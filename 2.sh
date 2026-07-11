#!/bin/bash

# ==========================================
# ติดตั้ง OpenCode AI บน Termux ด้วย NVM
# ==========================================

# สีสวยงาม
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "  ติดตั้ง OpenCode AI แบบมืออาชีพ"
echo -e "  (ใช้ NVM จัดการ Node.js)"
echo -e "==========================================${NC}"

# 1. อัปเดต Termux และติดตั้ง proot-distro
echo -e "${YELLOW}>>> [1/5] อัปเดตระบบ Termux...${NC}"
pkg update -y && pkg upgrade -y

echo -e "${YELLOW}>>> ติดตั้ง proot-distro...${NC}"
pkg install proot-distro -y

# 2. ติดตั้ง Debian
echo -e "${YELLOW}>>> [2/5] กำลังดาวน์โหลดและติดตั้ง Debian (ใช้เวลา 2-5 นาที)...${NC}"
proot-distro install debian

# 3. สร้างสคริปต์ตั้งค่าภายใน Debian
echo -e "${YELLOW}>>> [3/5] สร้างสคริปต์ติดตั้งภายใน Debian...${NC}"
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
echo -e "${YELLOW}>>> [4/5] กำลังติดตั้งใน Debian (ใช้เวลา 3-5 นาที)...${NC}"
chmod +x $HOME/setup-opencode.sh
proot-distro login debian -- bash ~/setup-opencode.sh

# 5. สร้าง alias ให้ใช้งานง่าย
echo -e "${YELLOW}>>> [5/5] สร้างคำสั่งลัด...${NC}"
cat >> ~/.bashrc << 'EOF'

# Alias สำหรับ Debian + OpenCode
alias debian='proot-distro login debian'
alias opencode='proot-distro login debian -- bash -c "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$HOME/.nvm/nvm.sh\" ] && . \"\$HOME/.nvm/nvm.sh\"; opencode \$*"'
EOF

# ทำความสะอาดไฟล์ชั่วคราว
rm -f $HOME/setup-opencode.sh

echo -e "${GREEN}=========================================="
echo -e "  🎉 ติดตั้งทุกอย่างเรียบร้อยแล้ว!"
echo -e "==========================================${NC}"
echo -e ""
echo -e "${BLUE}📌 วิธีใช้งาน:${NC}"
echo -e "  1. เข้า Debian:       ${GREEN}debian${NC}"
echo -e "  2. ใช้ OpenCode:      ${GREEN}opencode --help${NC}"
echo -e "  3. เช็ค Node.js:      ${GREEN}debian -- node -v${NC}"
echo -e ""
echo -e "${YELLOW}💡 รีสตาร์ท Termux หรือรัน: source ~/.bashrc${NC}"
echo -e "${BLUE}==========================================${NC}"
