<div align="center">

# 🌸 Debian AI – OpenCode Setup

**ติดตั้ง OpenCode AI บน Termux ผ่าน Debian (proot-distro)**

<p>
  <img src="https://raw.githubusercontent.com/homarr-labs/dashboard-icons/main/svg/opencode.svg" width="80" alt="OpenCode"/>
  &nbsp;&nbsp;
  <img src="https://upload.wikimedia.org/wikipedia/commons/b/b5/Termux.svg" width="80" alt="Termux"/>
</p>

[![Made with](https://img.shields.io/badge/Made%20with-Bash-FF69B4?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![OpenCode](https://img.shields.io/badge/OpenCode-AI-FF1493?logo=openai)](https://opencode.ai)
[![Termux](https://img.shields.io/badge/Termux-Android-FF6B9D?logo=android)](https://termux.com)

</div>

---

```mermaid
flowchart TD
  A["📱 Termux (Android)"] --> B["📦 pkg install proot-distro"]
  B --> C["🐧 proot-distro install debian"]
  C --> D["⬇️ curl · git · nodejs · npm"]
  D --> E["🧪 Install Bun"]
  E --> F["🤖 npm install -g opencode-ai"]
  F --> G["✅ OpenCode พร้อมใช้งาน!"]

  style A fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
  style B fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
  style C fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
  style D fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
  style E fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
  style F fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
  style G fill:#FFB6C1,stroke:#FF1493,stroke-width:2px,color:#8B0A50
```

⚡ วิธีติดตั้ง (คำสั่งเดียว)

```bash
curl -fsSL https://raw.githubusercontent.com/Aa-ok99/debian--ai/main/setup.sh | bash
```

📦 สิ่งที่จะติดตั้งโดยอัตโนมัติ

ลำดับ รายการ รายละเอียด
1 proot-distro ระบบจำลอง Linux บน Termux
2 Debian ระบบปฏิบัติการ Linux
3 curl · git · nodejs · npm เครื่องมือพัฒนา
4 Bun Runtime JavaScript สมัยใหม่
5 OpenCode AI AI coding agent (global)

🚀 วิธีเข้าใช้งาน

หลังติดตั้งเสร็จ ให้รัน:

```bash
proot-distro login debian
opencode
```

⭐ การตั้งค่าเพิ่มเติม

เพื่อให้จัดการไฟล์และใช้งานง่ายขึ้นด้วย 2 คำสั่ง:

· d เข้าสู่สภาพแวดล้อม Debian
· c ดูโฟเดอร์และไฟล์ (d_root) ในสภาพแวดล้อม Termux native

สามารถเปลี่ยนหรือตั้งค่าชื่อคำสั่งตามความสะดวกและชอบของผู้ใช้

```bash
ln -s /data/data/com.termux/files/usr/var/lib/proot-distro/containers/debian/rootfs/root $HOME/d_root

echo 'alias d="proot-distro login debian"' >> ~/.bashrc
echo 'alias c="cd ~/d_root && ls -la"' >> ~/.bashrc

source ~/.bashrc
```

---

<div align="center">

<sub>✨ Repo by @Aa-ok99 | OpenCode is open source</sub>

</div>
