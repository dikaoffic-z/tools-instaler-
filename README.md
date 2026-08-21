# Tools Installer — proot-distro Ubuntu + OpenCode (Termux)

Script Bash interaktif untuk menginstall **proot-distro Ubuntu** dan **OpenCode** di Termux Android, dari nol hingga siap pakai.

## Fitur

- **3 menu interaktif** — install Ubuntu, install OpenCode, atau keluar
- **Auto-detect environment** — mendeteksi apakah berjalan di Termux base atau di dalam Ubuntu proot
- **Idempotent** — aman dijalankan berulang kali tanpa merusak instalasi yang sudah ada
- **Error handling lengkap** — setiap langkah diverifikasi, kegagalan ditangani dengan pesan yang jelas
- **CLI berwarna** — output menggunakan warna ANSI untuk kemudahan membaca

## Prasyarat

- Android dengan **Termux** terinstall (arsitektur arm64/armhf)
- Koneksi internet aktif
- Tidak memerlukan root access

## Cara Menggunakan

### 1. Clone Repository ke Termux

```bash
# Di Termux
pkg update && pkg install git -y
git clone https://github.com/username/tools-instaler-.git ~/tools-instaler
cd ~/tools-instaler
```

### 2. Jalankan script

```bash
bash tools.sh
```

### 3. Ikuti menu

```
┌──────────────────────────────────────────────────────────┐
│   🛠  Tools Installer: Ubuntu + OpenCode                  │
│      proot-distro Termux Android                        │
└──────────────────────────────────────────────────────────┘

  Environment: Termux Base

  ▶  1) Install proot-distro Ubuntu
  ▶  2) Install OpenCode
  ▶  3) Keluar

  ────────────────────────────────────────────────────

  Pilih opsi [1/2/3]:
```

## Alur Penggunaan

### Langkah 1 — Install Ubuntu (Opsi 1)

Dijalankan dari **Termux base**:

1. Script akan memeriksa dan menginstall `proot-distro` jika belum ada
2. Menginstall Ubuntu via `proot-distro install ubuntu`
3. Menyalin script ke dalam filesystem Ubuntu
4. Otomatis login ke shell Ubuntu

### Langkah 2 — Install OpenCode (Opsi 2)

Dijalankan dari **dalam Ubuntu proot**:

1. Setelah login ke Ubuntu (dari Langkah 1), jalankan ulang script:
   ```bash
   bash tools.sh
   ```
2. Pilih opsi **2**
3. Script akan menginstall dependencies (curl, nodejs, npm) jika belum ada
4. Menginstall OpenCode via script resmi atau npm fallback
5. Menambahkan PATH ke `~/.bashrc`
6. Memverifikasi instalasi dengan `opencode --version`

### Langkah 3 — Gunakan OpenCode

```bash
source ~/.bashrc
opencode
```

## Struktur Script

| Function | Deskripsi |
|---|---|
| `show_menu()` | Menampilkan menu utama dengan 3 opsi |
| `install_proot_ubuntu()` | Install proot-distro Ubuntu + auto-login |
| `install_opencode()` | Install OpenCode dengan dependency check |
| `exit_tool()` | Keluar dari script dengan pesan penutup |
| `cleanup()` | Handler untuk Ctrl+C / interrupt |
| `is_termux()` | Deteksi apakah berjalan di Termux base |
| `is_proot_ubuntu()` | Deteksi apakah berjalan di dalam Ubuntu proot |

## Penanganan Error

Script ini menangani berbagai skenario error:

- **Koneksi internet tidak ada** — pesan jelas, kembali ke menu
- **proot-distro gagal install** — saran untuk install manual
- **Ubuntu sudah terinstall** — tawaran login atau install ulang
- **Opsi 2 dipilih sebelum Ubuntu** — warning + minta konfirmasi
- **Input menu tidak valid** — pesan error ringan, menu tampil ulang
- **Ctrl+C** — keluar dengan pesan sopan, tidak crash

## Catatan

- Script ini hanya mendukung **Ubuntu** sebagai distro proot
- Murni **CLI**, tidak ada GUI
- Belum ada fitur uninstall/reset (future improvement)

## Lisensi

Free to use and modify.
