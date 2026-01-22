# Commit Guidelines

## Granularity

- 1 commit = 1 logical change
- Commit only in a working state

## Review Perspective

- Can the diff be understood per commit
- Is it easy to revert

## Prohibited Files

The following files should not be included in commits:

- `.env`, `.env.*` (environment variables / secrets)
- `credentials.json`, `secrets.*` (authentication credentials)
- `*.pem`, `*.key` (private keys)
- `node_modules/`, `vendor/` (dependency libraries)
