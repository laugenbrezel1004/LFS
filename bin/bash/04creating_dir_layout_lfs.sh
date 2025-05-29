#!/bin/sh
set -e # show error
set -x # extented debug info

# to get to the root
cd "$(dirname "${BASH_SOURCE[0]}")"
cd .. && cd .. && pwd

# source some importent functions
. bin/bash/functions.sh

# check if root started this
#__check_if_root

mkdir -pv "${LFS}"/{etc,var} "${LFS}"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv "usr/$i" "${LFS}"/$i
done

case $(uname -m) in
  x86_64) mkdir -pv "${LFS}"/lib64 ;;
esac

mkdir -pv "${LFS}"/tools