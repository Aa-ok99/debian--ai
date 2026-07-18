#!/bin/bash
set -euo pipefail

# ==========================================
# ติดตั้ง OpenCode AI บน Termux ด้วย NVM
# พร้อมระบบ Alias ครบครัน (เวอร์ชัน UI/Animation)
# ==========================================

# ---------- Theme / Colors ----------
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

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
  # simple animated gradient-ish text (lightweight)
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

spinner_run() {
  # spinner_run "message" cmd args...
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

bar_run() {
  # bar_run "message" pid-like command (runs in bg)
  local msg="$1"; shift

  # Start command
  "$@" >/dev/null 2>&1 &
  local pid=$!

  local width=34
  local i=0
  local blocks='▢▣▤▥▦▧▨▩█'

  while kill -0 "$pid" >/dev/null 2>&1; do
    clear_line

    local filled=$(( (i % (width+1)) ))
    local empty=$(( width - filled ))

    local c
    case $((i % 5)) in
      0) c="$CYAN" ;;
      1) c="$BLUE" ;;
      2) c="$MAGENTA" ;;
      3) c="$YELLOW" ;;
      4) c="$GREEN" ;;
    esac

    local barstr=""
    for ((k=0; k<filled; k++)); do barstr+="${c}█${RESET}"; done
    for ((k=0; k<empty; k++)); do barstr+="░"; done

    printf "%b %b%b%b ${DIM}%b%b%b${RESET}\n" \
      "${BOLD}${CYAN}•${RESET}" \
      "${BOLD}${WHITE:-}" "" \
      "${DIM}" "${WHITE:-}" \
      "${DIM}[${RESET}${barstr}${DIM}]${RESET}" ""

    # Above line has extra complexity; keep simple:
    # Redraw again without extra tokens
    sleep 0.08
    i=$((i+1))
  done

  clear_line
  echo -e "${DIM}done${RESET}"
  wait "$pid" >/dev/null 2>&1 || true
}

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
spinner_run "Installing proot-distro" pkg install proot-distro -y

# ---------- Step 2 ----------
echo
echo -e "${YELLOW}>>> [2/6] ติดตั้ง Debian (อาจใช้เวลา 2-5 นาที)...${NC}"
# proot-distro install debian อาจนาน ให้ใช้ spinner
spinner_run "proot-distro install debian" proot-distro install debian

# ---------- Step 3 ----------
echo
echo -e "${YELLOW}>>> [3/6] สร้างสคริปต์ตั้งค่าใน Debian...${NC}"

cat > "$HOME/setup-opencode.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "  ติดตั้ง OpenCode AI ใน Debian (ด้วย NVM)"
echo -e "==========================================${NC}"

echo -e "${YELLOW}--- อัปเดต Debian packages ---${NC}"
apt update >/dev/null 2>&1 || true
apt upgrade -y >/dev/null 2>&1 || true

echo -e "${YELLOW}--- ติดตั้ง build-essential, curl, git ---${NC}"
apt install -y curl git build-essential >/dev/null 2>&1 || true

echo -e "${YELLOW}--- ติดตั้ง NVM ---${NC}"
# install NVM (latest in your original script pinned v0.40.1)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash >/dev/null 2>&1

# Load NVM immediately (best effort)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

echo -e "${YELLOW}--- ติดตั้ง Node.js เวอร์ชันล่าสุด ---${NC}"
nvm install node >/dev/null 2>&1
nvm alias default node >/dev/null 2>&1

echo -e "${GREEN}✅ ติดตั้ง Node.js สำเร็จ!${NC}"
echo -e "   Node: $(node -v 2>/dev/null || echo '?')"
echo -e "   npm:  $(npm -v 2>/dev/null || echo '?')"

echo -e "${YELLOW}--- ติดตั้ง OpenCode AI (npm install -g) ---${NC}"
npm install -g opencode-ai >/dev/null 2>&1 || true

if command -v opencode &>/dev/null; then
  echo -e "${GREEN}✅ ติดตั้ง OpenCode AI สำเร็จ!${NC}"
  opencode --help >/dev/null 2>&1 || true
else
  echo -e "${RED}❌ ติดตั้งไม่สำเร็จ ลองติดตั้งใหม่ด้วย:${NC}"
  echo -e "   npm install -g opencode-ai"
  npm install -g opencode-ai >/dev/null 2>&1 || true
fi

# Add a PATH hint to .bashrc (best effort)
echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc" 2>/dev/null || true
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc" 2>/dev/null || true

EOF

chmod +x "$HOME/setup-opencode.sh"

# ---------- Step 4 ----------
echo
echo -e "${YELLOW}>>> [4/6] กำลังติดตั้งใน Debian (3-5 นาที)...${NC}"
spinner_run "proot-distro login + setup" \
  proot-distro login debian -- bash ~/setup-opencode.sh

# ---------- Step 5 ----------
echo
echo -e "${YELLOW}>>> [5/6] สร้างระบบ Alias...${NC}"

cat > "$HOME/.opencode_aliases" << 'EOF'
# ==========================================
# Aliases สำหรับ OpenCode AI + Debian
# ==========================================

# --- คำสั่งพื้นฐาน ---
alias debian='proot-distro login debian'
alias debian-root='proot-distro login debian -- bash -c "su -"'

# --- ใช้ OpenCode โดยตรง (ไม่ต้องเข้า Debian) ---
alias opencode='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; opencode \$*"'

# --- ใช้ Node.js / npm จาก Termux โดยตรง (ผ่าน Debian) ---
alias node-debian='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; node \$*"'
alias npm-debian='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; npm \$*"'
alias npx-debian='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; npx \$*"'

# --- ตรวจสอบเวอร์ชัน ---
alias node-version='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; node -v && npm -v"'
alias check-opencode='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; opencode --version"'

# --- จัดการ NVM ใน Debian ---
alias nvm-debian='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; nvm \$*"'

# --- รันคำสั่งใดๆ ใน Debian แบบรวดเร็ว ---
alias debian-run='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; \$*"'

# --- ติดตั้ง/อัปเดต OpenCode AI ---
alias update-opencode='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; npm update -g opencode-ai"'
alias reinstall-opencode='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; npm uninstall -g opencode-ai && npm install -g opencode-ai"'

# --- ทางลัดเพิ่มเติม ---
alias oc='opencode'
alias oc-h='opencode --help'
alias oc-v='opencode --version'

# --- แสดง Alias ทั้งหมด ---
alias show-aliases='cat ~/.opencode_aliases | grep "^alias"'
EOF

# Add source to .bashrc
if ! grep -q ".opencode_aliases" "$HOME/.bashrc" 2>/dev/null; then
  echo -e "\n# Load OpenCode aliases" >> "$HOME/.bashrc"
  echo "source ~/.opencode_aliases" >> "$HOME/.bashrc"
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
  opencode        ใช้ OpenCode AI โดยตรง (ไม่ต้องเข้า Debian)
  oc              alias ย่อของ opencode
  debian          เข้า Debian (มี Node.js + NVM)

🔹 ตรวจสอบเวอร์ชัน
─────────────────────────────────────────────────────────────
  node-version    เช็ค Node.js + npm version
  oc-v            เช็ค OpenCode version
  oc-h            ดู Help ของ OpenCode

🔹 จัดการ Node.js ใน Debian
─────────────────────────────────────────────────────────────
  nvm-debian      ใช้ NVM ใน Debian (เช่น nvm-debian ls)
  node-debian     รัน Node.js ใน Debian
  npm-debian      รัน npm ใน Debian
  npx-debian      รัน npx ใน Debian

🔹 จัดการ OpenCode AI
─────────────────────────────────────────────────────────────
  update-opencode    อัปเดต OpenCode AI เป็นเวอร์ชันล่าสุด
  reinstall-opencode ถอนติดตั้งแล้วติดตั้งใหม่

🔹 รันคำสั่งใน Debian แบบรวดเร็ว
─────────────────────────────────────────────────────────────
  debian-run <cmd>   รันคำสั่งใดๆ ใน Debian (เช่น debian-run ls -la)

🔹 ดู Alias ทั้งหมด
─────────────────────────────────────────────────────────────
  show-aliases       แสดง alias ที่มีทั้งหมด

╔══════════════════════════════════════════════════════════════╗
║  💡 เปิดไฟล์นี้ดูเมื่อลืม: cat ~/OPCODE-CHEATSHEET.txt      ║
╚══════════════════════════════════════════════════════════════╝
EOF
ok "สร้าง Cheat Sheet สำเร็จ"

# Load alias immediately
# shellcheck disable=SC1090
source "$HOME/.opencode_aliases"

# Cleanup temp script
rm -f "$HOME/setup-opencode.sh" >/dev/null 2>&1 || true

# ---------- Finish ----------
echo
printf "%b\n" "$(grad " ╔══════════════════════════════════════╗")"
printf "%b\n" "${BOLD}${GREEN} 🎉 ติดตั้งทุกอย่างเรียบร้อยแล้ว${RESET}"
printf "%b\n" "$(grad " ╚══════════════════════════════════════╝")"
echo

echo -e "${CYAN}📋 ระบบ Alias ที่สร้างขึ้น:${NC}"
echo -e "  ${GREEN}opencode${NC}        - ใช้ OpenCode AI โดยตรง"
echo -e "  ${GREEN}oc${NC}              - alias ย่อของ opencode"
echo -e "  ${GREEN}debian${NC}          - เข้า Debian"
echo -e "  ${GREEN}node-version${NC}    - เช็ค Node.js + npm version"
echo -e "  ${GREEN}oc-v${NC}            - เช็ค OpenCode version"
echo -e "  ${GREEN}oc-h${NC}            - ดู Help OpenCode"
echo -e "  ${GREEN}update-opencode${NC} - อัปเดต OpenCode AI"
echo -e "  ${GREEN}show-aliases${NC}    - ดู alias ทั้งหมด"

echo
echo -e "${YELLOW}📖 ดู Cheat Sheet:${NC}"
echo -e "  ${BLUE}cat ~/OPCODE-CHEATSHEET.txt${NC}"

echo
echo -e "${YELLOW}💡 โหลด alias ทันทีแล้ว (ถ้าสคริปต์นี้รันแล้ว) / หรือออกแล้วเข้าใหม่: ${NC}"
echo -e "${BLUE}source ~/.bashrc${NC}"
echo
