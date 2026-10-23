#!/bin/bash
# ==========================================================
#  OpenCode AI Installer for Termux (via proot-distro + NVM)
#  - Idempotent, safe for curl | bash
#  - Tested on fresh Termux (F-Droid / GitHub releases)
#  Author: revised version
# ==========================================================
set -euo pipefail

# ---------- Colors ----------
RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'

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

# ---------- Spinner ----------
# usage: spinner_run "msg" cmd args...
spinner_run() {
  local msg="$1"; shift
  local logf; logf="$(mktemp "${TMPDIR:-/tmp}/spin.XXXXXX")"
  local spin='|/-\\' i=0 pid rc=0

  "$@" >"$logf" 2>&1 </dev/null &
  pid=$!

  # ให้เวลา process เริ่มก่อน (กันกรณีจบทันที)
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

# ==========================================================
#  Pre-flight
# ==========================================================
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

# -------- Header --------
echo
grad " ╔════════════════════════════════════════════╗"
grad " ║   OpenCode AI • Termux • NVM (revised)     ║"
grad " ╚════════════════════════════════════════════╝"
echo

# ==========================================================
#  Step 1: Update Termux
# ==========================================================
echo -e "${YELLOW}>>> [1/6] อัปเดตระบบ Termux...${NC}"
export DEBIAN_FRONTEND=noninteractive

# ซ่อม dpkg state ที่ค้าง (best-effort)
spinner_run "ซ่อม dpkg ที่ค้าง" dpkg --configure -a --force-confold || true

# pkg update/upgrade อาจ exit != 0 แม้สำเร็จ (warn เฉยๆ)
spinner_run "pkg update"  pkg update  -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" \
  || warn "pkg update มี warning (ดำเนินการต่อ)"
spinner_run "pkg upgrade" pkg upgrade -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" \
  || warn "pkg upgrade มี warning (ดำเนินการต่อ)"

# ==========================================================
#  Step 2: proot-distro + ubuntu
# ==========================================================
echo
echo -e "${YELLOW}>>> [2/6] ติดตั้ง proot-distro + ubuntu...${NC}"

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

# ==========================================================
#  Step 3: สร้าง setup script สำหรับ ubuntu (รันฝั่ง ubuntu)
# ==========================================================
echo
echo -e "${YELLOW}>>> [3/6] เตรียมสคริปต์ตั้งค่าฝั่ง ubuntu...${NC}"

SETUP_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/setup-opencode.XXXXXX.sh")"
cat > "$SETUP_SCRIPT" << 'UBUNTU_SETUP_EOF'
#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

printf "%b\n" "${BLUE}==========================================${NC}"
printf "%b\n" "${BLUE}  ติดตั้ง OpenCode AI ใน ubuntu (NVM)     ${NC}"
printf "%b\n" "${BLUE}==========================================${NC}"

export DEBIAN_FRONTEND=noninteractive
export HOME="/root"

printf "%b\n" "${YELLOW}--- apt update / upgrade ---${NC}"
apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" upgrade \
  || echo "warning: apt-get upgrade มี warning (ดำเนินการต่อ)"

printf "%b\n" "${YELLOW}--- ติดตั้ง curl git build-essential ca-certificates ---${NC}"
apt-get install -y --no-install-recommends \
  curl ca-certificates git build-essential

printf "%b\n" "${YELLOW}--- ติดตั้ง NVM ---${NC}"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# shellcheck disable=SC1090,SC1091
. "$NVM_DIR/nvm.sh"

printf "%b\n" "${YELLOW}--- ติดตั้ง Node.js LTS ---${NC}"
nvm install --lts
nvm alias default 'lts/*'
nvm use default

printf "%b\n" "${GREEN}✅ Node: $(node -v)  npm: $(npm -v)${NC}"

printf "%b\n" "${YELLOW}--- ติดตั้ง OpenCode AI (npm pkg: opencode-ai) ---${NC}"
npm install -g opencode-ai

if command -v opencode >/dev/null 2>&1; then
  printf "%b\n" "${GREEN}✅ OpenCode: $(opencode --version 2>/dev/null || echo 'ok')${NC}"
else
  printf "%b\n" "${RED}❌ ไม่พบคำสั่ง opencode${NC}" >&2
  exit 1
fi

# ผูก NVM loader เข้า .bashrc (idempotent)
if ! grep -q 'NVM_DIR' "$HOME/.bashrc" 2>/dev/null; then
  {
    printf '\n# NVM loader\n'
    printf 'export NVM_DIR="$HOME/.nvm"\n'
    printf '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n'
    printf '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"\n'
  } >> "$HOME/.bashrc"
fi

printf "%b\n" "${GREEN}✅ ตั้งค่าฝั่ง ubuntu เสร็จสมบูรณ์${NC}"
UBUNTU_SETUP_EOF

chmod +x "$SETUP_SCRIPT"

# ==========================================================
#  Step 4: รัน setup script ใน ubuntu (ผ่าน pipe — robust)
# ==========================================================
echo
echo -e "${YELLOW}>>> [4/6] ติดตั้งใน ubuntu (อาจใช้เวลา 3-8 นาที)...${NC}"

# ใช้ pipe เข้า bash -s แทนการ copy ไฟล์ → ไม่ต้องรู้ path ภายใน rootfs
if ! proot-distro login ubuntu -- bash -s < "$SETUP_SCRIPT"; then
  err "ติดตั้งฝั่ง ubuntu ล้มเหลว"
  rm -f "$SETUP_SCRIPT"
  exit 1
fi
rm -f "$SETUP_SCRIPT"
ok "ติดตั้งฝั่ง ubuntu สำเร็จ"

# ==========================================================
#  Step 5: Alias file (ฝั่ง Termux)
# ==========================================================
echo
echo -e "${YELLOW}>>> [5/6] สร้างระบบ Alias...${NC}"

ALIAS_FILE="$HOME/.opencode_aliases"
cat > "$ALIAS_FILE" << 'ALIAS_EOF'
# ==========================================================
# OpenCode AI aliases (Termux side)
# ==========================================================

# รันคำสั่งใน ubuntu พร้อม NVM env
_ubuntu_exec() {
  local cmd="$1"; shift
  proot-distro login ubuntu -- bash -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    exec "$0" "$@"
  ' "$cmd" "$@"
}

# --- เข้า ubuntu ---
ubuntu() { proot-distro login ubuntu "$@"; }

# --- OpenCode ---
opencode()    { _ubuntu_exec opencode "$@"; }
oc()          { _ubuntu_exec opencode "$@"; }
oc-h()        { _ubuntu_exec opencode --help; }
oc-v()        { _ubuntu_exec opencode --version; }
update-opencode()    { _ubuntu_exec npm update -g opencode-ai; }
reinstall-opencode() { _ubuntu_exec npm uninstall -g opencode-ai || true; _ubuntu_exec npm install -g opencode-ai; }

# --- Node tools ---
node-ubuntu() { _ubuntu_exec node "$@"; }
npm-ubuntu()  { _ubuntu_exec npm  "$@"; }
npx-ubuntu()  { _ubuntu_exec npx  "$@"; }

# --- nvm (เป็น shell function → ต้องไม่ exec) ---
nvm-ubuntu() {
  proot-distro login ubuntu -- bash -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm "$@"
  ' _ "$@"
}

# --- ตรวจสอบ ---
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

# --- ทั่วไป ---
ubuntu-run() { _ubuntu_exec "$@"; }

show-aliases() {
  grep -E '^[a-z_][a-z0-9_-]*\s*\(\)' "$HOME/.opencode_aliases" | sed 's/() *{.*/()/'
}
ALIAS_EOF

# ผูกเข้า .bashrc (idempotent)
if ! grep -q '.opencode_aliases' "$HOME/.bashrc" 2>/dev/null; then
  {
    printf '\n# Load OpenCode aliases\n'
    printf '[ -f "$HOME/.opencode_aliases" ] && source "$HOME/.opencode_aliases"\n'
  } >> "$HOME/.bashrc"
  ok "เพิ่ม alias ใน .bashrc แล้ว"
else
  ok "alias ถูกโหลดใน .bashrc อยู่แล้ว"
fi

# ==========================================================
#  Step 6: Cheat sheet
# ==========================================================
echo
echo -e "${YELLOW}>>> [6/6] สร้าง Cheat Sheet...${NC}"

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

# โหลด alias ใน session ปัจจุบัน
# shellcheck disable=SC1090
source "$ALIAS_FILE"

# ==========================================================
#  Finish
# ==========================================================
echo
grad " ╔════════════════════════════════════════════╗"
printf "%b\n" "${BOLD}${GREEN}  🎉 ติดตั้งเสร็จสมบูรณ์${RESET}"
grad " ╚════════════════════════════════════════════╝"
echo
echo -e "${CYAN}ลองใช้:${NC}"
echo -e "  ${GREEN}opencode${NC}        - เปิด OpenCode"
echo -e "  ${GREEN}oc-v${NC}            - ดูเวอร์ชัน"
echo -e "  ${GREEN}ubuntu${NC}          - เข้า ubuntu"
echo -e "  ${GREEN}show-aliases${NC}    - ดู alias ทั้งหมด"
echo
echo -e "${YELLOW}💡 คำแนะนำ: เปิด terminal ใหม่ หรือรัน 'source ~/.bashrc'${NC}"
echo
