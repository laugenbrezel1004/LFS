#!/bin/sh

set -e # show error
set -x # extented debug info

# Get the directory where the script is located
cd $(dirname "${BASH_SOURCE[0]}")
# to get to the root
cd .. && cd .. && pwd

# create loopback
sudo mkdir /tmp/lfs
sudo mount -o loop lfs.img /tmp/lfs
sudo ln -s /tmp/lfs link_lfs.img
