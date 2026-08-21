#!/bin/bash
# =============================================================================
# Tools Installer: proot-distro Ubuntu + OpenCode (Termux)
# =============================================================================
# Script ini memandu user dari Termux polos hingga OpenCode siap digunakan
# di dalam environment Ubuntu proot-distro.
#
# Cara menjalankan:
#   bash tools.sh
#
# Requisitos:
#   - Termux di Android (arm64/armhf)
#   - Koneksi internet aktif
#   - Tidak memerlukan root access
# =============================================================================

set -o pipefail

# -----------------------------------------------------------------------------
# Konfigurasi Warna ANSI
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# -----------------------------------------------------------------------------
# Variabel Global
# -----------------------------------------------------------------------------
SCRIPT_NAME="tools.sh"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
OPENCODE_BIN_DIR="$HOME/.opencode/bin"
PROOT_ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Menampilkan pesan error dengan format konsisten
error() {
    echo -e "  ${RED}✖ ERROR${RESET}  ${BOLD}$1${RESET}" >&2
}

# Menampilkan pesan sukses
success() {
    echo -e "  ${GREEN}✔${RESET} $1"
}

# Menampilkan pesan warning
warning() {
    echo -e "  ${YELLOW}⚠${RESET} $1"
}

# Menampilkan pesan info
info() {
    echo -e "  ${CYAN}ℹ${RESET} $1"
}

# Menampilkan banner judul
show_banner() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}   ${BOLD}🛠  Tools Installer: Ubuntu + OpenCode${RESET}                  ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}      ${DIM}proot-distro Termux Android${RESET}                        ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}└──────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

# -----------------------------------------------------------------------------
# Deteksi Environment
# -----------------------------------------------------------------------------

# Mengecek apakah berjalan di Termux base
is_termux() {
    if [[ -n "$PREFIX" && "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        return 0
    fi
    return 1
}

# Mengecek apakah berjalan di dalam proot Ubuntu
is_proot_ubuntu() {
    if [[ -f /etc/os-release ]]; then
        if grep -qi "ubuntu" /etc/os-release; then
            return 0
        fi
    fi
    return 1
}

# Mendapatkan konteks environment saat ini
get_context() {
    if is_proot_ubuntu; then
        echo "Ubuntu (proot-distro)"
    elif is_termux; then
        echo "Termux Base"
    else
        echo "Unknown"
    fi
}

# -----------------------------------------------------------------------------
# Fungsi: Menu Utama
# -----------------------------------------------------------------------------
show_menu() {
    local context
    context=$(get_context)

    show_banner
    echo -e "  ${DIM}Environment:${RESET} ${BOLD}$context${RESET}"
    echo ""
    echo -e "  ${GREEN}▶${RESET}  ${BOLD}1${RESET}) Install proot-distro Ubuntu"
    echo -e "  ${GREEN}▶${RESET}  ${BOLD}2${RESET}) Install OpenCode"
    echo -e "  ${GREEN}▶${RESET}  ${BOLD}3${RESET}) Keluar"
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────${RESET}"
    echo ""
}

# -----------------------------------------------------------------------------
# Fungsi: Opsi 1 — Install proot-distro Ubuntu
# -----------------------------------------------------------------------------
install_proot_ubuntu() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ 📦 Install proot-distro Ubuntu ━━━${RESET}"
    echo ""

    # Hanya bisa dijalankan dari Termux base
    if ! is_termux; then
        error "Opsi ini hanya dapat dijalankan dari Termux base."
        warning "Jika Anda sudah berada di dalam Ubuntu, lewati ke opsi 2."
        echo ""
        return 1
    fi

    # Langkah 1: Pastikan proot-distro tersedia
    info "Memeriksa ketersediaan proot-distro..."
    if ! command -v proot-distro &>/dev/null; then
        warning "proot-distro belum terinstall. Menginstall via pkg..."
        pkg update -y || {
            error "Gagal menjalankan 'pkg update'. Periksa koneksi internet."
            return 1
        }
        pkg install proot-distro -y || {
            error "Gagal menginstall proot-distro. Coba jalankan manual: pkg install proot-distro"
            return 1
        }
        success "proot-distro berhasil diinstall."
    else
        info "proot-distro sudah tersedia."
    fi

    # Langkah 2: Cek apakah Ubuntu sudah pernah diinstall
    local ubuntu_installed=false
    local proot_list_output
    proot_list_output=$(proot-distro list 2>/dev/null)

    if echo "$proot_list_output" | grep -q "ubuntu.*installed"; then
        ubuntu_installed=true
    fi

    if $ubuntu_installed; then
        echo -e "  ${YELLOW}⚠ Ubuntu sudah terinstall sebelumnya.${RESET}"
        echo ""
        echo "  Pilih tindakan:"
        echo ""
        echo -e "    ${GREEN}1${RESET}) Login ke Ubuntu ${DIM}(direkomendasikan)${RESET}"
        echo -e "    ${GREEN}2${RESET}) Install ulang Ubuntu ${DIM}(data lama akan hilang)${RESET}"
        echo -e "    ${GREEN}0${RESET}) Kembali ke menu utama"
        echo ""
        read -rp "  Pilihan [1/2/0]: " choice

        case "$choice" in
            1)
                info "Login ke Ubuntu..."
                echo ""
                proot-distro login ubuntu
                return $?
                ;;
            2)
                warning "Menghapus instalasi Ubuntu lama..."
                proot-distro remove ubuntu || {
                    error "Gagal menghapus Ubuntu lama."
                    return 1
                }
                success "Ubuntu lama dihapus."
                ;;
            0)
                return 0
                ;;
            *)
                warning "Pilihan tidak valid. Kembali ke menu utama."
                return 0
                ;;
        esac
    fi

    # Langkah 3: Install Ubuntu
    echo ""
    info "Menginstall Ubuntu via proot-distro..."
    echo -e "${YELLOW}Proses ini memerlukan koneksi internet dan dapat memakan waktu beberapa menit.${RESET}"
    echo ""
    proot-distro install ubuntu || {
        error "Gagal menginstall Ubuntu."
        error "Saran: Jalankan 'pkg update && pkg install proot-distro' secara manual, lalu coba lagi."
        return 1
    }
    success "Ubuntu berhasil diinstall!"
    echo ""

    # Langkah 4: Verifikasi path rootfs
    if [[ ! -d "$PROOT_ROOTFS" ]]; then
        error "Path rootfs Ubuntu tidak ditemukan: $PROOT_ROOTFS"
        error "Script tidak dapat menyalin dirinya sendiri ke dalam Ubuntu."
        return 1
    fi

    # Langkah 5: Salin script ke dalam Ubuntu
    local target_dir="$PROOT_ROOTFS/root"
    local target_path="$target_dir/$SCRIPT_NAME"

    info "Menyalin script ke dalam Ubuntu: $target_path"
    mkdir -p "$target_dir" || {
        error "Gagal membuat direktori $target_dir"
        return 1
    }
    cp -f "$SCRIPT_PATH" "$target_path" || {
        error "Gagal menyalin script ke Ubuntu."
        return 1
    }
    chmod +x "$target_path" || true
    success "Script tersalin ke Ubuntu."
    echo ""

    # Langkah 6: Tampilkan instruksi
    echo -e "${BOLD}${GREEN}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  ${BOLD}✅ Setup Ubuntu Berhasil!${RESET}                              ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}├──────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}                                                  ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  Script telah disalin ke dalam Ubuntu.           ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  Setelah masuk, jalankan ulang script:           ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}    ${CYAN}bash $SCRIPT_NAME${RESET}                          ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  Lalu pilih opsi ${GREEN}2${RESET}.                               ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}                                                  ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}└──────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    info "Login ke Ubuntu..."
    echo -e "${YELLOW}(Ketik 'exit' di dalam Ubuntu untuk kembali ke Termux)${RESET}"
    echo ""

    proot-distro login ubuntu || {
        error "Gagal login ke Ubuntu."
        return 1
    }
}

# -----------------------------------------------------------------------------
# Fungsi: Opsi 2 — Install OpenCode
# -----------------------------------------------------------------------------
install_opencode() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ 🤖 Install OpenCode ━━━${RESET}"
    echo ""

    # Deteksi environment dan beri warning jika di Termux base
    if is_termux && ! is_proot_ubuntu; then
        warning "Script berjalan di Termux base, bukan di dalam Ubuntu proot."
        echo ""
        echo "  OpenCode dirancang untuk environment Linux standar."
        echo "  Disarankan install Ubuntu terlebih dahulu (opsi 1)."
        echo ""
        read -rp "  Lanjutkan instalasi OpenCode di Termux base? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            info "Membatalkan instalasi OpenCode."
            return 0
        fi
        echo ""
    fi

    # Langkah 1: Cek dan install dependencies
    info "Memeriksa dependencies (curl, nodejs, npm)..."
    local missing_deps=()

    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    fi
    if ! command -v node &>/dev/null; then
        missing_deps+=("nodejs")
    fi
    if ! command -v npm &>/dev/null; then
        missing_deps+=("npm")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        warning "Dependencies belum lengkap: ${missing_deps[*]}"
        info "Menginstall dependencies via package manager..."
        echo ""

        if is_termux; then
            pkg update -y || {
                error "Gagal menjalankan 'pkg update'. Periksa koneksi internet."
                return 1
            }
            pkg install "${missing_deps[@]}" -y || {
                error "Gagal menginstall dependencies: ${missing_deps[*]}"
                error "Coba install manual: pkg install ${missing_deps[*]}"
                return 1
            }
        elif is_proot_ubuntu; then
            apt update || {
                error "Gagal menjalankan 'apt update'. Periksa koneksi internet."
                return 1
            }
            apt install -y "${missing_deps[@]}" || {
                error "Gagal menginstall dependencies: ${missing_deps[*]}"
                error "Coba install manual: apt install ${missing_deps[*]}"
                return 1
            }
        else
            error "Tidak dapat mendeteksi package manager untuk menginstall dependencies."
            return 1
        fi
        success "Dependencies berhasil diinstall."
    else
        info "Semua dependencies sudah tersedia."
    fi

    # Verifikasi Node.js version (minimal v16)
    if command -v node &>/dev/null; then
        local node_version
        node_version=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [[ -n "$node_version" && "$node_version" -lt 16 ]]; then
            error "Node.js versi $node_version terdeteksi. OpenCode membutuhkan Node.js v16+."
            error "Silakan update Node.js ke versi yang lebih baru."
            return 1
        fi
        info "Node.js versi $(node --version) terdeteksi."
    fi

    # Langkah 2: Install OpenCode (metode utama: curl script resmi)
    echo ""
    info "Menginstall OpenCode (metode: curl script resmi)..."
    echo -e "${YELLOW}Proses ini memerlukan koneksi internet.${RESET}"
    echo ""

    local install_success=false

    # Metode 1: curl script resmi
    if curl -fsSL https://opencode.ai/install -o /tmp/opencode-install.sh 2>/dev/null; then
        bash /tmp/opencode-install.sh && install_success=true || {
            warning "Instalasi via curl script gagal."
        }
        rm -f /tmp/opencode-install.sh
    else
        warning "Gagal mengunduh script instalasi OpenCode."
    fi

    # Metode 2: fallback via npm
    if ! $install_success; then
        echo ""
        warning "Mencoba fallback: instalasi via npm..."
        npm install -g opencode-ai && install_success=true || {
            error "Instalasi OpenCode via npm juga gagal."
        }
    fi

    if ! $install_success; then
        error "Semua metode instalasi OpenCode gagal."
        error "Saran troubleshooting:"
        echo "  1. Periksa koneksi internet Anda"
        echo "  2. Pastikan Node.js v16+ sudah terinstall (cek: node --version)"
        echo "  3. Coba install manual: npm install -g opencode-ai"
        return 1
    fi

    success "OpenCode berhasil diinstall!"
    echo ""

    # Langkah 3: Pastikan PATH mencakup direktori binary OpenCode
    info "Memastikan PATH mencakup direktori binary OpenCode..."
    if ! echo "$PATH" | grep -q "$OPENCODE_BIN_DIR"; then
        # Tambahkan ke ~/.bashrc jika belum ada
        if ! grep -q "$OPENCODE_BIN_DIR" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# OpenCode PATH" >> "$HOME/.bashrc"
            echo "export PATH=\"\$PATH:$OPENCODE_BIN_DIR\"" >> "$HOME/.bashrc"
            info "PATH ditambahkan ke ~/.bashrc"
        fi
        # Tambahkan untuk sesi saat ini
        export PATH="$PATH:$OPENCODE_BIN_DIR"
    fi

    # Langkah 4: Verifikasi instalasi
    echo ""
    info "Memverifikasi instalasi..."
    local version_output
    if version_output=$(opencode --version 2>/dev/null); then
        success "OpenCode terinstall dengan baik!"
        echo -e "  Versi: ${GREEN}$version_output${RESET}"
    else
        # Coba cek apakah binary ada
        if [[ -f "$OPENCODE_BIN_DIR/opencode" ]]; then
            success "Binary OpenCode ditemukan di $OPENCODE_BIN_DIR"
            warning "Perintah 'opencode --version' belum bisa dijalankan."
            echo "  Mungkin perlu restart shell atau jalankan: source ~/.bashrc"
        else
            error "Verifikasi gagal. OpenCode mungkin belum terinstall dengan benar."
            error "Cek PATH Anda atau coba: source ~/.bashrc && opencode --version"
            return 1
        fi
    fi

    echo ""
    echo -e "${BOLD}${GREEN}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  ${BOLD}✅ OpenCode Siap Digunakan!${RESET}                            ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}├──────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}                                                  ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  Jalankan dengan mengetik: ${CYAN}opencode${RESET}                ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}  Jika tidak ditemukan: ${CYAN}source ~/.bashrc${RESET}              ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}│${RESET}                                                  ${BOLD}${GREEN}│${RESET}"
    echo -e "${BOLD}${GREEN}└──────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    return 0
}

# -----------------------------------------------------------------------------
# Fungsi: Opsi 3 — Keluar
# -----------------------------------------------------------------------------
exit_tool() {
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}  Terima kasih telah menggunakan Tools Installer  ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}              See you! 👋                          ${CYAN}│${RESET}"
    echo -e "${CYAN}└──────────────────────────────────────────┘${RESET}"
    echo ""
    exit 0
}

# -----------------------------------------------------------------------------
# Handler: Sinyal Interrupt (Ctrl+C)
# -----------------------------------------------------------------------------
cleanup() {
    echo ""
    echo ""
    warning "Proses diinterupsi oleh user."
    echo -e "  ${CYAN}Keluar dengan aman...${RESET}"
    echo ""
    exit 130
}

trap cleanup SIGINT SIGTERM

# -----------------------------------------------------------------------------
# Main: Loop Menu Utama
# -----------------------------------------------------------------------------
main() {
    while true; do
        show_menu
        read -rp "  Pilih opsi [1/2/3]: " choice
        echo ""

        case "$choice" in
            1)
                install_proot_ubuntu
                ;;
            2)
                install_opencode
                ;;
            3)
                exit_tool
                ;;
            *)
                echo -e "  ${RED}⚠ Pilihan tidak valid.${RESET} Masukkan angka ${GREEN}1${RESET}, ${GREEN}2${RESET}, atau ${GREEN}3${RESET}."
                echo ""
                echo -e "  ${DIM}Tekan Enter untuk melanjutkan...${RESET}"
                read -r
                continue
                ;;
        esac

        echo ""
        echo -e "  ${DIM}Tekan Enter untuk kembali ke menu...${RESET}"
        read -r
    done
}

# Jalankan main
main
