
IMAGE_FILE="lfs.img"
MOUNT_POINT="/tmp/lfs"
SIZE_MB=20480  # Size of the image file in MB (20 GB)
EXT4_MOUNT="./lfs/ext4"
FAT_MOUNT="./lfs/fat"

__check_if_root() {
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root!"
     exit 1
  fi
}

# Error handling
trap 'echo "Error occurred. Cleaning up..."; cleanup; exit 1' ERR

# Function to clean up
__cleanup() {
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
    # Remove mountpoint directories
    rm -rf "$EXT4_MOUNT" "$FAT_MOUNT"
    echo "Cleanup completed."
}