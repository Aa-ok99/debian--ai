#!/bin/bash

# ==========================================
# ติดตั้ง OpenCode AI บน Termux ด้วย NVM
# พร้อมระบบ Alias ครบครัน
# ==========================================

# สีสวยงาม
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "  ติดตั้ง OpenCode AI แบบมืออาชีพ"
echo -e "  (ใช้ NVM + ระบบ Alias ครบ)"
echo -e "==========================================${NC}"

# 1. อัปเดต Termux และติดตั้ง proot-distro
echo -e "${YELLOW}>>> [1/6] อัปเดตระบบ Termux...${NC}"
pkg update -y && pkg upgrade -y

echo -e "${YELLOW}>>> ติดตั้ง proot-distro...${NC}"
pkg install proot-distro -y

# 2. ติดตั้ง Debian
echo -e "${YELLOW}>>> [2/6] กำลังดาวน์โหลดและติดตั้ง Debian (ใช้เวลา 2-5 นาที)...${NC}"
proot-distro install debian

# 3. สร้างสคริปต์ตั้งค่าภายใน Debian
echo -e "${YELLOW}>>> [3/6] สร้างสคริปต์ติดตั้งภายใน Debian...${NC}"
cat > $HOME/setup-opencode.sh << 'EOF'
#!/bin/bash

# สี
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "  ติดตั้ง OpenCode AI ใน Debian (ด้วย NVM)"
echo -e "==========================================${NC}"

# อัปเดต Debian
echo -e "${YELLOW}--- อัปเดต Debian packages ---${NC}"
apt update && apt upgrade -y

# ติดตั้งเครื่องมือพื้นฐาน
echo -e "${YELLOW}--- ติดตั้ง build-essential, curl, git ---${NC}"
apt install curl git build-essential -y

# ติดตั้ง NVM (เวอร์ชันล่าสุด)
echo -e "${YELLOW}--- ติดตั้ง NVM ---${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# โหลด NVM ทันที
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ติดตั้ง Node.js เวอร์ชันล่าสุด
echo -e "${YELLOW}--- ติดตั้ง Node.js เวอร์ชันล่าสุด ---${NC}"
nvm install node
nvm alias default node

# ตรวจสอบเวอร์ชัน
echo -e "${GREEN}✅ ติดตั้ง Node.js สำเร็จ!${NC}"
echo -e "   Node: $(node -v)"
echo -e "   npm:  $(npm -v)"

# ติดตั้ง OpenCode AI แบบ Global
echo -e "${YELLOW}--- ติดตั้ง OpenCode AI (npm install -g) ---${NC}"
npm install -g opencode-ai

# ตรวจสอบการติดตั้ง
if command -v opencode &> /dev/null; then
    echo -e "${GREEN}✅ ติดตั้ง OpenCode AI สำเร็จ!${NC}"
    echo -e "   ลองรัน: opencode --help"
else
    echo -e "${RED}❌ ติดตั้งไม่สำเร็จ ลองติดตั้งใหม่ด้วย:${NC}"
    echo -e "   npm install -g opencode-ai"
fi

# เพิ่ม PATH ให้ .bashrc (เผื่ออนาคต)
echo 'export PATH="$HOME/.nvm/versions/node/$(node -v)/bin:$PATH"' >> ~/.bashrc

echo -e "${GREEN}=========================================="
echo -e "  ติดตั้งเสร็จสมบูรณ์ใน Debian!"
echo -e "==========================================${NC}"
EOF

# 4. ให้สิทธิ์และรันสคริปต์ใน Debian
echo -e "${YELLOW}>>> [4/6] กำลังติดตั้งใน Debian (ใช้เวลา 3-5 นาที)...${NC}"
chmod +x $HOME/setup-opencode.sh
proot-distro login debian -- bash ~/setup-opencode.sh

# 5. สร้างระบบ Alias ครบครัน
echo -e "${YELLOW}>>> [5/6] สร้างระบบ Alias...${NC}"

# สร้างไฟล์ alias แยกต่างหาก
cat > $HOME/.opencode_aliases << 'EOF'
# ==========================================
# Aliases สำหรับ OpenCode AI + Debian
# ==========================================

# --- คำสั่งพื้นฐาน ---
alias debian='proot-distro login debian'
alias debian-root='proot-distro login debian -- bash -c "su -"'

# --- ใช้ OpenCode โดยตรง (ไม่ต้องเข้า Debian) ---
alias opencode='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; opencode \$*"'

# --- ใช้ Node.js / npm จาก Termux โดยตรง ---
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

# เพิ่ม source เข้า .bashrc
if ! grep -q ".opencode_aliases" ~/.bashrc; then
    echo -e "\n# Load OpenCode aliases" >> ~/.bashrc
    echo "source ~/.opencode_aliases" >> ~/.bashrc
    echo -e "${GREEN}✅ เพิ่ม Alias เข้า .bashrc เรียบร้อย${NC}"
else
    echo -e "${YELLOW}⚠️  Alias มีอยู่แล้วใน .bashrc${NC}"
fi

# 6. สร้างไฟล์ช่วยเหลือ (Cheat Sheet)
echo -e "${YELLOW}>>> [6/6] สร้าง Cheat Sheet...${NC}"
cat > $HOME/OPCODE-CHEATSHEET.txt << 'EOF'
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

# โหลด alias ทันที
source ~/.opencode_aliases

# ทำความสะอาดไฟล์ชั่วคราว
rm -f $HOME/setup-opencode.sh

echo -e "${GREEN}=========================================="
echo -e "  🎉 ติดตั้งทุกอย่างเรียบร้อยแล้ว!"
echo -e "==========================================${NC}"
echo -e ""
echo -e "${CYAN}📋 ระบบ Alias ที่สร้างขึ้น:${NC}"
echo -e "  ${GREEN}opencode${NC}        - ใช้ OpenCode AI โดยตรง"
echo -e "  ${GREEN}oc${NC}              - alias ย่อของ opencode"
echo -e "  ${GREEN}debian${NC}          - เข้า Debian"
echo -e "  ${GREEN}node-version${NC}    - เช็ค Node.js + npm version"
echo -e "  ${GREEN}oc-v${NC}            - เช็ค OpenCode version"
echo -e "  ${GREEN}oc-h${NC}            - ดู Help OpenCode"
echo -e "  ${GREEN}update-opencode${NC} - อัปเดต OpenCode AI"
echo -e "  ${GREEN}show-aliases${NC}    - ดู alias ทั้งหมด"
echo -e ""
echo -e "${YELLOW}📖 ดู Cheat Sheet:${NC}"
echo -e "  ${BLUE}cat ~/OPCODE-CHEATSHEET.txt${NC}"
echo -e ""
echo -e "${YELLOW}💡 โหลด alias ทันที: source ~/.bashrc${NC}"
echo -e "${BLUE}==========================================${NC}"
