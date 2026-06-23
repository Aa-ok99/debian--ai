<div align="center">

# 🍃 Debian AI – OpenCode Setup

**ติดตั้ง OpenCode AI บน Termux ผ่าน Debian (proot-distro)**

<p>
  <img src="https://raw.githubusercontent.com/homarr-labs/dashboard-icons/main/svg/opencode.svg" width="80" alt="OpenCode"/>
  &nbsp;&nbsp;
  <img src="https://upload.wikimedia.org/wikipedia/commons/b/b5/Termux.svg" width="80" alt="Termux"/>
</p>

[![Made with](https://img.shields.io/badge/Made%20with-Bash-2ea44f?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![OpenCode](https://img.shields.io/badge/OpenCode-AI-008000?logo=openai)](https://opencode.ai)
[![Termux](https://img.shields.io/badge/Termux-Android-00c853?logo=android)](https://termux.com)

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

  style A fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
  style B fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
  style C fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
  style D fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
  style E fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
  style F fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
  style G fill:#98FF98,stroke:#1a7f1a,stroke-width:2px,color:#0a3d0a
```

## ⚡ วิธีติดตั้ง (คำสั่งเดียว)

```bash
curl -fsSL https://raw.githubusercontent.com/Aa-ok99/debian--ai/main/setup.sh | bash
```

## 📦 สิ่งที่จะติดตั้งโดยอัตโนมัติ

| ลำดับ | รายการ | รายละเอียด |
|------|--------|-----------|
| 1 | **proot-distro** | ระบบจำลอง Linux บน Termux |
| 2 | **Debian** | ระบบปฏิบัติการ Linux |
| 3 | **curl · git · nodejs · npm** | เครื่องมือพัฒนา |
| 4 | **Bun** | Runtime JavaScript สมัยใหม่ |
| 5 | **OpenCode AI** | AI coding agent (global) |

## 🚀 วิธีเข้าใช้งาน

หลังติดตั้งเสร็จ ให้รัน:

```bash
proot-distro login debian
opencode
```

## ⭐ การ setup เพิ่มเติม 

เพื่อให้จัดการไฟล์​และใช้งานง่าย:

```bash
ln -s /data/data/com.termux/files/usr/var/lib/proot-distro/containers/debian/rootfs/root $HOME/d_root

echo 'alias d="proot-distro login debian"' >> ~/.bashrc
echo 'alias c="cd ~/d_root && ls -la"' >> ~/.bashrc

source ~/.bashrc
```
---

<div align="center">

<sub>Repo by [@Aa-ok99](https://github.com/Aa-ok99) | OpenCode is [open source](https://github.com/anomalyco/opencode)</sub>

</div>
