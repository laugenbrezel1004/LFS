#!/bin/sh
set -e # show error
set -x # extented debug info

# to get to the root
cd $(dirname "${BASH_SOURCE[0]}")
cd .. && cd .. && pwd

# source some importent functions
source bin/bash/functions.sh

# check if root started this
__check_if_root



# 1. Set up loop device
echo "Setting up loop device..."
LOOP_DEV=$(losetup -fP --show "$IMAGE_FILE")
echo "Loop device: $LOOP_DEV"

# 2. Create mountpoints in project directory
echo "Creating mountpoints in $PROJECT_DIR..."
mkdir -p "$EXT4_MOUNT" "$FAT_MOUNT"

# 3. Mount partitions
echo "Mounting partitions..."
mount "${LOOP_DEV}p1" "$EXT4_MOUNT"
mount "${LOOP_DEV}p2" "$FAT_MOUNT"

# 5. Change permissions
#echo "Change permissions"
#chown -R "1000:1000" "./lfs"

# 6. Check contents
echo "Contents of mounted partitions:"
ls -l "$EXT4_MOUNT"
ls -l "$FAT_MOUNT"

