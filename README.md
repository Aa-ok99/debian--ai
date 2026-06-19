# Debian AI - OpenCode Setup

ติดตั้ง OpenCode AI บน Termux ผ่าน Debian (proot-distro)

## วิธีใช้

รันสคริปต์ติดตั้งด้วยคำสั่งเดียว:

```bash
curl -fsSL https://raw.githubusercontent.com/Aa-ok99/debian--ai/main/setup.sh | bash
```

## สิ่งที่จะติดตั้ง

- Debian ผ่าน proot-distro
- curl, git, nodejs, npm
- Bun
- OpenCode AI (global)

## วิธีเข้าใช้งานหลังติดตั้ง

```bash
proot-distro login debian
opencode
```
