#!/bin/bash
# ==========================================================
#  OpenCode AI Installer for Termux (via proot-distro + NVM)
#  Revised v2 — fixed unbound variable (set -u) issues
# ==========================================================
set -euo pipefail

# ---------- Colors ----------
RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
NC="$RESET"

grad() {
  local s="$1" out="" i=0 j ch
  local colors=("$CYAN" "$BLUE" "$MAGENTA" "$YELLOW" "$GREEN")
  local len=${#s}
  for ((j=0; j<len; j++)); do
    ch="${s:j:1}"
    out+="${colors[$((i%${#colors[@]}))]}${ch}${RESET}"
    i=$((i+1))
  done
  printf "%b\n" "$out"
}

log()  { printf "%b\n" "${BOLD}${CYAN}➜${RESET} $*"; }
ok()   { printf "%b\n" "${BOLD}${GREEN}✓${RESET} $*"; }
warn() { printf "%b\n" "${BOLD}${YELLOW}!${RESET} $*"; }
err()  { printf "%b\n" "${BOLD}${RED}✗${RESET} $*" >&2; }

spinner_run() {
  local msg="$1"; shift
  local logf; logf="$(mktemp "${TMPDIR:-/tmp}/spin.XXXXXX")"
  local spin='|/-\\' i=0 pid rc=0

  "$@" >"$logf" 2>&1 </dev/null &
  pid=$!
  sleep 0.05

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r${BOLD}${BLUE}•${RESET} %s ${spin:$i:1}" "$msg"
    sleep 0.1
  done

  wait "$pid" || rc=$?

  if [ "$rc" -eq 0 ]; then
    printf "\r${BOLD}${BLUE}•${RESET} %s ${DIM}done${RESET}\n" "$msg"
    rm -f "$logf"
  else
    printf "\r${BOLD}${BLUE}•${RESET} %s ${RED}failed${RESET}\n" "$msg"
    err "คำสั่งล้มเหลว (exit $rc): $*"
    printf "%b\n" "${DIM}---- log ล่าสุด (ท้าย 40 บรรทัด) ----${RESET}" >&2
    tail -n 40 "$logf" >&2 || true
    rm -f "$logf"
    return "$rc"
  fi
}

if [ ! -d "/data/data/com.termux" ] && [ -z "${TERMUX_VERSION:-}" ]; then
  warn "ตรวจไม่พบสภาพแวดล้อม Termux"
  ans="n"
  if [ -r /dev/tty ]; then
    read -r -p "ต้องการดำเนินการต่อหรือไม่? [y/N] " ans </dev/tty || ans="n"
  fi
  [[ "$ans" =~ ^[Yy]$ ]] || { err "ยกเลิก"; exit 1; }
fi

if ! command -v pkg >/dev/null 2>&1; then
  err "ไม่พบคำสั่ง 'pkg' — กรุณารันบน Termux"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  spinner_run "ติดตั้ง curl" pkg install -y curl
fi

echo
grad " ╔════════════════════════════════════════════╗"
grad " ║   OpenCode AI • Termux • NVM (revised v2)  ║"
grad " ╚════════════════════════════════════════════╝"
echo

printf "%b\n" "${YELLOW}>>> [1/6] อัปเดตระบบ Termux...${RESET}"
export DEBIAN_FRONTEND=noninteractive

spinner_run "ซ่อม dpkg ที่ค้าง" dpkg --configure -a --force-confold || true

spinner_run "pkg update"  pkg update  -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" \
  || warn "pkg update มี warning (ดำเนินการต่อ)"
spinner_run "pkg upgrade" pkg upgrade -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" \
  || warn "pkg upgrade มี warning (ดำเนินการต่อ)"

echo
printf "%b\n" "${YELLOW}>>> [2/6] ติดตั้ง proot-distro + ubuntu...${RESET}"

if ! command -v proot-distro >/dev/null 2>&1; then
  spinner_run "ติดตั้ง proot-distro" pkg install -y proot-distro
else
  ok "proot-distro มีอยู่แล้ว"
fi

UBUNTU_ROOTFS="${PREFIX}/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ -d "$UBUNTU_ROOTFS" ] && [ -x "$UBUNTU_ROOTFS/bin/bash" ]; then
  ok "ubuntu ติดตั้งไว้แล้ว — ข้ามขั้นตอนนี้"
else
  spinner_run "proot-distro install ubuntu" proot-distro install ubuntu \
    || { err "ติดตั้ง ubuntu ล้มเหลว"; exit 1; }
fi

echo
printf "%b\n" "${YELLOW}>>> [3/6] เตรียมสคริปต์ตั้งค่าฝั่ง ubuntu...${RESET}"

SETUP_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/setup-opencode.XXXXXX.sh")"
cat > "$SETUP_SCRIPT" << 'UBUNTU_SETUP_EOF'
#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; RESET='\033[0m'

printf "%b\n" "${BLUE}==========================================${RESET}"
printf "%b\n" "${BLUE}  ติดตั้ง OpenCode AI ใน ubuntu (NVM)     ${RESET}"
printf "%b\n" "${BLUE}==========================================${RESET}"

export DEBIAN_FRONTEND=noninteractive
export HOME="/root"

printf "%b\n" "${YELLOW}--- apt update / upgrade ---${RESET}"
apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" upgrade \
  || echo "warning: apt-get upgrade มี warning (ดำเนินการต่อ)"

printf "%b\n" "${YELLOW}--- ติดตั้ง curl git build-essential ca-certificates ---${RESET}"
apt-get install -y --no-install-recommends \
  curl ca-certificates git build-essential

printf "%b\n" "${YELLOW}--- ติดตั้ง NVM ---${RESET}"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

. "$NVM_DIR/nvm.sh"

printf "%b\n" "${YELLOW}--- ติดตั้ง Node.js LTS ---${RESET}"
nvm install --lts
nvm alias default 'lts/*'
nvm use default

printf "%b\n" "${GREEN}✅ Node: $(node -v)  npm: $(npm -v)${RESET}"

printf "%b\n" "${YELLOW}--- ติดตั้ง OpenCode AI (npm pkg: opencode-ai) ---${RESET}"
npm install -g opencode-ai

if command -v opencode >/dev/null 2>&1; then
  printf "%b\n" "${GREEN}✅ OpenCode: $(opencode --version 2>/dev/null || echo 'ok')${RESET}"
else
  printf "%b\n" "${RED}❌ ไม่พบคำสั่ง opencode${RESET}" >&2
  exit 1
fi

if ! grep -q 'NVM_DIR' "$HOME/.bashrc" 2>/dev/null; then
  {
    printf '\n# NVM loader\n'
    printf 'export NVM_DIR="$HOME/.nvm"\n'
    printf '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n'
    printf '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"\n'
  } >> "$HOME/.bashrc"
fi

printf "%b\n" "${GREEN}✅ ตั้งค่าฝั่ง ubuntu เสร็จสมบูรณ์${RESET}"
UBUNTU_SETUP_EOF

chmod +x "$SETUP_SCRIPT"

echo
printf "%b\n" "${YELLOW}>>> [4/6] ติดตั้งใน ubuntu (อาจใช้เวลา 3-8 นาที)...${RESET}"

if ! proot-distro login ubuntu -- bash -s < "$SETUP_SCRIPT"; then
  err "ติดตั้งฝั่ง ubuntu ล้มเหลว"
  rm -f "$SETUP_SCRIPT"
  exit 1
fi
rm -f "$SETUP_SCRIPT"
ok "ติดตั้งฝั่ง ubuntu สำเร็จ"

echo
printf "%b\n" "${YELLOW}>>> [5/6] สร้างระบบ Alias...${RESET}"

ALIAS_FILE="$HOME/.opencode_aliases"
cat > "$ALIAS_FILE" << 'ALIAS_EOF'
# ==========================================================
# OpenCode AI aliases (Termux side)
# ==========================================================

_ubuntu_exec() {
  local cmd="$1"; shift
  proot-distro login ubuntu -- bash -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    exec "$0" "$@"
  ' "$cmd" "$@"
}

ubuntu() { proot-distro login ubuntu "$@"; }

opencode()    { _ubuntu_exec opencode "$@"; }
oc()          { _ubuntu_exec opencode "$@"; }
oc-h()        { _ubuntu_exec opencode --help; }
oc-v()        { _ubuntu_exec opencode --version; }
update-opencode()    { _ubuntu_exec npm update -g opencode-ai; }
reinstall-opencode() { _ubuntu_exec npm uninstall -g opencode-ai || true; _ubuntu_exec npm install -g opencode-ai; }

node-ubuntu() { _ubuntu_exec node "$@"; }
npm-ubuntu()  { _ubuntu_exec npm  "$@"; }
npx-ubuntu()  { _ubuntu_exec npx  "$@"; }

nvm-ubuntu() {
  proot-distro login ubuntu -- bash -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm "$@"
  ' _ "$@"
}

node-version() {
  proot-distro login ubuntu -- bash -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    echo "Node: $(node -v 2>/dev/null || echo n/a)"
    echo "npm:  $(npm -v  2>/dev/null || echo n/a)"
    command -v opencode >/dev/null && echo "OpenCode: $(opencode --version 2>/dev/null || echo installed)" || echo "OpenCode: not found"
  '
}
check-opencode() { oc-v; }

ubuntu-run() { _ubuntu_exec "$@"; }

show-aliases() {
  grep -E '^[a-z_][a-z0-9_-]*\s*\(\)' "$HOME/.opencode_aliases" | sed 's/() *{.*/()/'
}
ALIAS_EOF

if ! grep -q '.opencode_aliases' "$HOME/.bashrc" 2>/dev/null; then
  {
    printf '\n# Load OpenCode aliases\n'
    printf '[ -f "$HOME/.opencode_aliases" ] && source "$HOME/.opencode_aliases"\n'
  } >> "$HOME/.bashrc"
  ok "เพิ่ม alias ใน .bashrc แล้ว"
else
  ok "alias ถูกโหลดใน .bashrc อยู่แล้ว"
fi

echo
printf "%b\n" "${YELLOW}>>> [6/6] สร้าง Cheat Sheet...${RESET}"

cat > "$HOME/OPCODE-CHEATSHEET.txt" << 'CHEAT_EOF'
╔══════════════════════════════════════════════════════════════╗
║            📘 OpenCode AI - คู่มือคำสั่งลัด                  ║
╚══════════════════════════════════════════════════════════════╝

🔹 คำสั่งหลัก
  opencode / oc        ใช้ OpenCode AI โดยตรง
  ubuntu               เข้า ubuntu (มี Node + NVM)

🔹 ตรวจสอบเวอร์ชัน
  node-version         Node / npm / OpenCode
  oc-v / oc-h          OpenCode version / help

🔹 NVM / Node ใน ubuntu
  nvm-ubuntu ls        ใช้ NVM ใน ubuntu
  node-ubuntu -v       รัน node
  npm-ubuntu -v        รัน npm
  npx-ubuntu ...       รัน npx

🔹 อัปเดต OpenCode
  update-opencode
  reinstall-opencode

🔹 รันคำสั่งใน ubuntu
  ubuntu-run <cmd>     เช่น  ubuntu-run ls -la

🔹 ดู alias ทั้งหมด
  show-aliases

💡 เปิด cheat sheet: cat ~/OPCODE-CHEATSHEET.txt
CHEAT_EOF
ok "สร้าง Cheat Sheet แล้ว"

source "$ALIAS_FILE"

echo
grad " ╔════════════════════════════════════════════╗"
printf "%b\n" "${BOLD}${GREEN}  🎉 ติดตั้งเสร็จสมบูรณ์${RESET}"
grad " ╚════════════════════════════════════════════╝"
echo
printf "%b\n" "${CYAN}ลองใช้:${RESET}"
printf "  %b\n" "${GREEN}opencode${RESET}        - เปิด OpenCode"
printf "  %b\n" "${GREEN}oc-v${RESET}            - ดูเวอร์ชัน"
printf "  %b\n" "${GREEN}ubuntu${RESET}          - เข้า ubuntu"
printf "  %b\n" "${GREEN}show-aliases${RESET}    - ดู alias ทั้งหมด"
echo
printf "%b\n" "${YELLOW}💡 คำแนะนำ: เปิด terminal ใหม่ หรือรัน 'source ~/.bashrc'${RESET}"
echo
