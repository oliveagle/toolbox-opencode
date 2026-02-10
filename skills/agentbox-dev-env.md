# Agentbox Development Environment Skill

Use this skill when you need to set up a development environment using agentbox containers.

## Overview

Agentbox is a multi-AI Agent container management tool that provides isolated development environments with shared base OS layer. Each agent (claude, opencode, etc.) runs in its own container with isolated home directory.

## When to Use

- When starting work on a new project
- When needing an isolated development environment
- When working with AI coding agents (Claude Code, OpenCode, etc.)
- When you need consistent development tooling across projects

## Quick Commands

### Create and Enter Development Environment

```bash
# Create and enter OCC agentbox (OpenCode + Claude combined)
agentbox create occ .
agentbox enter occ .

# Or use the shortcut
occ .
```

### Available Agents

| Agent | Description | Command |
|-------|-------------|---------|
| `occ` | OpenCode + Claude combined (recommended) | `agentbox enter occ .` |
| `claude` | Claude Code only | `agentbox enter claude .` |
| `opencode` | OpenCode only | `agentbox enter opencode .` |

### Skip Permission Prompts

Inside the container, use these commands to skip permission prompts:

```bash
# For Claude Code
claude-skip

# For OpenCode
opencode-skip
```

These are equivalent to:
- `claude --dangerously-skip-permissions`
- `opencode --dangerously-skip-permissions`

## Directory Structure

Agentbox stores data in:
- Config: `~/.config/agentbox/`
- Data: `~/.local/share/agentbox/<agent>/<project>/`
- SSH keys: `~/.config/agentbox/ssh/`

## Best Practices

1. **Create agentbox per project**: Keep environments isolated
2. **Use occ agent**: Combines both OpenCode and Claude Code
3. **Skip permissions in trusted projects**: Use `claude-skip` or `opencode-skip`
4. **Mount SSH keys**: Agentbox automatically mounts SSH keys for git operations

## Troubleshooting

### Container already exists
```bash
# Remove and recreate
agentbox rm occ <project-name>
agentbox create occ .
```

### Permission issues
```bash
# Recreate the agentbox
agentbox rm occ <project-name>
agentbox create occ .
```

## Example Workflow

```bash
# 1. Navigate to project
cd ~/my-project

# 2. Create and enter agentbox
occ .

# 3. Inside container, run agent with skip
⬢ occ:~$ claude-skip

# 4. When done, exit container
⬢ occ:~$ exit

# 5. List all agentboxes
agentbox list
```

## References

- Repository: https://github.com/oliveagle/agentbox
- Install: `curl -fsSL https://raw.githubusercontent.com/oliveagle/agentbox/main/install.sh | bash`
