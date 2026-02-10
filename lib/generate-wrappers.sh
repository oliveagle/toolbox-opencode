#!/bin/bash
# Generate Agent shortcut commands

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
AGENTS="${AGENTS:-occ}"

# Generate special aliases for commonly used agents
generate_special_aliases() {
    # occ -> agentbox-occ
    local alias_name="occ"
    local alias_path="${INSTALL_DIR}/${alias_name}"
    local target="agentbox-occ"

    cat > "$alias_path" << ALIAS
#!/bin/bash
# OCC Alias - shortcut for agentbox-occ
# Auto-generated, do not edit manually

set -euo pipefail
exec "${INSTALL_DIR}/${target}" "\$@"
ALIAS

    chmod +x "$alias_path"
    echo "Generated alias: $alias_path -> $target"
}

generate_wrapper() {
    local agent="$1"
    local wrapper_name="agentbox-${agent}"
    local wrapper_path="${INSTALL_DIR}/${wrapper_name}"
    
    cat > "$wrapper_path" << WRAPPER
#!/bin/bash
# AI Agent Toolbox Wrapper for ${agent}
# Auto-generated, do not edit manually

set -euo pipefail

AGENT="${agent}"
AGENTBOX_CMD="agentbox"

show_help() {
  cat << 'HELP'
  Command: ${wrapper_name}

Usage:
  ${wrapper_name} create [project]     Create agentbox
  ${wrapper_name} enter [project]     Enter agentbox (default)
  ${wrapper_name} run [project] [cmd]  Run command
  ${wrapper_name} build               Build image
  ${wrapper_name} rm [project]        Delete agentbox
  ${wrapper_name} kill [project]      Stop agentbox
  ${wrapper_name} list                List agentboxes

Examples:
  ${wrapper_name}              # Enter default project
  ${wrapper_name} .            # Enter current directory
  ${wrapper_name} myproject    # Enter specified project
  ${wrapper_name} create .     # Create agentbox for current dir
  ${wrapper_name} run .        # Run agent (default command)
  ${wrapper_name} run . git status   # Run git status in agentbox
  ${wrapper_name} kill .       # Stop agentbox

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
        \$AGENTBOX_CMD create "\$AGENT" "\$project"
        ;;
    enter)
        \$AGENTBOX_CMD enter "\$AGENT" "\$project"
        ;;
    run)
        if [[ \${#args[@]} -eq 0 ]]; then
            \$AGENTBOX_CMD run "\$AGENT" "\$project"
        else
            \$AGENTBOX_CMD run "\$AGENT" "\$project" "\${args[@]}"
        fi
        ;;
    build)
        \$AGENTBOX_CMD build "\$AGENT"
        ;;
    rm|remove)
        \$AGENTBOX_CMD rm "\$AGENT" "\$project"
        ;;
    kill|stop)
        \$AGENTBOX_CMD kill "\$AGENT" "\$project"
        ;;
    list|ls)
        \$AGENTBOX_CMD list | grep "agentbox-\$AGENT"
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
        echo "  agentbox-${agent}"
    done
    echo
    echo "Special aliases:"
    echo "  occ                              # Shortcut for agentbox-occ"
    echo
    echo "Examples:"
echo "  occ .                            # Enter occ agentbox (short form)"
echo "  agentbox-occ .              # Enter occ agentbox (full form)"
echo "  occ create .                     # Create occ agentbox"
echo "  occ run . git status             # Run git status in occ agentbox"
}

main "$@"
