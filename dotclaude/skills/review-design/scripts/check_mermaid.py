#!/usr/bin/env python3
"""Check the Mermaid blocks in a Markdown file for the mistakes that break rendering.

A Mermaid block with a syntax error renders as a red error box on GitHub, which
costs the document all of its credibility. This catches the common breakages
statically, and — if `mmdc` (@mermaid-js/mermaid-cli) is on PATH — also does a
real render pass.

Usage:
    python3 check_mermaid.py FILE.md [FILE2.md ...]
    python3 check_mermaid.py --max-nodes 20 FILE.md
    python3 check_mermaid.py --render FILE.md   # also render for real

Exit code is 1 when any ERROR was found, 0 otherwise (warnings do not fail).
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

DEFAULT_MAX_NODES = 15

BLOCK_OPENERS = ("subgraph", "alt", "opt", "loop", "par", "rect", "critical", "break", "box")
RISKY_IN_LABEL = set("()[]{},:/")
FLOWCHART_TYPES = ("flowchart", "graph")

# Identifiers that collide with block keywords and make the diagram fail to render.
# Verified by rendering each one with mermaid-cli 11 — the parser matches these
# case-insensitively, so an uppercase participant called OPT breaks just as `opt` would.
SEQ_RESERVED_IDS = {
    "alt", "opt", "loop", "par", "rect", "note", "box", "end", "and", "else",
    "critical", "break", "activate", "deactivate", "autonumber", "link", "links",
    "participant", "actor",
}
FLOW_RESERVED_IDS = {"end", "class"}
END_BALANCED_TYPES = ("flowchart", "graph", "sequencediagram", "statediagram", "statediagram-v2")

NODE_DEF_RE = re.compile(r"(?<![\w\"])([A-Za-z_][\w-]*)\s*(\[\[|\[\(|\[/|\[|\(\(|\(|\{\{|\{)")
ID_LIKE_RE = re.compile(r"(?<![\w\"])([^\s\"\[\](){}|>-]+)\s*(?:\[|\(|\{)")
EDGE_RE = re.compile(r"(?:^|\s)([A-Za-z_][\w-]*)\s*(?:-{2,3}>|-{2,3}|={2,3}>|-\.->)")
CLASSDEF_RE = re.compile(r"^\s*classDef\s+([\w,]+)\s+(.*)$")
CLASS_USE_RE = re.compile(r"^\s*class\s+([\w,\s]+?)\s+([\w]+)\s*$")
PARTICIPANT_RE = re.compile(r"^\s*(?:participant|actor)\s+([\w-]+)")


@dataclass
class Issue:
    level: str  # ERROR | WARN | INFO
    line: int
    message: str


@dataclass
class Block:
    start_line: int  # 1-based line of the ``` fence
    lines: list[str]

    @property
    def kind(self) -> str:
        for ln in self.lines:
            s = ln.strip()
            if not s or s.startswith("%%"):
                continue
            return s.split()[0].lower().rstrip(";")
        return ""


def extract_blocks(text: str) -> list[Block]:
    blocks: list[Block] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if re.match(r"^`{3,}\s*mermaid\s*$", stripped):
            fence = re.match(r"^(`{3,})", stripped).group(1)
            start = i + 1
            body: list[str] = []
            i += 1
            while i < len(lines) and not re.match(rf"^{fence}`*\s*$", lines[i].strip()):
                body.append(lines[i])
                i += 1
            blocks.append(Block(start_line=start, lines=body))
        i += 1
    return blocks


def strip_comment(line: str) -> str:
    idx = line.find("%%")
    return line[:idx] if idx >= 0 else line


def mask_quoted(line: str) -> str:
    """Blank out the inside of quoted labels.

    Label text routinely contains parentheses, dots and colons — `Option.to_info_dict()`
    is a perfectly good label. Scanning it for identifiers produces nothing but false
    alarms, so the ID and node-count passes run against the masked line.
    """
    return re.sub(r'"[^"]*"', lambda m: '"' + "\x00" * (len(m.group(0)) - 2) + '"', line)


def check_labels(block: Block, issues: list[Issue]) -> None:
    """Labels holding ()[]{},:/ must be quoted or Mermaid's parser trips.

    Only flowcharts and state diagrams use bracket labels; in classDiagram and
    erDiagram braces delimit member blocks, so the same scan would misfire there.
    """
    bracket_syntax = any(block.kind.startswith(t) for t in FLOWCHART_TYPES) or \
        block.kind.startswith("statediagram")
    for offset, raw in enumerate(block.lines):
        line = strip_comment(raw)
        if not line.strip() or line.strip().startswith(("classDef", "class ", "style ")):
            continue
        lineno = block.start_line + offset + 1
        if "\\n" in line:
            issues.append(Issue("ERROR", lineno, r"'\n' does not break lines in Mermaid — use <br/>"))
        if not bracket_syntax:
            continue
        for open_ch, close_ch in (("[", "]"), ("{", "}")):
            for m in re.finditer(re.escape(open_ch) + r"([^\[\]{}]*?)" + re.escape(close_ch), line):
                inner = m.group(1).strip()
                if not inner or inner.startswith('"') or inner.startswith("'"):
                    continue
                if inner.startswith(("(", "/")) and inner.endswith((")", "/")):
                    inner_core = inner[1:-1].strip()
                    if inner_core.startswith('"'):
                        continue
                    inner = inner_core
                bad = sorted(set(inner) & RISKY_IN_LABEL)
                if bad:
                    issues.append(Issue(
                        "ERROR", lineno,
                        f'unquoted label contains {"".join(bad)} -> wrap it: {open_ch}"{inner}"{close_ch}',
                    ))
        if "|" in line:
            for m in re.finditer(r"\|([^|]+)\|", line):
                inner = m.group(1).strip()
                if inner.startswith('"') or inner.startswith("'"):
                    continue
                bad = sorted(set(inner) & RISKY_IN_LABEL)
                if bad:
                    issues.append(Issue(
                        "ERROR", lineno,
                        f'unquoted edge label contains {"".join(bad)} -> wrap it: |"{inner}"|',
                    ))


def check_node_ids(block: Block, issues: list[Issue]) -> None:
    """Node IDs must be ASCII; Japanese belongs in the label, not the identifier."""
    if not any(block.kind.startswith(t) for t in FLOWCHART_TYPES):
        return
    for offset, raw in enumerate(block.lines):
        line = mask_quoted(strip_comment(raw))
        if not line.strip() or line.strip().startswith(("classDef", "class ", "style ", "click ")):
            continue
        lineno = block.start_line + offset + 1
        for m in ID_LIKE_RE.finditer(line):
            node_id = m.group(1)
            if node_id in ("participant", "actor", "state", "subgraph", "class", "end"):
                continue
            if "\x00" in node_id or not node_id.strip('"'):
                continue
            if not re.fullmatch(r"[A-Za-z_][\w-]*", node_id):
                issues.append(Issue(
                    "ERROR", lineno,
                    f"node ID '{node_id}' is not a plain ASCII identifier — "
                    f"use an ASCII ID and put the text in the label",
                ))


def check_reserved_ids(block: Block, issues: list[Issue]) -> None:
    """Node and participant IDs must not collide with block keywords.

    This one is worth catching statically because the failure is invisible until
    render time: `participant OPT as Option` parses as the start of an `opt` block
    and the whole diagram dies.
    """
    kind = block.kind
    if kind.startswith("sequencediagram"):
        reserved, what = SEQ_RESERVED_IDS, "participant"
        pattern = PARTICIPANT_RE
    elif any(kind.startswith(t) for t in FLOWCHART_TYPES):
        reserved, what = FLOW_RESERVED_IDS, "node"
        pattern = None
    else:
        return

    for offset, raw in enumerate(block.lines):
        line = mask_quoted(strip_comment(raw))
        lineno = block.start_line + offset + 1
        ids: set[str] = set()
        if pattern is not None:
            m = pattern.match(line)
            if m:
                ids.add(m.group(1))
            for m in re.finditer(r"(?:^|\s)([A-Za-z_][\w-]*)\s*(?:-{1,2}>>?|--?>|-\)|--x)", line):
                ids.add(m.group(1))
        else:
            if line.strip().startswith(("classDef", "class ", "style ", "click ")):
                continue
            for m in NODE_DEF_RE.finditer(line):
                ids.add(m.group(1))
            for m in EDGE_RE.finditer(line):
                ids.add(m.group(1))
        for ident in sorted(ids):
            if ident.lower() in reserved:
                issues.append(Issue(
                    "ERROR", lineno,
                    f"{what} ID '{ident}' collides with a Mermaid keyword "
                    f"(case-insensitive) and the diagram will not render — rename it",
                ))


def check_block_balance(block: Block, issues: list[Issue]) -> None:
    kind = block.kind
    if not any(kind.startswith(t) for t in END_BALANCED_TYPES):
        return
    depth = 0
    opened: list[tuple[int, str]] = []
    for offset, raw in enumerate(block.lines):
        line = mask_quoted(strip_comment(raw)).strip()
        lineno = block.start_line + offset + 1
        first = line.split("(")[0].split("[")[0].split("{")[0].strip().split()
        head = first[0] if first else ""
        # Mermaid keywords are lowercase; an uppercase LOOP is a node ID, not a block.
        if head in BLOCK_OPENERS:
            depth += 1
            opened.append((lineno, head))
        elif head == "end":
            # `end note` closes a multi-line note, which never opened a block here.
            if len(first) > 1 and first[1] == "note":
                continue
            depth -= 1
            if depth < 0:
                issues.append(Issue("ERROR", lineno, "'end' without a matching block opener"))
                depth = 0
            elif opened:
                opened.pop()
        elif head.lower() == "end" and head != "end":
            issues.append(Issue("ERROR", lineno, "'end' must be lowercase"))
    for lineno, head in opened:
        issues.append(Issue("ERROR", lineno, f"'{head}' is never closed by a matching 'end'"))


def check_classdefs(block: Block, issues: list[Issue]) -> None:
    defined: set[str] = set()
    for offset, raw in enumerate(block.lines):
        line = strip_comment(raw)
        lineno = block.start_line + offset + 1
        m = CLASSDEF_RE.match(line)
        if m:
            names = [n for n in m.group(1).split(",") if n]
            defined.update(names)
            body = m.group(2)
            if "fill:" in body and "color:" not in body:
                issues.append(Issue(
                    "WARN", lineno,
                    f"classDef {m.group(1)} sets fill: but not color: — "
                    f"labels become unreadable in GitHub's dark theme",
                ))
    for offset, raw in enumerate(block.lines):
        line = strip_comment(raw)
        lineno = block.start_line + offset + 1
        m = CLASS_USE_RE.match(line)
        if m:
            cls = m.group(2)
            if cls not in defined and cls not in ("default",):
                issues.append(Issue(
                    "ERROR", lineno,
                    f"'class ... {cls}' references a classDef that is not defined in this block",
                ))


def check_size(block: Block, issues: list[Issue], max_nodes: int) -> None:
    kind = block.kind
    ids: set[str] = set()
    if any(kind.startswith(t) for t in FLOWCHART_TYPES) or kind.startswith("statediagram"):
        for raw in block.lines:
            line = mask_quoted(strip_comment(raw))
            if line.strip().startswith(("classDef", "class ", "style ", "click ")):
                continue
            for m in NODE_DEF_RE.finditer(line):
                ids.add(m.group(1))
            for m in EDGE_RE.finditer(line):
                ids.add(m.group(1))
        label = "nodes"
    elif kind.startswith("sequencediagram"):
        for raw in block.lines:
            m = PARTICIPANT_RE.match(strip_comment(raw))
            if m:
                ids.add(m.group(1))
        label = "participants"
        max_nodes = min(max_nodes, 7)
    else:
        return
    ids.discard("end")
    if len(ids) > max_nodes:
        issues.append(Issue(
            "WARN", block.start_line,
            f"{len(ids)} {label} (readable limit ~{max_nodes}) — "
            f"raise the abstraction level or split into overview + zoom",
        ))


def check_style(block: Block, issues: list[Issue]) -> None:
    kind = block.kind
    if kind == "graph":
        issues.append(Issue("WARN", block.start_line, "'graph' is the legacy keyword — prefer 'flowchart'"))
    if kind == "statediagram":
        issues.append(Issue("WARN", block.start_line, "use 'stateDiagram-v2' rather than 'stateDiagram'"))
    if not kind:
        issues.append(Issue("ERROR", block.start_line, "block has no diagram type on its first line"))


def render_check(block: Block, issues: list[Issue], mmdc: list[str]) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "d.mmd"
        src.write_text("\n".join(block.lines), encoding="utf-8")
        try:
            proc = subprocess.run(
                [*mmdc, "-i", str(src), "-o", str(Path(tmp) / "d.svg")],
                capture_output=True, text=True, timeout=600,
            )
        except (subprocess.TimeoutExpired, OSError) as exc:
            issues.append(Issue("WARN", block.start_line, f"mmdc render check skipped: {exc}"))
            return
        if proc.returncode != 0:
            detail = (proc.stderr or proc.stdout or "").strip().splitlines()
            msg = detail[-1] if detail else f"exit {proc.returncode}"
            issues.append(Issue("ERROR", block.start_line, f"mmdc failed to render: {msg}"))


def check_file(path: Path, max_nodes: int, use_mmdc: list[str] | None = None) -> list[Issue]:
    issues: list[Issue] = []
    blocks = extract_blocks(path.read_text(encoding="utf-8"))
    if not blocks:
        issues.append(Issue("WARN", 1, "no ```mermaid blocks found — is this a diagram-first document?"))
    for block in blocks:
        check_style(block, issues)
        check_labels(block, issues)
        check_node_ids(block, issues)
        check_reserved_ids(block, issues)
        check_block_balance(block, issues)
        check_classdefs(block, issues)
        check_size(block, issues, max_nodes)
        if use_mmdc:
            render_check(block, issues, use_mmdc)
    return sorted(issues, key=lambda i: (i.line, i.level))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--max-nodes", type=int, default=DEFAULT_MAX_NODES,
                    help=f"readable node ceiling per diagram (default {DEFAULT_MAX_NODES})")
    ap.add_argument("--render", action="store_true",
                    help="also do a real render pass: uses mmdc if installed, else "
                         "`npx -y @mermaid-js/mermaid-cli` (first npx run downloads a browser)")
    ap.add_argument("--no-render", action="store_true", help=argparse.SUPPRESS)
    args = ap.parse_args()

    mmdc = None
    if args.render and not args.no_render:
        found = shutil.which("mmdc")
        if found:
            mmdc = [found]
            print(f"render pass: {found}\n")
        elif shutil.which("npx"):
            mmdc = ["npx", "-y", "@mermaid-js/mermaid-cli@11"]
            print("render pass: npx @mermaid-js/mermaid-cli (first run downloads a browser)\n")
        else:
            print("render pass requested but neither mmdc nor npx is available\n")

    errors = 0
    warnings = 0
    for path in args.files:
        if not path.exists():
            print(f"{path}: not found", file=sys.stderr)
            errors += 1
            continue
        issues = check_file(path, args.max_nodes, mmdc)
        if not issues:
            print(f"{path}: OK")
            continue
        for issue in issues:
            print(f"{path}:{issue.line}: [{issue.level}] {issue.message}")
            if issue.level == "ERROR":
                errors += 1
            else:
                warnings += 1

    print(f"\n{errors} error(s), {warnings} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
