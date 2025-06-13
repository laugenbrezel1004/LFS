#!/bin/sh
set -e  # Exit on error
set -x  # Enable debug output

# Check if running as root
__check_if_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
  fi
}
__check_if_root

# Environment setup
set +h
umask 022
LFS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
[ -d "$LFS" ] || { echo "Error: LFS directory not found at $LFS"; exit 1; }
alias ll='ls -lahF'
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
[ ! -L /bin ] && PATH=/bin:$PATH
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS
echo $LFS

# Define variables
export IMAGE_FILE="$LFS/lfs.img"
export SIZE_MB=20480  # 20 GB
export FAT_MOUNT="$LFS/fat"
export EXT4_MOUNT="$LFS/ext4"

# Cleanup function
__cleanup() {
  echo "Unmounting and cleaning up..."
  mountpoint -q "$EXT4_MOUNT" 2>/dev/null && umount "$EXT4_MOUNT"
  mountpoint -q "$FAT_MOUNT" 2>/dev/null && umount "$FAT_MOUNT"
  losetup -a | grep -q "$IMAGE_FILE" 2>/dev/null && losetup -d "$(losetup -j "$IMAGE_FILE" | cut -d: -f1)"
  echo "Cleanup completed."
}
trap 'echo "Error occurred. Cleaning up..."; __cleanup; exit 1' ERR

# 1. Create image file if it doesn't exist
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Creating image file ($SIZE_MB MB)..."
  dd if=/dev/zero of="$IMAGE_FILE" bs=1M count="$SIZE_MB" status=progress
  sync

  # 2. Set up loop device
  echo "Setting up loop device..."
  LOOP_DEV=$(losetup -fP --show "$IMAGE_FILE")
  echo "Loop device: $LOOP_DEV"

  # 3. Create partition table (FAT32 for UEFI, ext4 for root)
  echo "Creating partition table..."
  parted -s "$LOOP_DEV" mklabel gpt
  parted -s "$LOOP_DEV" mkpart primary fat32 1MiB 513MiB
  parted -s "$LOOP_DEV" set 1 esp on
  parted -s "$LOOP_DEV" mkpart primary ext4 513MiB 100%
  sync

  # 4. Format partitions
  echo "Formatting partitions..."
  mkfs.vfat -F 32 "${LOOP_DEV}p1"
  mkfs.ext4 "${LOOP_DEV}p2"
  sync
else
  # 2. Set up loop device for existing image
  echo "Setting up loop device..."
  LOOP_DEV=$(losetup -fP --show "$IMAGE_FILE")
  echo "Loop device: $LOOP_DEV"
fi

# 5. Create mountpoints if they don't exist
echo "Creating mountpoints..."
mkdir -p "$FAT_MOUNT" "$EXT4_MOUNT"

# 6. Mount partitions if not already mounted
echo "Mounting partitions..."
mountpoint -q "$FAT_MOUNT" || mount -t vfat "${LOOP_DEV}p1" "$FAT_MOUNT"
mountpoint -q "$EXT4_MOUNT" || mount -t ext4 "${LOOP_DEV}p2" "$EXT4_MOUNT"

# 7. Check contents
echo "Contents of mounted partitions:"
ls -lah "$FAT_MOUNT"
ls -lah "$EXT4_MOUNT"

# 8. Set up LFS directories if they don't exist
#mkdir -pv "${LFS}"/{etc,var,sources} "${LFS}"/usr/{bin,lib,sbin}
#for i in bin lib sbin; do
 # [ -L "${LFS}/$i" ] || ln -sfv "usr/$i" "${LFS}/$i"
#done
#case $(uname -m) in
#  x86_64) mkdir -pv "${LFS}/lib64" ;;
#esac
#mkdir -pv "${LFS}/tools"

# 9. Create lfs user and set permissions if not already done
if ! getent group lfs >/dev/null 2>&1; then
  groupadd lfs
fi
if ! id lfs >/dev/null 2>&1; then
  useradd -s /bin/bash -g lfs -m -k /dev/null lfs
  echo "lfs:lfs" | chpasswd
fi
chown -v lfs "${LFS}"/{usr{,/*},var,etc,tools,sources}
#case $(uname -m) in
 # x86_64) chown -v lfs "${LFS}/lib64" ;;
#esac

# 10. Download source packages if sources directory is empty
if [ -z "$(ls -A "$EXT4_MOUNT/sources" 2>/dev/null)" ]; then
  echo "Sources directory is empty. Downloading source packages..."
  mkdir -p "$EXT4_MOUNT/sources"
  wget --input-file=- --continue --directory-prefix="$EXT4_MOUNT/sources" <<HERE
https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz
https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz
https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz
https://ftp.gnu.org/gnu/automake/automake-1.17.tar.xz
https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz
https://github.com/gavinhoward/bc/releases/download/7.0.3/bc-7.0.3.tar.xz
https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.xz
https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz
https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz
https://ftp.gnu.org/gnu/coreutils/coreutils-9.6.tar.xz
https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz
https://ftp.gnu.org/gnu/diffutils/diffutils-3.11.tar.xz
https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.2/e2fsprogs-1.47.2.tar.gz
https://sourceware.org/ftp/elfutils/0.192/elfutils-0.192.tar.bz2
https://prdownloads.sourceforge.net/expat/expat-2.6.4.tar.xz
https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz
https://astron.com/pub/file/file-5.46.tar.gz
https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz
https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
https://pypi.org/packages/source/f/flit-core/flit_core-3.11.0.tar.gz
https://ftp.gnu.org/gnu/gawk/gawk-5.3.1.tar.xz
https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
https://ftp.gnu.org/gnu/gdbm/gdbm-1.24.tar.gz
https://ftp.gnu.org/gnu/gettext/gettext-0.24.tar.xz
https://ftp.gnu.org/gnu/glibc/glibc-2.41.tar.xz
https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz
https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz
https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz
https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz
https://github.com/Mic92/iana-etc/releases/download/20250123/iana-etc-20250123.tar.gz
https://ftp.gnu.org/gnu/inetutils/inetutils-2.6.tar.xz
https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz
https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.13.0.tar.xz
https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.5.tar.gz
https://www.kernel.org/pub/linux/utils/kbd/kbd-2.7.1.tar.xz
https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.tar.xz
https://www.greenwoodsoftware.com/less/less-668.tar.gz
https://www.linuxfromscratch.org/lfs/downloads/12.3/lfs-bootscripts-20240825.tar.xz
https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.73.tar.xz
https://github.com/libffi/libffi/releases/download/v3.4.7/libffi-3.4.7.tar.gz
https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz
https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz
https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz
https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.13.4.tar.xz
https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz
https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
https://download.savannah.gnu.org/releases/man-db/man-db-2.13.0.tar.xz
https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.12.tar.xz
https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.2.tar.gz
https://github.com/mesonbuild/meson/releases/download/1.7.0/meson-1.7.0.tar.gz
https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz
https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz
https://github.com/ninja-build/ninja/archive/v1.12.1/ninja-1.12.1.tar.gz
https://github.com/openssl/openssl/releases/download/openssl-3.4.1/openssl-3.4.1.tar.gz
https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
https://www.cpan.org/src/5.0/perl-5.40.1.tar.xz
https://distfiles.ariadne.space/pkgconf/pkgconf-2.3.0.tar.xz
https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz
https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz
https://www.python.org/ftp/python/3.13.2/Python-3.13.2.tar.xz
https://www.python.org/ftp/python/doc/3.13.2/python-3.13.2-docs-html.tar.bz2
https://ftp.gnu.org/gnu/readline/readline-8.2.13.tar.gz
https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz
https://pypi.org/packages/source/s/setuptools/setuptools-75.8.1.tar.gz
https://github.com/shadow-maint/shadow/releases/download/4.17.3/shadow-4.17.3.tar.xz
https://github.com/troglobit/sysklogd/releases/download/v2.7.0/sysklogd-2.7.0.tar.gz
https://github.com/systemd/systemd/archive/v257.3/systemd-257.3.tar.gz
https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-257.3.tar.xz
https://github.com/slicer69/sysvinit/releases/download/3.14/sysvinit-3.14.tar.xz
https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz
https://downloads.sourceforge.net/tcl/tcl8.6.16-src.tar.gz
https://downloads.sourceforge.net/tcl/tcl8.6.16-html.tar.gz
https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz
https://www.iana.org/time-zones/repository/releases/tzdata2025a.tar.gz
https://anduin.lfsfromscratch.org/LFS/udev-lfs-20230818.tar.xz
https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.4.tar.xz
https://github.com/vim/vim/archive/v9.1.1166/vim-9.1.1166.tar.gz
https://pypi.org/packages/source/w/wheel/wheel-0.45.1.tar.gz
https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz
https://github.com/tukaani-project/xz/releases/download/v5.6.4/xz-5.6.4.tar.xz
https://zlib.net/fossils/zlib-1.3.1.tar.gz
https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
https://www.linuxfromscratch.org/patches/lfs/12.3/bzip2-1.0.8-install_docs-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.3/coreutils-9.6-i18n-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.3/expect-5.45.4-gcc14-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.3/glibc-2.41-fhs-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.3/kbd-2.7.1-backspace-1.patch
https://www.linuxfromscratch.org/patches/lfs/12.3/sysvinit-3.14-consolidated-1.patch
HERE
else
  echo "Sources directory ($EXT4_MOUNT/sources) is not empty. Skipping download."
fi

echo "LFS environment setup complete. Ready to work."