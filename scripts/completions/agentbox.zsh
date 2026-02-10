#!/bin/zsh
# agentbox zsh completion script

_agentbox() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local -a commands
    commands=(
        'agents:List available agents'
        'create:Create agentbox'
        'enter:Enter agentbox'
        'run:Run command in agentbox'
        'list:List all agentboxes'
        'rm:Delete agentbox'
        'kill:Stop agentbox'
        'build:Build agent image'
        'build-all:Build all images'
        'help:Show help'
    )

    local -a agents
    agents=(occ opencode claude kilo copilot qwen codebuddy)

    _arguments -C \
        '1: :->command' \
        '2: :->agent' \
        '*: :->args' && return 0

    case "$state" in
        command)
            _describe -t commands 'commands' commands
            ;;
        agent)
            _describe -t agents 'agents' agents
            ;;
        args)
            _files -/
            ;;
    esac
}

compdef _agentbox agentbox

# Wrapper commands completion
_agentbox_wrapper() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local -a commands
    commands=(
        'create:Create agentbox'
        'enter:Enter agentbox (default)'
        'run:Run command in agentbox'
        'rm:Delete agentbox'
        'kill:Stop agentbox'
        'list:List agentboxes'
        'build:Build image'
    )

    _arguments -C \
        '1: :->command' \
        '*: :->args' && return 0

    case "$state" in
        command)
            _describe -t commands 'commands' commands
            ;;
        args)
            _files -/
            ;;
    esac
}

# Apply to all wrapper commands
compdef _agentbox_wrapper agentbox-occ
compdef _agentbox_wrapper agentbox-opencode
compdef _agentbox_wrapper agentbox-claude
compdef _agentbox_wrapper agentbox-kilo
compdef _agentbox_wrapper agentbox-copilot
compdef _agentbox_wrapper agentbox-qwen
compdef _agentbox_wrapper agentbox-codebuddy
