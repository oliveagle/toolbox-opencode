#!/bin/bash
set -euo pipefail

log_info() { echo "[agentbox] $*"; }
log_warn() { echo "[agentbox] WARN: $*" >&2; }
log_error() { echo "[agentbox] ERROR: $*" >&2; }

HOST_USER="${HOST_USER:-user}"
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
HOME="${HOME:-/home/$HOST_USER}"

log_info "Initializing agentbox for user: $HOST_USER (UID: $HOST_UID, GID: $HOST_GID)"

# 只有在以 root 身份运行时才创建用户和组
if [[ $EUID -eq 0 ]]; then
    if ! getent group "$HOST_GID" >/dev/null 2>&1; then
        groupadd -g "$HOST_GID" "$HOST_USER" 2>/dev/null || true
    fi

    if ! id -u "$HOST_USER" >/dev/null 2>&1; then
        useradd -m -u "$HOST_UID" -g "$HOST_GID" -s /bin/bash "$HOST_USER" 2>/dev/null || \
        useradd -m -o -u "$HOST_UID" -g "$HOST_GID" -s /bin/bash "$HOST_USER" 2>/dev/null || true
    fi

    if [[ -d /etc/sudoers.d ]]; then
        echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/agentbox
        chmod 440 /etc/sudoers.d/agentbox
        usermod -aG sudo "$HOST_USER" 2>/dev/null || true
    fi
fi

fix_config_permissions() {
    # 只有 root 才能修改权限
    [[ $EUID -ne 0 ]] && return 0

    local config_dir="$1"

    if [[ -d "$config_dir" ]]; then
        local current_uid
        current_uid=$(stat -c '%u' "$config_dir" 2>/dev/null || echo "0")

        if [[ "$current_uid" != "$HOST_UID" ]]; then
            log_info "Fixing permissions: $config_dir (current UID: $current_uid -> target UID: $HOST_UID)"
            chown -R "${HOST_UID}:${HOST_GID}" "$config_dir" 2>/dev/null || {
                log_warn "Could not chown $config_dir (may be read-only)"
            }
        fi
    fi
}

# 修复挂载的配置目录 - 这些通常是主机目录挂载进来的
# 通过检查 /proc/mounts 找到挂载到 /home 下的配置目录
if [[ -f /proc/mounts ]]; then
    while IFS= read -r line; do
        mount_point=$(echo "$line" | awk '{print $2}')
        # 检查是否是挂载到用户目录下的配置目录
        if [[ "$mount_point" == "$HOME/.config/"* ]] || [[ "$mount_point" == "$HOME/.cache/"* ]]; then
            fix_config_permissions "$mount_point"
        fi
    done < /proc/mounts
fi

# 修复常见的配置目录（包括挂载的和本地的）
for config_path in \
    "$HOME" \
    "$HOME/.config" \
    "$HOME/.config/claude" \
    "$HOME/.config/opencode" \
    "$HOME/.config/kilo" \
    "$HOME/.config/codebuddy" \
    "$HOME/.config/gh" \
    "$HOME/.config/qwen" \
    "$HOME/.cache" \
    "$HOME/.local" \
    "$HOME/.ssh"; do

    if [[ -e "$config_path" ]]; then
        fix_config_permissions "$config_path"
    fi
done

# 创建软链接：如果配置目录存在于 ${HOME} 但不在实际用户的 home 中
# 这解决了容器内 ubuntu 用户访问 ${HOME}/.claude 等目录的问题
link_configs_to_real_home() {
    local real_home="${HOME}"
    local configs=(
        ".claude"
        ".config/opencode"
        ".config/claude"
        ".config/kilo"
        ".config/codebuddy"
        ".config/gh"
        ".config/qwen"
    )

    # 只有当实际用户的 home 不是 agentbox home 时才需要链接
    if [[ "$HOME" != "$real_home" && -d "$real_home" ]]; then
        for config in "${configs[@]}"; do
            local source="$real_home/$config"
            local target="$HOME/$config"

            # 源目录存在才处理
            [[ -e "$source" ]] || continue

            # 如果目标已经是符号链接，跳过
            [[ -L "$target" ]] && continue

            # 如果目标存在但不是符号链接，先删除
            if [[ -e "$target" ]]; then
                log_info "Removing existing: $target"
                rm -rf "$target" 2>/dev/null || true
            fi

            # 创建父目录和符号链接
            mkdir -p "$(dirname "$target")"
            log_info "Creating symlink: $target -> $source"
            ln -s "$source" "$target"
        done
    fi

    # 链接 .config 下的目录（如果存在）
    if [[ "$HOME" != "$real_home" && -d "$real_home/.config" ]]; then
        for config_dir in "opencode" "claude" "kilo" "codebuddy" "gh" "qwen"; do
            local source="$real_home/.config/$config_dir"
            local target="$HOME/.config/$config_dir"

            # 源目录存在才处理
            [[ -e "$source" ]] || continue

            # 如果目标已经是符号链接，跳过
            [[ -L "$target" ]] && continue

            # 如果目标存在但不是符号链接，先删除
            if [[ -e "$target" ]]; then
                log_info "Removing existing directory: $target"
                rm -rf "$target" 2>/dev/null || true
            fi

            # 创建符号链接
            log_info "Creating symlink: $target -> $source"
            ln -s "$source" "$target"
        done
    fi
}

link_configs_to_real_home

# 导出 Claude/OpenCode 配置环境变量到全局环境
claude_settings="${HOME}/.claude/settings.json"
if [[ -f "$claude_settings" ]]; then
    # 读取 settings.json 中的 env 部分并导出
    if command -v jq >/dev/null 2>&1; then
        env_vars=$(jq -r '.env | to_entries[] | "\(.key)=\(.value)"' "$claude_settings" 2>/dev/null || true)
        if [[ -n "$env_vars" ]]; then
            while IFS= read -r env_var; do
                [[ -n "$env_var" ]] && export "$env_var"
            done <<< "$env_vars"
            log_info "Exported Claude Code environment variables from settings.json"
        fi
    fi
fi

if [[ -n "${AGENTBOX_HOME:-}" && -d "$AGENTBOX_HOME" ]]; then
    log_info "Setting up AGENTBOX_HOME: $AGENTBOX_HOME"
    chown -R "${HOST_UID}:${HOST_GID}" "$AGENTBOX_HOME" 2>/dev/null || true
fi

if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi
chown "${HOST_UID}:${HOST_GID}" "$HOME/.ssh" 2>/dev/null || true

if [[ ! -d "$HOME/.config" ]]; then
    mkdir -p "$HOME/.config"
    chmod 755 "$HOME/.config"
fi
chown "${HOST_UID}:${HOST_GID}" "$HOME/.config" 2>/dev/null || true

# 修复 ${HOME} 目录的所有权（如果容器以 root 运行）
if [[ $EUID -eq 0 && -d "${HOME}" ]]; then
    chown -R "${HOST_UID}:${HOST_GID}" "${HOME}" 2>/dev/null || true
    log_info "Fixed ${HOME} ownership to ${HOST_USER}:${HOST_USER}"
fi

log_info "Agentbox initialization complete"

# 如果使用 --userns=keep-id，容器已经以目标用户身份运行，直接执行命令
# 否则需要切换用户
if [[ $EUID -eq 0 && $(id -u) -ne ${HOST_UID} ]]; then
    # 以 root 运行但需要切换到目标用户
    run_as_user() {
        if command -v setpriv >/dev/null 2>&1; then
            setpriv --reuid="${HOST_UID}" --regid="${HOST_GID}" --clear-groups "$@"
        elif command -v runuser >/dev/null 2>&1; then
            runuser -u "#${HOST_UID}" -- "$@"
        else
            su - "${HOST_USER}" -c "cd '${HOME:-/home/$HOST_USER}' && exec \"\$@\"" -- "$@"
        fi
    }

    if [[ $# -eq 0 ]]; then
        run_as_user sleep infinity
    else
        run_as_user "$@"
    fi
else
    # 已经以目标用户运行，直接执行
    if [[ $# -eq 0 ]]; then
        exec sleep infinity
    else
        exec "$@"
    fi
fi
