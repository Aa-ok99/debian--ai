#!/bin/bash
set -euo pipefail

# ==========================================
# ติดตั้ง OpenCode AI บน Termux ด้วย NVM
# พร้อมระบบ Alias ครบครัน (เวอร์ชัน UI/Animation)
# แก้ไขโดยผู้ชำนาญ - พร้อมใช้งาน
# ==========================================

# ---------- Theme / Colors ----------
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
WHITE="\033[1;37m"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---------- Helpers ----------
clear_line(){ printf "\r\033[K"; }

grad() {
  local s="$1"
  local colors=("$CYAN" "$BLUE" "$MAGENTA" "$YELLOW" "$GREEN")
  local out="" i=0
  local len=${#s}
  for ((j=0; j<len; j++)); do
    local ch="${s:j:1}"
    out+="${colors[$((i%${#colors[@]}))]}${ch}${RESET}"
    i=$((i+1))
  done
  echo -e "$out"
}

log()  { echo -e "${BOLD}${CYAN}➜${RESET} $*"; }
ok()   { echo -e "${BOLD}${GREEN}✓${RESET} $*"; }
warn() { echo -e "${BOLD}${YELLOW}!${RESET} $*"; }
err()  { echo -e "${BOLD}${RED}✗${RESET} $*" >&2; }

# spinner_run: แสดง spinner ระหว่างรันคำสั่ง
# ใช้ log ไฟล์ชั่วคราวเพื่อ preserve exit code
spinner_run() {
  local msg="$1"; shift
  local logf
  logf="$(mktemp "${TMPDIR:-/tmp}/spin.XXXXXX")"

  echo -en "${BOLD}${BLUE}•${RESET} ${msg} "
  "$@" >"$logf" 2>&1 &
  local pid=$!

  local spin='|/-\\'
  local i=0
  while kill -0 "$pid" >/dev/null 2>&1; do
    i=$(( (i+1) % 4 ))
    echo -ne "${spin:$i:1}"
    sleep 0.1
    echo -ne "\b"
  done

  local rc=0
  wait "$pid" || rc=$?

  if [ "$rc" -eq 0 ]; then
    echo -e "${DIM}done${RESET}"
    rm -f "$logf"
  else
    echo -e "${RED}failed${RESET}"
    err "คำสั่งล้มเหลว (exit $rc): $*"
    echo -e "${DIM}---- log ล่าสุด ----${RESET}"
    tail -n 30 "$logf" >&2 || true
    rm -f "$logf"
    return "$rc"
  fi
}

# ---------- Pre-flight checks ----------
if [ ! -d "/data/data/com.termux" ] && [ -z "${TERMUX_VERSION:-}" ]; then
  warn "ตรวจไม่พบสภาพแวดล้อม Termux — สคริปต์นี้ออกแบบมาสำหรับ Termux"
  read -r -p "ต้องการดำเนินการต่อหรือไม่? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { err "ยกเลิก"; exit 1; }
fi

if ! command -v pkg >/dev/null 2>&1; then
  err "ไม่พบคำสั่ง 'pkg' — กรุณารันบน Termux"
  exit 1
fi

# ตรวจเน็ตเวิร์ก
if ! command -v curl >/dev/null 2>&1; then
  spinner_run "ติดตั้ง curl" pkg install -y curl
fi

# -------- Header --------
echo
printf "%b\n" "$(grad " ╔══════════════════════════════════════╗")"
printf "%b\n" "$(grad " ║     OpenCode AI • Termux • NVM      ║")"
printf "%b\n" "$(grad " ╚══════════════════════════════════════╝")"
echo
log "เริ่มติดตั้งแบบมืออาชีพ (มี UI/แอนิเมชั่น) ..."
echo

# ---------- Step 1 ----------
echo -e "${YELLOW}>>> [1/6] อัปเดตระบบ Termux...${NC}"
spinner_run "pkg update" pkg update -y
spinner_run "pkg upgrade" pkg upgrade -y

echo
echo -e "${YELLOW}>>> ติดตั้ง proot-distro...${NC}"
if ! command -v proot-distro >/dev/null 2>&1; then
  spinner_run "Installing proot-distro" pkg install -y proot-distro
else
  ok "proot-distro มีอยู่แล้ว"
fi

# ---------- Step 2 ----------
echo
echo -e "${YELLOW}>>> [2/6] ติดตั้ง ubuntu (อาจใช้เวลา 2-5 นาที)...${NC}"
# ตรวจว่ามี ubuntu อยู่แล้วหรือยัง
if proot-distro list 2>/dev/null | grep -qE '^\s*ubuntu\s' && \
   [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
  ok "ubuntu ถูกติดตั้งไว้แล้ว — ข้ามขั้นตอนนี้"
else
  spinner_run "proot-distro install ubuntu" proot-distro install ubuntu
fi

# ---------- Step 3 ----------
echo
echo -e "${YELLOW}>>> [3/6] สร้างสคริปต์ตั้งค่าใน ubuntu...${NC}"

SETUP_SCRIPT="$HOME/setup-opencode.sh"
cat > "$SETUP_SCRIPT" << 'EOF'
#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "  ติดตั้ง OpenCode AI ใน ubuntu (ด้วย NVM)"
echo -e "==========================================${NC}"

echo -e "${YELLOW}--- อัปเดต ubuntu packages ---${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo -e "${YELLOW}--- ติดตั้ง build-essential, curl, git ---${NC}"
apt-get install -y curl git build-essential ca-certificates

echo -e "${YELLOW}--- ติดตั้ง NVM ---${NC}"
# URL ที่ถูกต้อง: install.sh (ไม่ใช่ 5.sh — นั่นเป็นชื่อไฟล์ของคุณ!)
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

echo -e "${YELLOW}--- ติดตั้ง Node.js LTS ---${NC}"
nvm install --lts
nvm alias default 'lts/*'
nvm use default

echo -e "${GREEN}✅ ติดตั้ง Node.js สำเร็จ!${NC}"
echo -e "   Node: $(node -v 2>/dev/null || echo '?')"
echo -e "   npm:  $(npm -v 2>/dev/null || echo '?')"

echo -e "${YELLOW}--- ติดตั้ง OpenCode AI ---${NC}"
# ชื่อ package ที่ถูกต้องคือ 'opencode-ai'
npm install -g opencode-ai

if command -v opencode &>/dev/null; then
  echo -e "${GREEN}✅ ติดตั้ง OpenCode AI สำเร็จ! ($(opencode --version 2>/dev/null || echo '?'))${NC}"
else
  echo -e "${RED}❌ ไม่พบคำสั่ง opencode — ลองติดตั้งใหม่ภายหลัง${NC}"
  exit 1
fi

# เพิ่ม NVM loader ใน .bashrc (idempotent)
if ! grep -q 'NVM_DIR' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" << 'RC'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
RC
fi

echo -e "${GREEN}✅ ตั้งค่า ubuntu เสร็จสมบูรณ์${NC}"
EOF

chmod +x "$SETUP_SCRIPT"

# ---------- Step 4 ----------
echo
echo -e "${YELLOW}>>> [4/6] กำลังติดตั้งใน ubuntu (3-5 นาที)...${NC}"
# สำคัญ: ต้อง copy สคริปต์เข้า rootfs ก่อน เนื่องจาก ~ ฝั่ง Termux ≠ ~ ฝั่ง ubuntu
UBUNTU_HOME="/root"   # proot-distro login ubuntu ใช้ root เป็น default
DEST="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu${UBUNTU_HOME}/setup-opencode.sh"
cp "$SETUP_SCRIPT" "$DEST"
chmod +x "$DEST"

spinner_run "proot-distro login + setup" \
  proot-distro login ubuntu -- bash "$UBUNTU_HOME/setup-opencode.sh"

# ---------- Step 5 ----------
echo
echo -e "${YELLOW}>>> [5/6] สร้างระบบ Alias...${NC}"

ALIAS_FILE="$HOME/.opencode_aliases"
cat > "$ALIAS_FILE" << 'EOF'
# ==========================================
# Aliases สำหรับ OpenCode AI + ubuntu
# ==========================================
# หมายเหตุ: ใช้ฟังก์ชันแทน alias เพื่อรองรับการส่ง argument ข้าม proot-distro

_ubuntu_exec() {
  # รันคำสั่งใน ubuntu พร้อม load NVM
  local cmd="$1"; shift
  proot-distro login ubuntu -- bash -c \
    'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; '"$cmd"' "$@"' _ "$@"
}

# --- เข้า ubuntu ---
ubuntu()      { proot-distro login ubuntu "$@"; }
ubuntu-root() { proot-distro login ubuntu -- bash -c 'su -'; }

# --- ใช้ OpenCode โดยตรง ---
opencode()    { _ubuntu_exec opencode "$@"; }
oc()          { opencode "$@"; }
oc-h()        { opencode --help; }
oc-v()        { opencode --version; }

# --- Node / npm / npx ---
node-ubuntu() { _ubuntu_exec node "$@"; }
npm-ubuntu()  { _ubuntu_exec npm "$@"; }
npx-ubuntu()  { _ubuntu_exec npx "$@"; }

# --- ตรวจสอบเวอร์ชัน ---
node-version() {
  proot-distro login ubuntu -- bash -c \
    'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; echo "Node: $(node -v)"; echo "npm:  $(npm -v)"'
}
check-opencode() { oc-v; }

# --- จัดการ NVM ---
nvm-ubuntu()  { _ubuntu_exec nvm "$@"; }

# --- รันคำสั่งใดๆ ใน ubuntu ---
ubuntu-run()  { _ubuntu_exec "$@"; }

# --- ติดตั้ง/อัปเดต OpenCode AI ---
update-opencode()    { _ubuntu_exec npm update -g opencode-ai; }
reinstall-opencode() { _ubuntu_exec npm uninstall -g opencode-ai; _ubuntu_exec npm install -g opencode-ai; }

# --- แสดง alias/function ทั้งหมด ---
show-aliases() {
  grep -E '^(alias|_ubuntu_exec|[a-z][a-z0-9_-]*\(\))' "$HOME/.opencode_aliases"
}
EOF

# ผูกกับ .bashrc
if ! grep -q ".opencode_aliases" "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ""
    echo "# Load OpenCode aliases"
    echo '[ -f "$HOME/.opencode_aliases" ] && source "$HOME/.opencode_aliases"'
  } >> "$HOME/.bashrc"
  ok "เพิ่ม Alias เข้า .bashrc เรียบร้อย"
else
  warn "Alias มีอยู่แล้วใน .bashrc"
fi

# ---------- Step 6 ----------
echo
echo -e "${YELLOW}>>> [6/6] สร้าง Cheat Sheet...${NC}"
cat > "$HOME/OPCODE-CHEATSHEET.txt" << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║            📘 OpenCode AI - คู่มือคำสั่งลัด                  ║
╚══════════════════════════════════════════════════════════════╝

🔹 คำสั่งหลัก
─────────────────────────────────────────────────────────────
  opencode        ใช้ OpenCode AI โดยตรง (ไม่ต้องเข้า ubuntu)
  oc              คำย่อของ opencode
  ubuntu          เข้า ubuntu (มี Node.js + NVM)

🔹 ตรวจสอบเวอร์ชัน
─────────────────────────────────────────────────────────────
  node-version    เช็ค Node.js + npm version
  oc-v            เช็ค OpenCode version
  oc-h            ดู Help ของ OpenCode

🔹 จัดการ Node.js ใน ubuntu
─────────────────────────────────────────────────────────────
  nvm-ubuntu      ใช้ NVM ใน ubuntu (เช่น nvm-ubuntu ls)
  node-ubuntu     รัน Node.js ใน ubuntu
  npm-ubuntu      รัน npm ใน ubuntu
  npx-ubuntu      รัน npx ใน ubuntu

🔹 จัดการ OpenCode AI
─────────────────────────────────────────────────────────────
  update-opencode     อัปเดต OpenCode AI เป็นเวอร์ชันล่าสุด
  reinstall-opencode  ถอนติดตั้งแล้วติดตั้งใหม่

🔹 รันคำสั่งใน ubuntu แบบรวดเร็ว
─────────────────────────────────────────────────────────────
  ubuntu-run <cmd>    รันคำสั่งใดๆ ใน ubuntu (เช่น ubuntu-run ls -la)

🔹 ดู Alias ทั้งหมด
─────────────────────────────────────────────────────────────
  show-aliases        แสดง alias/function ที่มีทั้งหมด

╔══════════════════════════════════════════════════════════════╗
║  💡 เปิดไฟล์นี้ดูเมื่อลืม: cat ~/OPCODE-CHEATSHEET.txt      ║
╚══════════════════════════════════════════════════════════════╝
EOF
ok "สร้าง Cheat Sheet สำเร็จ"

# โหลด alias ทันทีใน session ปัจจุบัน
# shellcheck disable=SC1090
source "$ALIAS_FILE"

# Cleanup
rm -f "$SETUP_SCRIPT" >/dev/null 2>&1 || true

# ---------- Finish ----------
echo
printf "%b\n" "$(grad " ╔══════════════════════════════════════╗")"
printf "%b\n" "${BOLD}${GREEN} 🎉 ติดตั้งทุกอย่างเรียบร้อยแล้ว${RESET}"
printf "%b\n" "$(grad " ╚══════════════════════════════════════╝")"
echo

echo -e "${CYAN}📋 คำสั่งที่ใช้งานได้ทันที:${NC}"
echo -e "  ${GREEN}opencode${NC}         - ใช้ OpenCode AI โดยตรง"
echo -e "  ${GREEN}oc${NC}               - คำย่อของ opencode"
echo -e "  ${GREEN}ubuntu${NC}           - เข้า ubuntu"
echo -e "  ${GREEN}node-version${NC}     - เช็ค Node.js + npm version"
echo -e "  ${GREEN}oc-v${NC}             - เช็ค OpenCode version"
echo -e "  ${GREEN}oc-h${NC}             - ดู Help OpenCode"
echo -e "  ${GREEN}update-opencode${NC}  - อัปเดต OpenCode AI"
echo -e "  ${GREEN}show-aliases${NC}     - ดู alias/function ทั้งหมด"

echo
echo -e "${YELLOW}📖 ดู Cheat Sheet:${NC}"
echo -e "  ${BLUE}cat ~/OPCODE-CHEATSHEET.txt${NC}"
echo
echo -e "${YELLOW}💡 Alias ถูกโหลดใน session นี้แล้ว / session ใหม่จะโหลดอัตโนมัติ:${NC}"
echo -e "  ${BLUE}source ~/.bashrc${NC}"
echo
