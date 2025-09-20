#!/bin/bash

# Claude Code Status Line - Directory only
# Outputs the current working directory in macOS short style (HOME -> ~)
# and applies Starship-like directory substitutions per path segment.

set -euo pipefail

# Read JSON from stdin only if stdin is not a TTY; otherwise skip to avoid blocking.
cwd="${PWD:-$HOME}"
if [ ! -t 0 ]; then
    input=$(cat || true)
    if [[ -n "${input:-}" ]]; then
        if command -v jq >/dev/null 2>&1; then
            # Prefer current_dir from ccstatusline, fall back to env vars
            cwd=$(echo "$input" | jq -r '.workspace.current_dir // env.PWD // env.HOME' 2>/dev/null || echo "$cwd")
        fi
    fi
fi

#!/bin/bash

# Starship-like directory substitutions (from starship.toml)
substitute_dir_name() {
    local name="$1"
    case "$name" in
        Documents) echo "󰈙" ;;
        Downloads) echo "" ;;
        Music)     echo "󰝚" ;;
        Pictures)  echo "" ;;
        Projects)  echo "󰲋" ;;
        Desktop)   echo "" ;;
        Videos)    echo "󰕧" ;;
        .config)   echo "" ;;
        .local)    echo "" ;;
        .cache)    echo "" ;;
        *)         echo "$name" ;;
    esac
}

# Convert path to macOS short style and apply substitutions per segment
short_path_from_cwd() {
    local path="$1"
    local home="${HOME%/}"

    # Special cases
    [[ -z "$path" ]] && echo "~" && return 0
    [[ "$path" == "/" ]] && echo "/" && return 0

    # Collapse HOME prefix to ~
    if [[ "$path" == "$home" || "$path" == "$home"/* ]]; then
        path="~${path#"$home"}"
    fi

    # If it's exactly ~, return it
    [[ "$path" == "~" ]] && echo "~" && return 0

    # Split by '/'
    local IFS='/'
    read -r -a parts <<< "$path"

    local result=""
    for i in "${!parts[@]}"; do
        local seg="${parts[$i]}"

        # Preserve leading '/'
        if [[ $i -eq 0 && -z "$seg" ]]; then
            result="/"
            continue
        fi

        # Preserve leading ~
        if [[ $i -eq 0 && "$seg" == "~" ]]; then
            seg="~"
        else
            seg="$(substitute_dir_name "$seg")"
        fi

        if [[ -z "$result" ]]; then
            result="$seg"
        else
            # Avoid '//' after root
            if [[ "$result" == "/" ]]; then
                result+="$seg"
            else
                result+="/$seg"
            fi
        fi
    done

    echo "$result"
}

short_path="$(short_path_from_cwd "$cwd")"

# Print the path string only (no theming)
printf "%s" "$short_path"