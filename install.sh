#!/bin/bash
# AI Agent Toolbox 安装脚本

set -euo pipefail

REPO_URL="https://github.com/oliveagle/toolbox-opencode"
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/agent-toolbox"
REPO_DIR="${HOME}/.local/share/agent-toolbox"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

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
        log_error "需要 Podman 或 Docker"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "需要 Git"
        exit 1
    fi
}

clone_repo() {
    log_info "下载 AI Agent Toolbox..."
    
    if [[ -d "$REPO_DIR" ]]; then
        rm -rf "$REPO_DIR"
    fi
    
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>/dev/null || {
        log_error "下载失败"
        exit 1
    }
    
    log_success "下载完成"
}

install_toolbox() {
    log_info "Installing agent-toolbox..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"

    cp "$REPO_DIR/agent-toolbox" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/agent-toolbox"

    log_success "Installed: $INSTALL_DIR/agent-toolbox"
}

generate_wrappers() {
    log_info "Generating agent wrapper scripts..."

    export INSTALL_DIR="$INSTALL_DIR"
    bash "$REPO_DIR/lib/generate-wrappers.sh"

    log_success "Wrapper scripts generated"
}

check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "$INSTALL_DIR 不在 PATH 中"
        echo
        echo "添加到 ~/.bashrc 或 ~/.zshrc:"
        echo '    export PATH="$HOME/.local/bin:$PATH"'
    else
        log_success "PATH 配置正确"
    fi
}

build_images() {
    log_info "构建基础镜像..."
    cd "$REPO_DIR"

    # Build args for proxy (from environment variables)
    local build_args=()
    [[ -n "${HTTP_PROXY:-}" ]] && build_args+=(--build-arg "HTTP_PROXY=$HTTP_PROXY")
    [[ -n "${HTTPS_PROXY:-}" ]] && build_args+=(--build-arg "HTTPS_PROXY=$HTTPS_PROXY")
    [[ -n "${NO_PROXY:-}" ]] && build_args+=(--build-arg "NO_PROXY=$NO_PROXY")
    [[ -n "${http_proxy:-}" ]] && build_args+=(--build-arg "http_proxy=$http_proxy")
    [[ -n "${https_proxy:-}" ]] && build_args+=(--build-arg "https_proxy=$https_proxy")
    [[ -n "${no_proxy:-}" ]] && build_args+=(--build-arg "no_proxy=$no_proxy")

    # Use host network for build (needed for localhost proxy access)
    build_args+=(--network=host)

    if podman build "${build_args[@]}" -t localhost/toolbox-base:latest -f images/Containerfile.base .; then
        log_success "基础镜像构建成功"
    else
        log_warn "基础镜像构建失败"
        return 1
    fi

    log_info "构建 Agent 镜像..."

    for agent in occ; do
        if [[ -f "$REPO_DIR/agents/$agent/Containerfile" ]]; then
            log_info "构建 $agent..."
            cd "$REPO_DIR/agents/$agent"
            podman build "${build_args[@]}" -t "localhost/toolbox-agent-${agent}:latest" -f Containerfile . || log_warn "$agent 构建失败"
        fi
    done

    log_success "镜像构建完成"
}

show_help() {
    echo
    log_success "AI Agent Toolbox installation complete!"
    echo
    echo "Quick start:"
    echo "  agent-toolbox agents"
    echo "  agent-toolbox create occ ."
    echo "  agent-toolbox enter occ ."
    echo
    echo "Or use shortcut commands:"
    echo "  occ .                           # Enter occ toolbox (short form)"
    echo "  occ create .                    # Create occ toolbox"
    echo "  agent-toolbox-occ .             # Full form"
    echo
}

main() {
    echo "================================"
    echo "AI Agent Toolbox 安装程序"
    echo "================================"
    echo
    
    check_dependencies
    clone_repo
    install_toolbox
    generate_wrappers
    check_path
    
    read -p "是否立即构建镜像? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        build_images
    fi
    
    show_help
}

main "$@"
