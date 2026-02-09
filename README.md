# OpenCode Toolbox

Toolbx 风格的容器化开发环境，专为 OpenCode AI 编程助手设计。

## 特点

- **默认使用 Podman**：优先使用 podman，无守护进程，更安全
- **Git 配置自动挂载**：默认挂载 `~/.gitconfig`，保持 git 身份
- **目录隔离**：不挂载整个 home 目录，每个 toolbox 有独立的 home
- **项目级隔离**：只为特定项目创建容器，最小权限原则
- **可选挂载**：SSH、Docker socket 等可选且默认关闭

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/oliveagle/toolbox-opencode/main/install.sh | bash
```

安装完成后，重新加载 shell 配置：
```bash
source ~/.bashrc  # 或 ~/.zshrc
```

### 手动安装

```bash
# 克隆仓库
git clone https://github.com/oliveagle/toolbox-opencode.git
cd toolbox-opencode

# 安装到 PATH
sudo cp opencode-toolbox /usr/local/bin/
sudo chmod +x /usr/local/bin/opencode-toolbox

# 或者本地安装
mkdir -p ~/.local/bin
cp opencode-toolbox ~/.local/bin/
```

## 快速开始

```bash
# 进入项目目录
cd ~/my-project

# 创建 toolbox（使用当前目录名）
opencode-toolbox create .

# 进入 toolbox
opencode-toolbox enter .
⬢ $ opencode

# 直接运行 opencode
opencode-toolbox run .
```

## 命令

| 命令 | 说明 |
|------|------|
| `create [名称\|路径]` | 创建新的 toolbox |
| `enter [名称\|路径]` | 进入交互式 shell |
| `run <名称> [命令]` | 运行命令（默认 `opencode`） |
| `list` | 列出所有 toolbox |
| `rm <名称>` | 删除 toolbox |
| `build` | 构建 toolbox 镜像 |

## 隔离设计

### 挂载策略

**默认挂载（安全）**：
- ✅ 项目目录（只挂载你指定的目录）
- ✅ Git 配置（`~/.gitconfig`，用于保持 git 身份）
- ✅ 系统时区（只读）
- ✅ X11/Wayland 显示（用于 GUI 应用）

**可选挂载（需显式开启）**：
- ⭕ SSH keys（`~/.ssh`）
- ⭕ Docker/Podman socket
- ⭕ 其他自定义目录

**不挂载（隔离）**：
- ❌ 整个 home 目录
- ❌ 系统配置文件
- ❌ 主机环境变量

### 独立 Home 目录

每个 toolbox 有完全独立的 home 目录：

```
~/.local/share/opencode-toolbox/
├── myproject/          # toolbox "myproject" 的 home
│   ├── .npm-global/    # npm 全局安装
│   ├── .gitconfig      # 容器内的 git 配置
│   └── ...
└── another-project/    # 另一个 toolbox
```

## 配置

配置文件：`~/.config/opencode-toolbox/config.yaml`

```yaml
# 默认镜像
default_image: localhost/opencode-toolbox:latest

# 默认使用 podman
engine: podman

defaults:
  # 是否挂载 SSH keys（默认 false）
  mount_ssh: false
  
  # 是否挂载 Git 配置（默认 true）
  mount_gitconfig: true
  
  # 是否挂载 Docker/Podman socket（默认 false）
  mount_docker: false
  
  # X11/Wayland 支持（默认 true）
  mount_display: true

# 全局环境变量
global_env:
  EDITOR: vim
  TZ: Asia/Shanghai
```

## 工作流程

```bash
# 1. 进入项目目录
cd ~/projects/web-app

# 2. 创建 toolbox（第一次）
opencode-toolbox create .

# 3. 日常使用 - 进入 toolbox
opencode-toolbox enter .
⬢ [toolbox-web-app] $ opencode

# 4. 或者直接在 toolbox 中运行命令
opencode-toolbox run . npm test
opencode-toolbox run . git status

# 5. 查看所有 toolbox
opencode-toolbox list

# 6. 删除不再使用的 toolbox
opencode-toolbox rm web-app
```

## 与 Toolbx 的区别

| 特性 | Toolbx | OpenCode Toolbox |
|------|--------|------------------|
| 默认引擎 | Podman | Podman |
| home 目录 | 挂载主机 home | 独立隔离 home |
| 项目隔离 | 一个 toolbox 通用 | 按项目创建 |
| Git 配置 | 自动同步 | 默认挂载 |
| SSH keys | 自动挂载 | 可选，默认关闭 |
| 目标场景 | 系统故障排查 | AI 编程开发 |

## 文件结构

```
toolbox-opencode/
├── opencode-toolbox      # 主脚本
├── install.sh            # 安装脚本
├── Containerfile         # 容器镜像定义
├── config.yaml          # 默认配置
└── README.md            # 本文档
```

## 系统要求

- Linux 系统
- Podman (推荐) 或 Docker
- 4GB+ 内存
- 10GB+ 磁盘空间

## License

MIT License
