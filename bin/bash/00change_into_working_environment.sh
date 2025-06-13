set +h
umask 022
LFS="$(cd ../../lfs/ && pwd)"
alias ll="ls -lahF"
LC_ALL=POSIX
MAKEFLAGS=-j24
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS