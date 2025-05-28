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

mkdir -pv "${EXT4_MOUNT}/{etc,var}" "${EXT4_MOUNT}/usr/{bin,lib,sbin}"

for i in bin lib sbin; do
  ln -sv "usr/$i" "${EXT4_MOUNT}"/$i
done

case $(uname -m) in
  x86_64) mkdir -pv "${EXT4_MOUNT}"/lib64 ;;
esac

mkdir -pv "${EXT4_MOUNT}"/tools