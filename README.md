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

  style A fill:#d4edda,stroke:#155724,color:#155724
  style B fill:#c3e6cb,stroke:#155724,color:#155724
  style C fill:#b8daff,stroke:#004085,color:#004085
  style D fill:#d6d8db,stroke:#383d41,color:#383d41
  style E fill:#f8d7da,stroke:#721c24,color:#721c24
  style F fill:#d4edda,stroke:#155724,color:#155724
  style G fill:#cce5ff,stroke:#004085,color:#004085
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

---

<div align="center">

<sub>Repo by [@Aa-ok99](https://github.com/Aa-ok99) | OpenCode is [open source](https://github.com/anomalyco/opencode)</sub>

</div>
