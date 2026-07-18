#!/usr/bin/env bash
set -euo pipefail

# ==============================
#  Full UI + Animation Theme
# ==============================

# ANSI Colors
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Gradient helper (lightweight)
grad() {
  # Usage: grad "text"
  local s="$1"
  local colors=("${CYAN}" "${BLUE}" "${MAGENTA}" "${YELLOW}" "${GREEN}")
  local out="" i=0
  local len=${#s}
  for ((j=0; j<len; j++)); do
    local ch="${s:j:1}"
    out+="${colors[$((i%${#colors[@]}))]}${ch}${RESET}"
    i=$((i+1))
  done
  echo -e "$out"
}

# UI functions
clear_line() { printf "\r\033[K"; }

log()  { echo -e "${BOLD}${CYAN}➜${RESET} $*"; }
ok()   { echo -e "${BOLD}${GREEN}✓${RESET} $*"; }
warn() { echo -e "${BOLD}${YELLOW}!${RESET} $*"; }
err()  { echo -e "${BOLD}${RED}✗${RESET} $*" >&2; }

# Loading bar (runs while pid alive)
bar() {
  # Usage: bar "message" <pid>
  local msg="$1"
  local pid="$2"
  local width=30
  local chars='▢▣▤▥▦▧▨▩█'
  local i=0

  while kill -0 "$pid" >/dev/null 2>&1; do
    clear_line
    local filled=$(( (i % (width+1)) ))
    local empty=$(( width - filled ))

    # Pick a fancy block color cycling
    local c
    case $((i % 5)) in
      0) c="$CYAN" ;;
      1) c="$BLUE" ;;
      2) c="$MAGENTA" ;;
      3) c="$YELLOW" ;;
      4) c="$GREEN" ;;
    esac

    # Build bar
    local barstr=""
    for ((k=0; k<filled; k++)); do
      barstr+="${c}█${RESET}"
    done
    for ((k=0; k<empty; k++)); do
      barstr+="░"
    done

    printf "%b ${BOLD}%b%b ${DIM}[ ${RESET}%b${DIM} ${DIM}]%b" \
      "${CYAN}•${RESET}" \
      "${WHITE}" "${msg}" "${DIM}" \
      "${barstr}" "${DIM}${RESET}"
    sleep 0.08
    i=$((i+1))
  done

  clear_line
  echo -e "${DIM}done${RESET}"
}

# Spinner fallback (if no pid yet)
spinner() {
  # Usage: spinner "message" command args...
  local msg="$1"; shift
  echo -en "${BOLD}${BLUE}•${RESET} ${msg} "
  "$@" >/dev/null 2>&1 &
  local pid=$!

  local spin='|/-\'
  local i=0
  while kill -0 "$pid" >/dev/null 2>&1; do
    i=$(( (i+1) % 4 ))
    echo -ne "${spin:$i:1}"
    sleep 0.1
    echo -ne "\b"
  done

  wait "$pid" >/dev/null 2>&1 || true
  echo -e "${DIM}done${RESET}"
}

# Quiet apt helpers (match your original "quiet + continue if fails" style)
export DEBIAN_FRONTEND=noninteractive
export DPKG_FORCE=confold
export APT_LISTCHANGES_FRONTEND=none
export LANG=C
export LC_ALL=C

DPKG_OPTS=(
  -o Dpkg::Options::="--force-confold"
  -o Dpkg::Options::="--force-confdef"
)

apt_quiet() {
  # Usage: apt_quiet pkg <subcmd> [args...]
  local subcmd="$1"; shift
  pkg "$subcmd" "$@" "${DPKG_OPTS[@]}" </dev/null 2>&1 || true
}

# Run a command with bar animation, but don't fail script (like your original pattern)
run_with_bar() {
  # Usage: run_with_bar "message" bash -c 'cmd...'
  local msg="$1"; shift
  "$@" >/dev/null 2>&1 &
  local pid=$!
  bar "$msg" "$pid"
  wait "$pid" >/dev/null 2>&1 || true
}

# Ensure ~/.bashrc exists
BASHRC="${HOME}/.bashrc"
touch "$BASHRC" 2>/dev/null || true

# ==============================
#  Header
# ==============================
echo
printf "%b\n" "$(grad " ╔══════════════════════════════╗")"
printf "%b\n" "$(grad " ║   ชุดติดตั้ง + ตั้งค่า Node  ║")"
printf "%b\n" "$(grad " ╚══════════════════════════════╝")"
echo

# ==============================
#  Step 1: Update
# ==============================
log "กำลังอัปเดตรายการแพ็กเกจ..."
run_with_bar "apt update" bash -c 'apt_quiet update -y'

ok "อัปเดตเสร็จ"

# ==============================
#  Step 2: Upgrade
# ==============================
log "กำลังอัปเกรดแพ็กเกจ..."
run_with_bar "apt upgrade" bash -c 'apt_quiet upgrade -y'

ok "อัปเกรดเสร็จ"

# ==============================
#  Step 3: Install tools
# ==============================
log "กำลังติดตั้งเครื่องมือจำเป็น..."
run_with_bar "apt install (curl, nodejs-lts, git, which)" \
  bash -c 'pkg install -y curl nodejs-lts git which "${DPKG_OPTS[@]}" </dev/null 2>&1 || true'

ok "ติดตั้งเครื่องมือเรียบร้อย"

# ==============================
#  Step 4: Node DNS options
# ==============================
NODE_EXPORT='export NODE_OPTIONS=--dns-result-order=ipv4first'

log "ตั้งค่า NODE_OPTIONS ใน ${BASHRC}..."
if grep -qF 'NODE_OPTIONS=--dns-result-order=ipv4first' "$BASHRC" 2>/dev/null; then
  ok "NODE_OPTIONS ถูกตั้งค่าแล้ว"
else
  # Add at end
  echo "" >> "$BASHRC" 2>/dev/null || true
  echo "$NODE_EXPORT" >> "$BASHRC" 2>/dev/null || true
  ok "เพิ่ม NODE_OPTIONS เรียบร้อย"
fi

export NODE_OPTIONS=--dns-result-order=ipv4first

# ==============================
#  Step 5: npm global install
# ==============================
log "กำลังติดตั้ง npm package แบบ global..."
run_with_bar "npm install -g @gitlawb/openclaude" \
  bash -c 'npm install -g @gitlawb/openclaude </dev/null 2>&1 || true'

ok "npm เสร็จเรียบร้อย"

# ==============================
#  Finish
# ==============================
echo
printf "%b\n" "${BOLD}${GREEN}🎉  เสร็จแล้ว!${RESET}"
echo -e "${DIM}NODE_OPTIONS=${WHITE}${NODE_EXPORT#export }${RESET}${DIM}${RESET}"

# Optional: quick success pulse (no external deps)
sleep 0.15
for i in 1 2 3; do
  printf "\r${BOLD}${YELLOW}●${RESET} ${DIM}All set${RESET}"
  sleep 0.12
  printf "\r${BOLD}${GREEN}●${RESET} ${DIM}All set${RESET}"
  sleep 0.12
done
printf "\r${BOLD}${GREEN}✓${RESET} ${DIM}Done${RESET}\n"
