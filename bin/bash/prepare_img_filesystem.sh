#!/bin/sh


set -e # show error
set -x # extented debug info

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)."
   exit 1
fi

# Get the directory where the script is located
cd $(dirname "${BASH_SOURCE[0]}")
# to get to the root
cd .. && cd .. && pwd

# Variables
IMAGE_FILE="lfs.img"
MOUNT_POINT="/tmp/lfs"
SIZE_MB=20480  # Size of the image file in MB (20 GB)
EXT4_MOUNT="/tmp/lfs/ext4"
FAT_MOUNT="/tmp/lfs/fat"

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

# Error handling
trap 'echo "Error occurred. Cleaning up..."; cleanup; exit 1' ERR

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
mkfs.vfat -t fat32 "${LOOP_DEV}p2"
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
ls -l "$EXT4_MOUNT"
ls -l "$FAT_MOUNT"

# 8. Short pause to demonstrate mounts
echo "Partitions are mounted. Waiting 5 seconds..."
sleep 5

# 9. Clean up
cleanup

echo "Script completed successfully."
