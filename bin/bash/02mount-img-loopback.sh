#!/bin/sh
set -e # show error
set -x # extented debug info

# to get to the root
cd "$(dirname "${BASH_SOURCE[0]}")"
cd .. && cd .. && pwd

env
# source some importent functions
. bin/bash/functions.sh

# check if root started this
__check_if_root



# 1. Set up loop device
echo "Setting up loop device..."
LOOP_DEV=$(losetup -fP --show "$IMAGE_FILE")
echo "Loop device: $LOOP_DEV"


# 2. Mount partitions
echo "Mounting partitions..."
mount "${LOOP_DEV}p1" "${LFS}/fat"
mount "${LOOP_DEV}p2" "${LFS}/ext4"


# 3. Check contents
echo "Contents of mounted partitions:"
ls -l "${LFS}/etx4"
ls -l "${LFS}/fat"

