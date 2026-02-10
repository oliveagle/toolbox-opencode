#!/bin/bash
# AI Agent Toolbox 卸载脚本

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
CONFIG_DIR="${HOME}/.config/agentbox"
DATA_DIR="${HOME}/.local/share/agentbox"
CACHE_DIR="${HOME}/.cache/agentbox"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 检测容器引擎
detect_engine() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo "podman"
    fi
}

CONTAINER_ENGINE=$(detect_engine)

# 停止并删除所有 agentbox 容器
remove_containers() {
    log_info "查找并删除所有 agentbox 容器..."

    local containers
    containers=$("$CONTAINER_ENGINE" ps -a --filter "name=agentbox-" --format "{{.Names}}" 2>/dev/null || true)

    if [[ -n "$containers" ]]; then
        echo "找到以下容器:"
        echo "$containers"
        echo
        read -p "是否删除所有 agentbox 容器? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$containers" | while read -r container; do
                log_info "删除容器: $container"
                "$CONTAINER_ENGINE" rm -f "$container" 2>/dev/null || true
            done
            log_success "容器已删除"
        fi
    else
        log_info "没有找到 agentbox 容器"
    fi
}

# 删除镜像
remove_images() {
    log_info "查找 agentbox 镜像..."

    local images
    images=$("$CONTAINER_ENGINE" images --format "{{.Repository}}:{{.Tag}}" | grep "^localhost/agentbox-" || true)

    if [[ -n "$images" ]]; then
        echo "找到以下镜像:"
        echo "$images"
        echo
        read -p "是否删除所有 agentbox 镜像? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$images" | while read -r image; do
                log_info "删除镜像: $image"
                "$CONTAINER_ENGINE" rmi -f "$image" 2>/dev/null || true
            done
            log_success "镜像已删除"
        fi
    else
        log_info "没有找到 agentbox 镜像"
    fi
}

# 删除快捷命令
remove_wrappers() {
    log_info "删除快捷命令..."
    
    local wrappers=""
    for agent in opencode claude-code kilo copilot qwen codebuddy; do
        local wrapper="${INSTALL_DIR}/agentbox-${agent}"
        if [[ -f "$wrapper" ]]; then
            wrappers="$wrappers $wrapper"
        fi
    done
    
    if [[ -n "$wrappers" ]]; then
        echo "找到以下快捷命令:$wrappers"
        read -p "是否删除? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for wrapper in $wrappers; do
                rm -f "$wrapper"
            done
            log_success "快捷命令已删除"
        fi
    fi
}

# 删除主脚本
remove_main_script() {
    log_info "删除主脚本..."
    local script="${INSTALL_DIR}/agentbox"
    if [[ -f "$script" ]]; then
        rm -f "$script"
        log_success "主脚本已删除"
    fi
}

# 删除数据和配置
remove_data() {
    log_info "数据和配置目录:"
    echo "  配置: $CONFIG_DIR"
    echo "  数据: $DATA_DIR"
    echo "  缓存: $CACHE_DIR"
    echo
    
    read -p "是否删除所有数据和配置? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        rm -rf "$DATA_DIR"
        rm -rf "$CACHE_DIR"
        log_success "数据和配置已删除"
    fi
}

# 主函数
main() {
    echo "================================"
    echo "AI Agent Toolbox 卸载程序"
    echo "================================"
    echo
    
    echo "这将卸载以下内容:"
echo "  - 所有 agentbox 容器"
echo "  - 所有 agentbox 镜像"
    echo "  - 主脚本 (agentbox)"
    echo "  - 快捷命令 (agentbox-*)"
    echo "  - 配置和数据文件"
    echo
    
    read -p "确认卸载? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        exit 0
    fi
    
    echo
    remove_containers
    echo
    remove_images
    echo
    remove_wrappers
    echo
    remove_main_script
    echo
    remove_data
    
    echo
    log_success "AI Agent Toolbox 已卸载"
    echo
    echo "手动清理（如有需要）:"
    echo "  1. 从 PATH 中移除: $INSTALL_DIR"
    echo "  2. 删除仓库: $DATA_DIR"
}

main "$@"
