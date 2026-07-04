#!/usr/bin/env bash
# ==============================================================================
# Interactive theme / icon / cursor selector. Writes the choice to
# $DEBRICE_STATE_DIR/selection.env, then calls apply-theme.sh.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

THEMES=(catppuccin "Catppuccin" \
        tokyo-night "Tokyo Night" \
        nord "Nord" \
        dracula "Dracula" \
        gruvbox "Gruvbox" \
        amoled-black "AMOLED Black" \
        glassmorphism "Glassmorphism" \
        cyberpunk-neon "Cyberpunk Neon")

ICONS=(papirus "Papirus" tela "Tela" colloid "Colloid" whitesur "WhiteSur")
CURSORS=(bibata-ice "Bibata Modern Ice" bibata-classic "Bibata Modern Classic" nordzy "Nordzy")

pick_from_list() {
    # $1 = title, remaining pairs = key label
    local title="$1"; shift
    local -a pairs=("$@")
    local n=$(( ${#pairs[@]} / 2 ))

    if command_exists whiptail; then
        local menu_items=()
        local i=0
        for (( idx=0; idx<${#pairs[@]}; idx+=2 )); do
            i=$((i+1))
            menu_items+=("$i" "${pairs[idx+1]}")
        done
        local choice
        choice=$(whiptail --title "DebRice Setup" --menu "$title" 20 60 "$n" "${menu_items[@]}" 3>&1 1>&2 2>&3) || choice=1
        echo "${pairs[$(( (choice-1)*2 ))]}"
        return
    fi

    # Plain-text fallback (no whiptail available)
    echo -e "\n${C_BOLD}$title${C_RESET}" >&2
    local i=0
    for (( idx=0; idx<${#pairs[@]}; idx+=2 )); do
        i=$((i+1))
        echo "  $i) ${pairs[idx+1]}" >&2
    done
    local sel
    read -r -p "Choose [1-$n]: " sel >&2
    sel="${sel:-1}"
    [[ "$sel" =~ ^[0-9]+$ ]] || sel=1
    (( sel < 1 || sel > n )) && sel=1
    echo "${pairs[$(( (sel-1)*2 ))]}"
}

if [[ "${DEBRICE_NONINTERACTIVE:-0}" == "1" ]]; then
    SELECTED_THEME="${DEBRICE_THEME:-catppuccin}"
    SELECTED_ICONS="${DEBRICE_ICONS:-papirus}"
    SELECTED_CURSOR="${DEBRICE_CURSOR:-bibata-ice}"
else
    SELECTED_THEME="$(pick_from_list "Choose your DebRice theme:" "${THEMES[@]}")"
    SELECTED_ICONS="$(pick_from_list "Choose an icon pack:" "${ICONS[@]}")"
    SELECTED_CURSOR="$(pick_from_list "Choose a cursor theme:" "${CURSORS[@]}")"
fi

log_ok "Selected theme: $SELECTED_THEME | icons: $SELECTED_ICONS | cursor: $SELECTED_CURSOR"

cat > "$DEBRICE_STATE_DIR/selection.env" <<EOF
SELECTED_THEME="$SELECTED_THEME"
SELECTED_ICONS="$SELECTED_ICONS"
SELECTED_CURSOR="$SELECTED_CURSOR"
SELECTED_WAYBAR_STYLE="${DEBRICE_WAYBAR_STYLE:-modern}"
EOF

# Immediately apply it
"$SCRIPT_DIR/apply-theme.sh" "$SELECTED_THEME"
