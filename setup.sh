#!/bin/bash

# ==========================================
# ติดตั้ง OpenCode AI บน Termux (แบบไม่เคยมี Debian)
# ==========================================

echo "=========================================="
echo "  เริ่มต้นการติดตั้งระบบแบบใหม่เอี่ยม"
echo "=========================================="

# 1. อัปเดต Termux และติดตั้ง proot-distro
echo ">>> [1/4] อัปเดตระบบ Termux..."
pkg update && pkg upgrade -y
echo ">>> ติดตั้ง proot-distro..."
pkg install proot-distro -y

# 2. ติดตั้ง Debian (ใช้ชื่อ default คือ debian)
echo ">>> [2/4] กำลังดาวน์โหลดและติดตั้ง Debian (อาจใช้เวลา 2-5 นาที)..."
proot-distro install debian

# 3. เข้าไปตั้งค่าใน Debian และติดตั้งโปรแกรม
echo ">>> [3/4] กำลังเข้าสู่ระบบ Debian เพื่อติดตั้ง OpenCode..."
# ใช้คำสั่ง login แล้วต่อท้ายด้วยคำสั่งที่ต้องการรัน
proot-distro login debian -- bash -c "
    echo '--- อัปเดตฐานข้อมูลแพ็กเกจ Debian ---'
    apt update
    
    echo '--- ติดตั้งเครื่องมือพื้นฐาน (curl, git, nodejs, npm) ---'
    apt install curl git nodejs npm -y
    
    echo '--- ติดตั้ง Bun ---'
    curl -fsSL https://bun.sh/install | bash
    
    echo '--- ติดตั้ง OpenCode AI (แบบ Global) ---'
    npm install -g opencode-ai
    
    echo '--- เสร็จสิ้นการติดตั้งใน Debian ---'
"

# 4. แจ้งผลลัพธ์
echo "=========================================="
echo "✅ ติดตั้งทุกอย่างเรียบร้อยแล้ว!"
echo ""
echo "วิธีเข้าใช้งาน:"
echo "1. พิมพ์คำสั่งนี้ใน Termux เพื่อเข้า Debian:"
echo "   proot-distro login debian"
echo ""
echo "2. เมื่อเข้าไปแล้ว พิมพ์:"
echo "   opencode"
echo "=========================================="