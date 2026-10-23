#!/usr/bin/env bash
# ============================================================
#  install.sh — All-in-One Termux + Ubuntu proot setup
# ------------------------------------------------------------
#  ใช้:
#    curl -fsSL https://raw.githubusercontent.com/<USER>/<REPO>/main/install.sh | bash
#
#  พฤติกรรม:
#    - ถ้ารันบน Termux  → ติดตั้ง proot-distro + Ubuntu แล้ว
#                          re-invoke ตัวเองภายใน Ubuntu อัตโนมัติ
#    - ถ้ารันใน Ubuntu  → ติดตั้ง node24 / pnpm / opencode
# ============================================================
set -euo pipefail

# ---------- สีสำหรับ log ----------
C_RESET="\033[0m"; C_INFO="\033[36m"; C_OK="\033[32m"; C_WARN="\033[33m"; C_ERR="\033[31m"
log()  { echo -e "${C_INFO}==>${C_RESET} $*"; }
ok()   { echo -e "${C_OK}✔${C_RESET}  $*"; }
warn() { echo -e "${C_WARN}⚠${C_RESET}  $*"; }
err()  { echo -e "${C_ERR}✘${C_RESET}  $*" >&2; }

# ---------- ตัวแปรตั้งค่า ----------
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/<USER>/<REPO>/main}"
SELF_URL="${SELF_URL:-$REPO_RAW/install.sh}"
UBUNTU_DISTRO="${UBUNTU_DISTRO:-ubuntu}"
NODE_VERSION="${NODE_VERSION:-24}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"
MARKER_DIR="${HOME}/.cache/termux-ubuntu-setup"

# ============================================================
#  ฟังก์ชัน: ตรวจ environment
# ============================================================
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
#  STAGE 1 — รันบน Termux host
# ============================================================
run_on_termux() {
    log "ตรวจพบ: Termux host"
    log "[1/3] อัปเดตแพ็กเกจ Termux..."
    yes | pkg update -y
    yes | pkg upgrade -y

    log "[2/3] ติดตั้ง git / proot-distro / proot..."
    pkg install -y git proot-distro proot

    log "[3/3] เตรียม Ubuntu (${UBUNTU_DISTRO})..."
    if ! proot-distro list --installed 2>/dev/null | grep -qx "$UBUNTU_DISTRO"; then
        proot-distro install "$UBUNTU_DISTRO"
        ok "ติดตั้ง $UBUNTU_DISTRO เรียบร้อย"
    else
        ok "$UBUNTU_DISTRO มีอยู่แล้ว ข้ามการติดตั้ง"
    fi

    # คัดลอกสคริปต์เข้าไปใน Ubuntu แล้ว re-invoke ตัวเอง
    log "ส่งสคริปต์เข้าไปรันภายใน $UBUNTU_DISTRO..."
    TARGET="/root/install-allinone.sh"
    proot-distro login "$UBUNTU_DISTRO" -- bash -c "
        set -e
        mkdir -p /root
        cat > $TARGET <<'__INNER_EOF__'
$(cat "$0" 2>/dev/null || curl -fsSL "$SELF_URL")
__INNER_EOF__
        chmod +x $TARGET
        export STAGE=ubuntu
        bash $TARGET
    "

    ok "ติดตั้งเสร็จทั้งหมด!"
    echo
    echo "👉 เข้าใช้งาน:  proot-distro login $UBUNTU_DISTRO"
    echo "👉 ทดสอบ:      node -v && npm -v && pnpm -v && opencode -v"
}

# ============================================================
#  STAGE 2 — รันภายใน Ubuntu (proot-distro)
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
    pnpm -v
    opencode -v || warn "opencode ยังไม่พร้อม — ลอง logout/login ใหม่"

    # เขียน .bashrc ให้โหลด NVM อัตโนมัติ
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
#  MAIN — dispatch ตาม environment
# ============================================================
main() {
    # ถ้ามี STAGE ถูก set มาแล้ว ให้ทำงานตามนั้น (ใช้ตอน re-invoke)
    if [ "${STAGE:-}" = "ubuntu" ]; then
        run_on_ubuntu
        return
    fi

    ENV="$(detect_env)"
    log "Environment detected: ${ENV}"

    case "$ENV" in
        termux)  run_on_termux ;;
        ubuntu)  run_on_ubuntu ;;
        proot)   warn "ตรวจพบ proot แต่ไม่ใช่ Ubuntu — พยายามรัน stage ubuntu"
                 run_on_ubuntu ;;
        *)
            err "ไม่รองรับ environment นี้ — ต้องรันบน Termux หรือ Ubuntu (proot-distro)"
            exit 1
            ;;
    esac
}

main "$@"
