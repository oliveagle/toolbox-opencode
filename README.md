# Agentbox

Multi-AI Agent container management tool with shared base OS layer and isolated environments per agent.

## Features

- **Shared Base OS**: Ubuntu 24.04 + common dev tools
- **Agent Isolation**: Each agent runs in its own container with isolated home
- **SSH Keys**: Dedicated SSH key pair for agentbox in `~/.config/agentbox/ssh/`
- **Wrapper Scripts**: Shortcut commands for quick access
- **OCC Agent**: Combined OpenCode + Claude Code agent

## Architecture

```
┌─────────────────────────────────────────┐
│          Base OS Layer (agentbox-base)       │
│  Ubuntu 24.04 + Dev Tools + Node/Python/Go  │
└─────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┬──────────────┐
    │              │              │              │
┌───▼────┐    ┌───▼─────┐   ┌───▼────┐   ┌───▼──────┐
│OpenCode│    │Claude   │   │  Kilo  │   │  Copilot │
│ Agent  │    │  Code   │   │ Agent  │   │   CLI    │
└────────┘    └─────────┘   └────────┘   └──────────┘
```

## Supported Agents

| Agent | Name | Installation |
|-------|------|-------------|
| `occ` | OpenCode + Claude | Combined agent (Recommended) |
| `opencode` | OpenCode AI | `npm install -g opencode-ai` |
| `claude` | Claude Code | `npm install -g @anthropic-ai/claude-code` |
| `kilo` | Kilo AI | `npm install -g kilo-ai` |
| `copilot` | GitHub Copilot | `gh extension install github/copilot` |
| `qwen` | Qwen AI | `pip3 install qwen-code` |
| `codebuddy` | CodeBuddy | `npm install -g codebuddy-cli` |

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/oliveagle/agentbox/main/install.sh | bash
```

## Quick Start

```bash
# 1. List available agents
agentbox agents

# 2. Create OpenCode agentbox
agentbox create opencode .

# 3. Enter agentbox
agentbox enter opencode .
⬢ opencode:~$ opencode

# 4. Create Claude Code agentbox (another project)
agentbox create claude-code another-project
agentbox enter claude-code another-project
⬢ claude-code:~$ claude
```

## Shortcut Commands (Wrapper Scripts)

After installation, shortcut commands are generated for each agent:

```bash
# Available shortcuts:
agentbox-occ         # OpenCode + Claude (Recommended)
agentbox-opencode     # OpenCode
agentbox-claude      # Claude Code
agentbox-kilo        # Kilo
agentbox-copilot     # GitHub Copilot
agentbox-qwen        # Qwen
agentbox-codebuddy    # CodeBuddy
```

### Shortcut Usage Examples

```bash
# Enter current directory's OpenCode agentbox
agentbox-opencode .

# Create Claude Code agentbox for project
agentbox-claude create myproject

# Run command in Kilo agentbox
agentbox-kilo run . npm test

# List all Kilo agentboxes
agentbox-kilo list

# Run agent in default project
agentbox-qwen

# Show help
agentbox-opencode --help
```

## Commands

| Command | Description |
|---------|-------------|
| `agents` | List available agents |
| `create <agent> [project]` | Create agentbox |
| `enter <agent> [project]` | Enter interactive shell |
| `run <agent> [project] [cmd]` | Run command |
| `list` | List all agentboxes |
| `rm <agent> [project]` | Delete agentbox |
| `build <agent>` | Build agent image |
| `build-all` | Build all images |

**Note:** Each agent also has a shortcut command (e.g., `agentbox-opencode`) that provides the same functionality.

## Usage Examples

```bash
# OCC (OpenCode + Claude) examples
cd ~/project1
agentbox create occ .
agentbox enter occ .

# OpenCode examples
cd ~/project1
agentbox create opencode .
agentbox enter opencode .

# Claude Code examples
agentbox create claude project2
agentbox run claude project2

# Run commands directly
agentbox run occ . git status
agentbox run opencode . git status
agentbox run claude myproject npm test

# Or use shortcut commands
agentbox-opencode .          # Enter current project
agentbox-kilo run . npm test # Run npm test in Kilo agentbox
agentbox-qwen                # Run Qwen in default project
```

## Directory Structure

```
~/.local/share/agentbox/
├── repo/                    # Utility scripts
├── occ/
│   ├── project1/           # OCC project1 home
│   └── project2/           # OCC project2 home
├── opencode/
│   ├── project1/           # OpenCode project1 home
│   └── project2/           # OpenCode project2 home
├── claude/
│   └── myproject/          # Claude myproject home
└── kilo/
    └── another/            # Kilo another home
```

## Configuration

Config file: `~/.config/agentbox/agents.yaml`

```yaml
default_agent: occ

agents:
  occ:
    name: OpenCode + Claude
    image: localhost/agentbox-occ:latest
    cmd: claude
    config_dir: ~/.config/claude

 mounts:
  agent_config: true   # Mount agent config
  gitconfig: true      # Mount git config
  ssh: true            # Mount SSH keys
  docker: false        # Don't mount Docker
```

## Container Mounts

When an agentbox is created, the following directories are mounted into the container:

| Host Path | Container Path | Description |
|-----------|---------------|-------------|
| `~/.claude` | `${HOME}/.claude` | Claude Code configuration |
| `~/.config/opencode` | `${HOME}/.config/opencode` | OpenCode configuration |
| `~/.gitconfig` | `${HOME}/.gitconfig` | Git configuration (read-only) |
| `~/.local/share/agentbox/<agent>/<project>` | Same path | Toolbox home directory |
| `/etc/localtime` | `/etc/localtime` | Timezone |
| `/tmp/.X11-unix` | `/tmp/.X11-unix` | X11 display server (if enabled) |
| `/tmp` | `/tmp` | Temporary directory |

**OCC Agent Additional Mounts:**
- `~/.config/claude` - Claude Code settings
- `~/.config/opencode` - OpenCode settings

**Optional Mounts (configured via `agents.yaml`):**
- `~/.ssh` - SSH keys (when `ssh: true`)
- `/var/run/docker.sock` - Docker socket (when `docker: true`)

## User Permissions

Toolbox automatically handles user UID/GID mapping between host and container:

```
Host User (UID 1000)  <--->  Container User (UID 1000)
        |                           |
   ~/.config/claude            ~/.config/claude
   (bind mount)               (same UID, no permission issues)
```

When an agentbox is created, the entrypoint script automatically:
1. Creates a user in the container matching your host UID/GID
2. Fixes permissions on all mounted config directories
3. Ensures the agentbox home directory is owned by you

**Note**: If you encounter permission issues with mounted configs, try recreating the agentbox:
```bash
agentbox rm occ myproject
agentbox create occ myproject
```

## SSH Keys

Agentbox generates a dedicated SSH key pair for git operations:

```bash
# Keys are stored at:
~/.config/agentbox/ssh/
├── id_ed25519         # Private key
└── id_ed25519.pub     # Public key
```

**Setup:**
```bash
# Keys are auto-generated on first run
# Add public key to GitHub/GitLab:
cat ~/.config/agentbox/ssh/id_ed25519.pub

# Enable SSH mounting in config (default: disabled)
ssh: true
```

## Image Layers

1. **Base Layer** (`agentbox-base`): Ubuntu + development tools
2. **Agent Layer** (`agentbox-*`): Base layer + specific agent

Build order:
```bash
agentbox build-all
# Or build individually
agentbox build occ
agentbox build opencode
agentbox build claude
```

### Build with Proxy

Builds use host network (`--network=host`) to access localhost proxies:

```bash
# Use proxy from environment variables
HTTP_PROXY=http://localhost:8080 agentbox build occ
HTTPS_PROXY=http://proxy.example.com:8080 agentbox build-all

# Or set globally in your shell profile
export HTTP_PROXY=http://localhost:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1
```

## OCC Agent (OpenCode + Claude)

The `occ` agent combines OpenCode and Claude Code in a single container:

```bash
# Create OCC agentbox
agentbox create occ .

# Enter and use Claude
agentbox enter occ .
⬢ occ:~$ claude

# Or use OpenCode
⬢ occ:~$ opencode
```

**Features:**
- Both Claude Code and OpenCode pre-installed
- Shared configuration and cache
- Use `claude` or `opencode` commands as needed

## Adding New Agents

1. Create `agents/<name>/Containerfile`:
```dockerfile
FROM localhost/agentbox-base:latest

LABEL agent="myagent"

# Install your agent
RUN npm install -g my-agent-cli

ENV AGENT_NAME=myagent
ENV AGENT_CMD=myagent
```

2. Update config `~/.config/agentbox/agents.yaml`

3. Build the image:
```bash
agentbox build myagent
```

4. Generate wrapper script:
```bash
# Add your agent to AGENTS variable
AGENTS="occ opencode claude kilo copilot qwen codebuddy myagent" \
    bash lib/generate-wrappers.sh
```

## File Structure

```
agentbox/
├── agentbox              # Main script
├── install.sh                 # Installation script
├── lib/
│   └── generate-wrappers.sh   # Wrapper script generator
├── images/
│   └── Containerfile.base    # Base image
├── agents/
│   ├── opencode/
│   │   └── Containerfile
│   ├── claude-code/
│   │   └── Containerfile
│   ├── kilo/
│   │   └── Containerfile
│   └── ...
└── README.md
```

## License

MIT License
