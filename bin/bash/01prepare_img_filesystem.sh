#!/bin/sh
######
# UEFI and ext4 partitions
#

set -e # show error
set -x # extented debug info

# to get to the root
cd "$(dirname "${BASH_SOURCE[0]}")"
cd .. && cd .. && pwd

# source some importent functions
. bin/bash/functions.sh

# Check if the script is run as root
__check_if_root


# Variables


# Function to clean up
cleanup() {
    echo "Unmounting and cleaning up..."
    # Unmount filesystems
    if mountpoint -q "$EXT4_MOUNT"; then
        umount "$EXT4_MOUNT"
    fi
    if mountpoint -q "$FAT_MOUNT"; then
        umount "$FAT_MOUNT"
    fi
    # Detach loop device
    if losetup -a | grep -q "$IMAGE_FILE"; then
        losetup -d "$(losetup -j "$IMAGE_FILE" | cut -d: -f1)"
    fi
    # Remove mountpoints and image file
    rm -rf "$MOUNT_POINT" "$IMAGE_FILE"
    echo "Cleanup completed."
}


# 1. Create image file
if [ ! -f "${IMAGE_FILE}" ]; then
  echo "Creating image file ($SIZE_MB MB)..."
  dd if=/dev/zero of="$IMAGE_FILE" bs=1M count="$SIZE_MB status=progess" 
  sync
fi

# 2. Set up loop device
echo "Setting up loop device..."
LOOP_DEV=$(losetup -fP --show "$IMAGE_FILE")
echo "Loop device: $LOOP_DEV"

# 3. Create partition table (two partitions for ext4 and FAT32)
echo "Creating partition table..."
parted -s "$LOOP_DEV" mklabel gpt
parted -s "$LOOP_DEV" mkpart ESP fat32 1MiB 513MiB
parted -s "$LOOP_DEV" set 1 esp on
parted -s "$LOOP_DEV" mkpart primary ext4 513MiB 100%
sync

# 4. Format partitions
echo "Formatting partitions..."
mkfs.ext4 "${LOOP_DEV}p1"
mkfs.fat -F 32 "${LOOP_DEV}p2"
sync

# 5. Create mountpoints
echo "Creating mountpoints..."
mkdir -p "$MOUNT_POINT" "$EXT4_MOUNT" "$FAT_MOUNT"

# 6. Mount partitions
echo "Mounting partitions..."
mount "${LOOP_DEV}p1" "$EXT4_MOUNT"
mount "${LOOP_DEV}p2" "$FAT_MOUNT"

# 7. Check contents
echo "Contents of mounted partitions:"
ls -lah "$EXT4_MOUNT"
ls -lah "$FAT_MOUNT"

# 8. Short pause to demonstrate mounts
echo "Partitions are mounted. Waiting 5 seconds..."
sleep 5

# 9. Clean up
cleanup

echo "Script completed successfully."
