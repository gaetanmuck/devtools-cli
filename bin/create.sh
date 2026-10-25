#!/usr/bin/env bash
set -euo pipefail

# Menu options: "display label:make recipe"
options=(
    "New SvelteKit project:create-project-js"
    "New Python project:create-project-py"
)

DEVTOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAKEFILE="$DEVTOOLS_DIR/Makefile"
selected=0

# Use colors only when the output is a terminal.
if [[ -t 1 ]]; then
    RESET=$'\033[0m'
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    CYAN=$'\033[36m'
    MAGENTA=$'\033[35m'
    GREEN=$'\033[32m'
else
    RESET=''
    BOLD=''
    DIM=''
    CYAN=''
    MAGENTA=''
    GREEN=''
fi

labels=()
recipes=()
for option in "${options[@]}"; do
    labels+=("${option%%:*}")
    recipes+=("${option#*:}")
done

if (( ${#labels[@]} == 0 )); then
    printf 'No project options configured.\n' >&2
    exit 1
fi

print_menu() {
    clear
    printf '%s%s╭────────────────────────────────────╮%s\n' "$MAGENTA" "$BOLD" "$RESET"
    printf '%s%s│       ✨ DEVTOOLS FACTORY ✨       │%s\n' "$MAGENTA" "$BOLD" "$RESET"
    printf '%s%s╰────────────────────────────────────╯%s\n\n' "$MAGENTA" "$BOLD" "$RESET"
    printf '%sWhat are we building today?%s\n\n' "$BOLD" "$RESET"

    for i in "${!labels[@]}"; do
        if (( i == selected )); then
            printf '  %s%s❯  %-30s%s\n' "$CYAN" "$BOLD" "${labels[i]}" "$RESET"
        else
            printf '     %s\n' "${labels[i]}"
        fi
    done

    printf '\n%s  ↑/↓ or j/k navigate   ↵ launch   1-%d select   q quit%s\n' "$DIM" "${#labels[@]}" "$RESET"
}

# A numbered prompt keeps the script usable when stdin isn't interactive.
if [[ ! -t 0 ]]; then
    printf 'What are we building today?\n\n'
    for i in "${!labels[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${labels[i]}"
    done
    printf '\nChoose an option (1-%d): ' "${#labels[@]}"
    read -r choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#labels[@]} )); then
        printf 'Invalid selection.\n' >&2
        exit 1
    fi
    selected=$((choice - 1))
else
    # Read terminal input one byte at a time; arrow keys are ESC [ A/B.
    while true; do
        print_menu
        key=''
        IFS= read -rsn1 key || break

        if [[ "$key" == $'\x1b' ]]; then
            key=''
            IFS= read -rsn1 -t 1 key || true
            if [[ "$key" == '[' || "$key" == 'O' ]]; then
                direction=''
                IFS= read -rsn1 -t 1 direction || true
                case "$direction" in
                    A) selected=$(( (selected - 1 + ${#labels[@]}) % ${#labels[@]} )) ;;
                    B) selected=$(( (selected + 1) % ${#labels[@]} )) ;;
                esac
            fi
            continue
        fi

        case "$key" in
            '') break ;;
            q|Q) clear; printf 'See you next time! 👋\n'; exit 0 ;;
            $'\x03') clear; exit 130 ;;
            k|K) selected=$(( (selected - 1 + ${#labels[@]}) % ${#labels[@]} )) ;;
            j|J) selected=$(( (selected + 1) % ${#labels[@]} )) ;;
            1|2|3|4|5|6|7|8|9)
                choice=$((key))
                if (( choice >= 1 && choice <= ${#labels[@]} )); then
                    selected=$((choice - 1))
                    break
                fi
                ;;
        esac
    done
fi

clear
printf '%s🚀 Launching: %s%s\n\n' "$GREEN" "${labels[selected]}" "$RESET"
exec make -f "$MAKEFILE" "${recipes[selected]}"