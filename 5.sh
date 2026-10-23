#!/usr/bin/env bash
# ============================================================
#  install.sh — All-in-One Termux + Ubuntu proot setup (fixed)
# ============================================================
set -euo pipefail

C_RESET="\033[0m"; C_INFO="\033[36m"; C_OK="\033[32m"; C_WARN="\033[33m"; C_ERR="\033[31m"
log()  { echo -e "${C_INFO}==>${C_RESET} $*"; }
ok()   { echo -e "${C_OK}✔${C_RESET}  $*"; }
warn() { echo -e "${C_WARN}⚠${C_RESET}  $*"; }
err()  { echo -e "${C_ERR}✘${C_RESET}  $*" >&2; }

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/Aa-ok99/debian--ai/main}"
SELF_URL="${SELF_URL:-$REPO_RAW/5.sh}"
UBUNTU_DISTRO="${UBUNTU_DISTRO:-ubuntu}"
NODE_VERSION="${NODE_VERSION:-24}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"

# ---------- helper: รันคำสั่งที่อาจ return non-zero โดยไม่ให้ set -e kill ----------
safe() { "$@" || true; }

detect_env() {
    if [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux/files/usr" ]; then
        echo "termux"
    elif [ -f /etc/os-release ] && grep -qi ubuntu /etc/os-release 2>/dev/null; then
        echo "ubuntu"
    elif [ -n "${PROOT_L2S_DIR:-}" ] || [ -n "${PROOT_TMP_DIR:-}" ]; then
        echo "proot"
    else
        echo "unknown"
    fi
}

# ============================================================
#  STAGE 1 — Termux host
# ============================================================
run_on_termux() {
    log "ตรวจพบ: Termux host"

    log "[1/3] อัปเดตแพ็กเกจ Termux..."
    # ✅ ใช้ -y อย่างเดียว ไม่ต้อง yes | ; ใช้ safe กัน set -e
    safe pkg update -y
    safe pkg upgrade -y

    log "[2/3] ติดตั้ง git / proot-distro / proot..."
    pkg install -y git proot-distro proot

    log "[3/3] เตรียม Ubuntu (${UBUNTU_DISTRO})..."
    if proot-distro list --installed 2>/dev/null | grep -qx "$UBUNTU_DISTRO"; then
        ok "$UBUNTU_DISTRO มีอยู่แล้ว ข้ามการติดตั้ง"
    else
        proot-distro install "$UBUNTU_DISTRO"
        ok "ติดตั้ง $UBUNTU_DISTRO เรียบร้อย"
    fi

    # ดึงสคริปต์ตัวเองเข้าไปใน Ubuntu แล้วรัน stage 2
    log "ส่งสคริปต์เข้าไปรันภายใน $UBUNTU_DISTRO..."
    # ใช้ curl ดึงจาก SELF_URL ถ้า $0 ไม่ใช่ไฟล์จริง (กรณีรันผ่าน pipe)
    if [ -f "$0" ] && [ -s "$0" ]; then
        SCRIPT_SRC="$(cat "$0")"
    else
        log "  \$0 ไม่ใช่ไฟล์ (pipe) → ดึงจาก $SELF_URL"
        SCRIPT_SRC="$(curl -fsSL "$SELF_URL")"
    fi

    # เขียนลง /root ใน ubuntu แล้วรัน
    printf '%s' "$SCRIPT_SRC" | proot-distro login "$UBUNTU_DISTRO" -- bash -c '
        set -e
        cat > /root/install-allinone.sh
        chmod +x /root/install-allinone.sh
        export STAGE=ubuntu
        bash /root/install-allinone.sh
    '

    ok "ติดตั้งเสร็จทั้งหมด!"
    echo
    echo "👉 เข้าใช้งาน:  proot-distro login $UBUNTU_DISTRO"
    echo "👉 ทดสอบ:      node -v && npm -v && pnpm -v && opencode -v"
}

# ============================================================
#  STAGE 2 — Ubuntu (proot-distro)
# ============================================================
run_on_ubuntu() {
    export DEBIAN_FRONTEND=noninteractive
    log "ตรวจพบ: Ubuntu (proot-distro) — เริ่มติดตั้ง toolchain"

    log "[1/5] อัปเดต apt + แพ็กเกจพื้นฐาน..."
    apt update -y
    apt install -y ca-certificates curl git bash

    log "[2/5] ติดตั้ง NVM ${NVM_VERSION}..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" -o /tmp/nvm-install.sh
        bash /tmp/nvm-install.sh
    else
        ok "NVM มีอยู่แล้ว ข้าม"
    fi
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"

    log "[3/5] ติดตั้ง Node ${NODE_VERSION}..."
    if ! nvm ls "$NODE_VERSION" >/dev/null 2>&1; then
        nvm install "$NODE_VERSION"
    fi
    nvm use "$NODE_VERSION" >/dev/null
    nvm alias default "$NODE_VERSION" >/dev/null
    ok "Node: $(node -v)"

    log "[4/5] เปิด Corepack + pnpm..."
    corepack enable
    corepack prepare pnpm@latest --activate
    ok "pnpm: $(pnpm -v)"

    log "[5/5] ติดตั้ง opencode..."
    if curl -fsSL https://opencode.ai/v2/install | bash; then
        ok "ติดตั้ง opencode ผ่าน curl-installer สำเร็จ"
    else
        warn "curl-installer ล้มเหลว → fallback ไป npm"
        npm install -g @opencode/cli
    fi

    echo
    echo "===== สรุปเวอร์ชัน ====="
    node -v
    npm -v
    pnpm -v || warn "pnpm ยังไม่พร้อม"
    opencode -v || warn "opencode ยังไม่พร้อม — logout/login ใหม่"

    # auto-NVM ใน .bashrc
    if ! grep -q 'NVM_DIR' "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" <<'EOF'

# --- NVM auto-load ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
        ok "อัปเดต ~/.bashrc ให้โหลด NVM อัตโนมัติ"
    fi

    ok "ติดตั้งภายใน Ubuntu เสร็จสิ้น!"
}

# ============================================================
#  MAIN
# ============================================================
main() {
    if [ "${STAGE:-}" = "ubuntu" ]; then
        run_on_ubuntu
        return
    fi

    ENV="$(detect_env)"
    log "Environment detected: ${ENV}"

    case "$ENV" in
        termux)  run_on_termux ;;
        ubuntu)  run_on_ubuntu ;;
        proot)   warn "ตรวจพบ proot แต่ไม่ใช่ Ubuntu — ลองรัน stage ubuntu"
                 run_on_ubuntu ;;
        *)       err "ไม่รองรับ environment นี้"; exit 1 ;;
    esac
}

main "$@"
