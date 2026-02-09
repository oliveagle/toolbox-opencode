#!/bin/bash
# OpenCode Toolbox 安装脚本

set -euo pipefail

REPO_URL="https://github.com/oliveagle/toolbox-opencode"
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/opencode-toolbox"
REPO_DIR="${HOME}/.local/share/opencode-toolbox/repo"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    local has_podman=false
    local has_docker=false
    
    if command -v podman &> /dev/null; then
        has_podman=true
        log_success "找到 Podman"
    fi
    
    if command -v docker &> /dev/null; then
        has_docker=true
        log_success "找到 Docker"
    fi
    
    if [[ "$has_podman" == false && "$has_docker" == false ]]; then
        log_error "需要 Podman 或 Docker，请先安装其中一个"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "需要 Git，请先安装"
        exit 1
    fi
}

# 克隆仓库
clone_repo() {
    log_info "下载 OpenCode Toolbox..."
    
    # 清理旧版本
    if [[ -d "$REPO_DIR" ]]; then
        rm -rf "$REPO_DIR"
    fi
    
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>/dev/null || {
        log_error "下载失败，请检查网络连接"
        exit 1
    }
    
    log_success "下载完成"
}

# 安装脚本
install_toolbox() {
    log_info "安装 opencode-toolbox..."
    
    # 创建目录
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # 复制脚本
    cp "$REPO_DIR/opencode-toolbox" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/opencode-toolbox"
    
    # 复制配置文件
    if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
        cp "$REPO_DIR/config.yaml" "$CONFIG_DIR/config.yaml"
    fi
    
    log_success "安装完成: $INSTALL_DIR/opencode-toolbox"
}

# 检查 PATH
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "$INSTALL_DIR 不在 PATH 中"
        echo
        echo "请将以下内容添加到你的 ~/.bashrc 或 ~/.zshrc:"
        echo '    export PATH="$HOME/.local/bin:$PATH"'
        echo
        echo "然后运行: source ~/.bashrc (或 ~/.zshrc)"
    else
        log_success "PATH 配置正确"
    fi
}

# 构建镜像
build_image() {
    log_info "构建 toolbox 镜像（这可能需要几分钟）..."
    
    if "$INSTALL_DIR/opencode-toolbox" build; then
        log_success "镜像构建成功"
    else
        log_warn "镜像构建失败，稍后请手动运行: opencode-toolbox build"
    fi
}

# 显示帮助
show_help() {
    echo
    log_success "OpenCode Toolbox 安装成功！"
    echo
    echo "使用示例:"
    echo "  # 进入项目目录"
    echo "  cd ~/my-project"
    echo ""
    echo "  # 创建 toolbox"
    echo "  opencode-toolbox create ."
    echo ""
    echo "  # 进入 toolbox 运行 opencode"
    echo "  opencode-toolbox enter ."
    echo "  ⬢ \$ opencode"
    echo ""
    echo "更多命令:"
    echo "  opencode-toolbox --help"
    echo
}

# 主函数
main() {
    echo "================================"
    echo "OpenCode Toolbox 安装程序"
    echo "================================"
    echo
    
    check_dependencies
    clone_repo
    install_toolbox
    check_path
    
    read -p "是否立即构建 toolbox 镜像? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        build_image
    fi
    
    show_help
}

main "$@"
