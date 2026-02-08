---
name: debug-environment
description: >-
  Environment and configuration investigation. Apply when debugging
  environment-specific failures, missing configuration, permission errors,
  platform differences, and deployment issues.
user-invocable: false
---

# Environment Checker Investigation

Investigate environment and configuration issues that cause failures in specific contexts.

## Investigation Checklist

### Configuration Verification
- Compare actual configuration values against expected defaults
- Check for missing required environment variables or config keys
- Identify configuration override precedence conflicts
- Verify config file format and encoding are parsed correctly
- Look for environment-specific config that was not applied

### Platform Differences
- Identify OS-specific behavior differences causing the failure
- Check for path separator, line ending, or case sensitivity issues
- Verify runtime version compatibility across environments
- Look for locale or timezone settings that affect data processing
- Check for architecture-specific issues in native dependencies

### File System & Permissions
- Verify file and directory existence at expected paths
- Check read, write, and execute permissions for the running process
- Identify symlink resolution failures or broken links
- Look for disk space or inode exhaustion conditions
- Check for file locking conflicts with other processes

### Network & Connectivity
- Verify DNS resolution and endpoint reachability
- Check for proxy, firewall, or VPN interference
- Identify timeout values that are too aggressive for the environment
- Verify TLS certificate validity and trust chain
- Look for port conflicts or binding failures on the host

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
