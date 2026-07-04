#!/usr/bin/env bash
# ==============================================================================
# DebRice shared library — logging, error handling, backup/rollback helpers.
# Sourced by every script in the project. Never executed directly.
# ==============================================================================

# Guard against double-sourcing
if [[ -n "${DEBRICE_LIB_LOADED:-}" ]]; then return 0 2>/dev/null || exit 0; fi
DEBRICE_LIB_LOADED=1

set -uo pipefail

# ---- Paths -------------------------------------------------------------
export DEBRICE_HOME="${DEBRICE_HOME:-$HOME/.local/share/debrice}"
export DEBRICE_REPO="${DEBRICE_REPO:-$HOME/.local/share/debrice/repo}"
export DEBRICE_CONFIG_DIR="${DEBRICE_CONFIG_DIR:-$HOME/.config}"
export DEBRICE_STATE_DIR="${DEBRICE_STATE_DIR:-$HOME/.local/state/debrice}"
export DEBRICE_BACKUP_DIR="${DEBRICE_BACKUP_DIR:-$HOME/.local/share/debrice/backups}"
export DEBRICE_LOG_DIR="${DEBRICE_LOG_DIR:-$HOME/.local/share/debrice/logs}"
export DEBRICE_LOG_FILE="${DEBRICE_LOG_FILE:-$DEBRICE_LOG_DIR/debrice-$(date +%Y%m%d-%H%M%S).log}"

mkdir -p "$DEBRICE_HOME" "$DEBRICE_STATE_DIR" "$DEBRICE_BACKUP_DIR" "$DEBRICE_LOG_DIR" 2>/dev/null || true

# ---- Colors --------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET='\033[0m'; C_RED='\033[1;31m'; C_GREEN='\033[1;32m'
    C_YELLOW='\033[1;33m'; C_BLUE='\033[1;34m'; C_MAGENTA='\033[1;35m'
    C_CYAN='\033[1;36m'; C_BOLD='\033[1m'; C_DIM='\033[2m'
else
    C_RESET=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_MAGENTA=''; C_CYAN=''; C_BOLD=''; C_DIM=''
fi

# ---- Logging ---------------------------------------------------------------
_log() {
    local level="$1"; shift
    local msg="$*"
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [$level] $msg" >> "$DEBRICE_LOG_FILE" 2>/dev/null || true
}

log_info()  { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; _log "INFO" "$*"; }
log_ok()    { echo -e "${C_GREEN}[ OK ]${C_RESET} $*"; _log "OK" "$*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; _log "WARN" "$*"; }
log_error() { echo -e "${C_RED}[FAIL]${C_RESET} $*" >&2; _log "ERROR" "$*"; }
log_step()  { echo -e "\n${C_MAGENTA}${C_BOLD}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; _log "STEP" "$*"; }

banner() {
    echo -e "${C_CYAN}${C_BOLD}"
    cat <<'EOF'
   ____       _     ____  _
  |  _ \  ___| |__ |  _ \(_) ___ ___
  | | | |/ _ \ '_ \| |_) | |/ __/ _ \
  | |_| |  __/ |_) |  _ <| | (_|  __/
  |____/ \___|_.__/|_| \_\_|\___\___|

EOF
    echo -e "${C_RESET}${C_DIM}  Automated Hyprland rice for Debian Trixie${C_RESET}\n"
}

# ---- Error handling / rollback ---------------------------------------------
DEBRICE_ROLLBACK_STACK=()

push_rollback() { DEBRICE_ROLLBACK_STACK+=("$1"); }

run_rollback() {
    if [[ ${#DEBRICE_ROLLBACK_STACK[@]} -eq 0 ]]; then return 0; fi
    log_warn "Rolling back changes made during this run..."
    local i
    for (( i=${#DEBRICE_ROLLBACK_STACK[@]}-1; i>=0; i-- )); do
        eval "${DEBRICE_ROLLBACK_STACK[$i]}" 2>/dev/null || true
    done
    log_warn "Rollback complete."
}

trap_error() {
    local exit_code=$?
    local line_no=$1
    if [[ $exit_code -ne 0 ]]; then
        log_error "Command failed (exit $exit_code) at line $line_no in ${BASH_SOURCE[1]:-unknown}"
        log_error "Full log: $DEBRICE_LOG_FILE"
        run_rollback
    fi
    exit "$exit_code"
}

enable_strict_error_trap() {
    set -eE
    trap 'trap_error $LINENO' ERR
}

# ---- Idempotency helpers -----------------------------------------------
# Backs up a target path (file or dir) into the timestamped backup dir,
# only once per run, and only if it exists and isn't already a symlink
# into our own repo (which would mean it's already managed by DebRice).
backup_path() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0

    if [[ -L "$target" ]]; then
        local resolved
        resolved="$(readlink -f "$target" 2>/dev/null || true)"
        if [[ "$resolved" == "$DEBRICE_REPO"* ]]; then
            log_info "Skipping backup of $target (already managed by DebRice)"
            return 0
        fi
    fi

    local session_backup="$DEBRICE_BACKUP_DIR/$DEBRICE_SESSION"
    mkdir -p "$session_backup"
    local rel; rel="$(basename "$target")"
    log_info "Backing up existing $target -> $session_backup/$rel"
    cp -a "$target" "$session_backup/$rel" 2>/dev/null || true
    rm -rf "$target"
}

# Symlinks src -> dest, creating parent dirs, and records rollback action.
link_config() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_path "$dest"
    ln -sfn "$src" "$dest"
    push_rollback "rm -f '$dest'"
    log_ok "Linked $(basename "$dest")"
}

# Runs apt-get in a safe, non-interactive, idempotent way.
apt_install() {
    local pkgs=("$@")
    local to_install=()
    for p in "${pkgs[@]}"; do
        if ! dpkg -s "$p" >/dev/null 2>&1; then
            to_install+=("$p")
        fi
    done
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_ok "All packages already installed (${#pkgs[@]} checked)"
        return 0
    fi
    log_info "Installing: ${to_install[*]}"
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get install -y --no-install-recommends "${to_install[@]}" \
        || { log_error "apt-get failed for: ${to_install[*]}"; return 1; }
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-y}"
    if [[ "${DEBRICE_NONINTERACTIVE:-0}" == "1" ]]; then return 0; fi
    local yn="[Y/n]"; [[ "$default" == "n" ]] && yn="[y/N]"
    read -r -p "$(echo -e "${C_YELLOW}?${C_RESET} $prompt $yn ")" reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy] ]]
}

export DEBRICE_SESSION="${DEBRICE_SESSION:-$(date +%Y%m%d-%H%M%S)}"
