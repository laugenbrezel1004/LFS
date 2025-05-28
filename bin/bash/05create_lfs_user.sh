#!/bin/sh
set -e # show error
set -x # extented debug info

# to get to the root
cd "$(dirname "${BASH_SOURCE[0]}")"
cd .. && cd .. && pwd

# source some importent functions
. bin/bash/functions.sh

# check if root started this
__check_if_root

groupadd lfs
useradd -d /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
#Grant lfs full access to all the directories under $LFS by making lfs the owner:
chown -v lfs "${EXT4_MOUNT}/{usr{,/*},var,etc,tools}"
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

mkdir -pv "${EXT4_MOUNT}/{etc,var}" "${EXT4_MOUNT}/usr/{bin,lib,sbin}"
