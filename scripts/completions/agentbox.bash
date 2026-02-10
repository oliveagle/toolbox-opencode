#!/bin/bash
# agentbox bash completion script

_agentbox() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    local commands="agents create enter run list rm kill build build-all help"
    
    # Agent names
    local agents="occ opencode claude kilo copilot qwen codebuddy"

    case "${prev}" in
        agentbox)
            # Complete with main commands
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return 0
            ;;
        create|enter|run|rm|kill|build)
            # Complete with agent names
            COMPREPLY=( $(compgen -W "${agents}" -- ${cur}) )
            return 0
            ;;
        *)
            # Check if we're after an agent name
            local found_agent=false
            for ((i=2; i<COMP_CWORD; i++)); do
                if [[ "${agents}" =~ "${COMP_WORDS[i]}" ]]; then
                    found_agent=true
                    break
                fi
            done
            
            if [[ "$found_agent" == "true" ]]; then
                # Complete with directory/project names
                COMPREPLY=( $(compgen -d -- ${cur}) )
            fi
            return 0
            ;;
    esac
}

complete -F _agentbox agentbox

# Completion for agentbox-* wrapper commands
_agentbox_wrapper() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local commands="create enter run rm kill list"

    case "${prev}" in
        agentbox-*)
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return 0
            ;;
        create|enter|run|rm|kill)
            # Complete with directory names
            COMPREPLY=( $(compgen -d -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return 0
            ;;
    esac
}

# Apply completion to all agentbox-* commands
complete -F _agentbox_wrapper agentbox-occ
complete -F _agentbox_wrapper agentbox-opencode
complete -F _agentbox_wrapper agentbox-claude
complete -F _agentbox_wrapper agentbox-kilo
complete -F _agentbox_wrapper agentbox-copilot
complete -F _agentbox_wrapper agentbox-qwen
complete -F _agentbox_wrapper agentbox-codebuddy
