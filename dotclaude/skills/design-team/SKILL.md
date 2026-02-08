---
name: design-team
description: Agent Teamsで設計検討・複数視点議論チームを自動構成・起動
argument-hint: "[design question, RFC, or architecture topic]"
user-invocable: true
disable-model-invocation: true
---

# Design Team

Create an Agent Team with automatically selected panelists based on the design topic for structured debate and decision-making.

## Instructions

1. **Analyze the topic** (design question, RFC, or architecture topic) to determine the domain
2. **Select appropriate panelists** based on the selection matrix below
3. **Create the agent team** with only the selected panelists
4. Have them debate from their perspectives and produce a decision document

## Step 1: Topic Analysis

Before spawning any teammates, analyze the design question to determine the domain and scope:

| Signal | Type |
|--------|------|
| Service boundaries, communication patterns, scaling strategy, module decomposition | System Architecture |
| Endpoint design, request/response schemas, versioning, SDK design | API Design |
| Schema design, storage engines, migration strategy, data flow | Data Design |
| Component hierarchy, user flows, interaction patterns, accessibility | UI/UX Design |
| CI/CD pipelines, infrastructure, deployment strategy, monitoring | DevOps/Infra |
| Auth design, encryption, compliance, threat modeling | Security Design |
| Mixed signals | Analyze dominant concerns and apply multiple types |

## Step 2: Panelist Selection Matrix

| Panelist | System Architecture | API Design | Data Design | UI/UX Design | DevOps/Infra | Security Design |
|:---------|:-------------------:|:----------:|:-----------:|:------------:|:------------:|:---------------:|
| Pragmatist | Always | Always | Always | Always | Always | Always |
| Futurist | Always | Always | Always | Always | Always | Always |
| Skeptic | Always | Always | Always | Always | Always | Always |
| Domain Expert | Always | Always | Always | Always | Always | Always |
| User Advocate | If user-facing | If developer-facing | If user data | Always | Skip | If user impact |
| Cost Analyst | If infra-related | Skip | If storage-heavy | Skip | Always | If compliance |
| Standards Keeper | Always | Always | Always | Always | Always | Always |

### Selection Rules

- **Always**: Spawn this panelist unconditionally
- **Skip**: Do not spawn this panelist
- **Conditional**: Spawn only if the condition is met based on topic analysis

When uncertain, **include the panelist** (prefer thoroughness over efficiency).

## Step 3: Team Creation

Spawn only the selected panelists with their specialized prompts:

1. **Pragmatist**: Advocate for practical, proven solutions. Focus on time-to-market, team capabilities, and maintenance cost. Challenge over-engineering and premature optimization. Ground discussions in real-world constraints.

2. **Futurist**: Consider long-term scalability, emerging technologies, and future requirements. Challenge short-term thinking and identify potential evolution paths. Propose forward-looking alternatives that prevent costly rewrites.

3. **Skeptic**: Question assumptions, identify risks, find edge cases, and stress-test proposals with failure scenarios. Play devil's advocate on every option. Ask "what happens when this fails?" for each proposal.

4. **Domain Expert**: Provide deep domain knowledge, industry best practices, and reference architectures for the specific problem. Cite relevant case studies and known pitfalls from similar systems.

5. **User Advocate**: Represent end-user needs, developer experience, and usability considerations in design decisions. Ensure the design serves its consumers well, whether they are end-users or fellow developers.

6. **Cost Analyst**: Evaluate infrastructure costs, operational overhead, licensing implications, and total cost of ownership. Compare options on both initial investment and long-term operational expense.

7. **Standards Keeper**: Ensure compliance with coding standards, architectural guidelines, and organizational conventions. Verify consistency with existing patterns in the codebase and team agreements.

## Workflow

1. Lead frames the design question and establishes evaluation criteria, announcing selected panelists with reasoning
2. Each selected panelist prepares their position based on their specialized perspective
3. Panelists engage in structured debate, responding to each other's points and challenging assumptions
4. The lead synthesizes the discussion into a decision document:
   - Options analyzed with pros and cons from each perspective
   - Trade-offs explicitly documented
   - Recommended approach with clear rationale
   - Dissenting opinions recorded with their reasoning

## Output

The lead produces a final design decision document including:
- Design topic classified and panelists selected (with reasoning)
- Options evaluated from multiple perspectives
- Trade-off analysis matrix
- Recommended approach with supporting rationale
- Dissenting opinions and minority concerns preserved
