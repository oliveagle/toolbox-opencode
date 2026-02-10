#!/bin/bash
# Generate Agent shortcut commands

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
AGENTS="${AGENTS:-occ}"

# Generate special aliases for commonly used agents
generate_special_aliases() {
    # occ -> agent-toolbox-occ
    local alias_name="occ"
    local alias_path="${INSTALL_DIR}/${alias_name}"
    local target="agent-toolbox-occ"

    cat > "$alias_path" << ALIAS
#!/bin/bash
# OCC Alias - shortcut for agent-toolbox-occ
# Auto-generated, do not edit manually

set -euo pipefail
exec "${INSTALL_DIR}/${target}" "\$@"
ALIAS

    chmod +x "$alias_path"
    echo "Generated alias: $alias_path -> $target"
}

generate_wrapper() {
    local agent="$1"
    local wrapper_name="agent-toolbox-${agent}"
    local wrapper_path="${INSTALL_DIR}/${wrapper_name}"
    
    cat > "$wrapper_path" << WRAPPER
#!/bin/bash
# AI Agent Toolbox Wrapper for ${agent}
# Auto-generated, do not edit manually

set -euo pipefail

AGENT="${agent}"
TOOLBOX_CMD="agent-toolbox"

show_help() {
  cat << 'HELP'
  Command: ${wrapper_name}

Usage:
  ${wrapper_name} create [project]     Create toolbox
  ${wrapper_name} enter [project]     Enter toolbox (default)
  ${wrapper_name} run [project] [cmd]  Run command
  ${wrapper_name} build               Build image
  ${wrapper_name} rm [project]        Delete toolbox
  ${wrapper_name} kill [project]      Stop toolbox
  ${wrapper_name} list                List toolboxes

Examples:
  ${wrapper_name}              # Enter default project
  ${wrapper_name} .            # Enter current directory
  ${wrapper_name} myproject    # Enter specified project
  ${wrapper_name} create .     # Create toolbox for current dir
  ${wrapper_name} run .        # Run agent (default command)
  ${wrapper_name} run . git status   # Run git status in toolbox
  ${wrapper_name} kill .       # Stop toolbox

HELP
}

# Parse arguments
cmd=""
project=""
args=()

# First argument could be command or project name
if [[ \$# -eq 0 ]]; then
    # No args: enter default project
    cmd="enter"
    project="."
elif [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "help" ]]; then
    show_help
    exit 0
else
    # Check if first arg is a subcommand
    case "\$1" in
        create|enter|run|build|rm|remove|kill|stop|list|ls)
            cmd="\$1"
            shift
            project="\${1:-.}"
            shift || true
            args=("\$@")
            ;;
        *)
            # Not a command, treat as project name
            cmd="enter"
            project="\$1"
            shift
            args=("\$@")
            ;;
    esac
fi

# Execute command
case "\$cmd" in
    create)
        \$TOOLBOX_CMD create "\$AGENT" "\$project"
        ;;
    enter)
        \$TOOLBOX_CMD enter "\$AGENT" "\$project"
        ;;
    run)
        if [[ \${#args[@]} -eq 0 ]]; then
            \$TOOLBOX_CMD run "\$AGENT" "\$project"
        else
            \$TOOLBOX_CMD run "\$AGENT" "\$project" "\${args[@]}"
        fi
        ;;
    build)
        \$TOOLBOX_CMD build "\$AGENT"
        ;;
    rm|remove)
        \$TOOLBOX_CMD rm "\$AGENT" "\$project"
        ;;
    kill|stop)
        \$TOOLBOX_CMD kill "\$AGENT" "\$project"
        ;;
    list|ls)
        \$TOOLBOX_CMD list | grep "agentbox-\$AGENT"
        ;;
    *)
        echo "Unknown command: \$cmd"
        show_help
        exit 1
        ;;
esac
WRAPPER

    chmod +x "$wrapper_path"
    echo "Generated: $wrapper_path"
}

# Main function
main() {
    echo "Generating agent shortcut commands..."
    echo

    mkdir -p "$INSTALL_DIR"

    for agent in $AGENTS; do
        generate_wrapper "$agent"
    done

    echo
    echo "Generating special aliases..."
    generate_special_aliases

    echo
    echo "Shortcut commands generated at: $INSTALL_DIR"
    echo
    echo "You can now use:"
    for agent in $AGENTS; do
        echo "  agent-toolbox-${agent}"
    done
    echo
    echo "Special aliases:"
    echo "  occ                              # Shortcut for agent-toolbox-occ"
    echo
    echo "Examples:"
    echo "  occ .                            # Enter occ toolbox (short form)"
    echo "  agent-toolbox-occ .              # Enter occ toolbox (full form)"
    echo "  occ create .                     # Create occ toolbox"
    echo "  occ run . git status             # Run git status in occ toolbox"
}

main "$@"
