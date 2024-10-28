#!/bin/bash
set -e

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --disk=*)
            DISK="${1#*=}"
            shift
            ;;
        --username=*)
            USERNAME="${1#*=}"
            shift
            ;;
        --hostname=*)
            HOSTNAME="${1#*=}"
            shift
            ;;
        --timezone=*)
            TIMEZONE="${1#*=}"
            shift
            ;;
        --keymap=*)
            KEYMAP="${1#*=}"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --disk=DEVICE     Target disk (default: /dev/vda)"
            echo "  --username=NAME   Username to create (default: archuser)"
            echo "  --hostname=NAME   System hostname (default: archlinux)"
            echo "  --timezone=ZONE   Timezone (default: Europe/London)"
            echo "  --keymap=LAYOUT   Keyboard layout (default: uk)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Configuration variables with defaults
: "${DISK:=/dev/vda}"
: "${USERNAME:=archuser}"
: "${HOSTNAME:=archlinux}"
: "${TIMEZONE:=Europe/Warsaw}"
: "${KEYMAP:=pl}"

# Get user password
read -s -p "Enter new password for user ${USERNAME}: " USER_PASSWORD

# Validate required parameters
if [[ ! -b "${DISK}" ]] && [[ ! "${DISK}" =~ ^/dev/nvme[0-9]+n[0-9]+$ ]]; then
    echo "Error: Disk ${DISK} does not exist or is not a block device"
    exit 1
fi

# Disk preparation
sgdisk -Z "${DISK}"
if [[ "${DISK}" =~ ^/dev/nvme[0-9]+n[0-9]+$ ]]; then
    # NVMe drives use 'p' suffix for partition numbers
    sgdisk -n1:0:+512M -t1:ef00 -c1:EFI -N2 -t2:8304 -c2:cryptroot "${DISK}"
    DISK1="${DISK}p1"
    DISK2="${DISK}p2"
else
    # Traditional drives use number suffix
    sgdisk -n1:0:+512M -t1:ef00 -c1:EFI -N2 -t2:8304 -c2:cryptroot "${DISK}"
    DISK1="${DISK}1"
    DISK2="${DISK}2"
fi
partprobe -s "${DISK}"

# Setup encryption with a temporary password
TEMP_PASS="arch"
echo -n "${TEMP_PASS}" | cryptsetup luksFormat --type luks2 "${DISK2}" --batch-mode -
echo -n "${TEMP_PASS}" | cryptsetup open "${DISK2}" cryptroot -

# Create filesystems
mkfs.vfat -F32 -n EFI "${DISK1}"
mkfs.btrfs -f -L cryptroot /dev/mapper/cryptroot

# Mount and create subvolumes
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/efi
mount "${DISK1}" /mnt/efi

# Create btrfs subvolumes
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/srv
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/var/log
btrfs subvolume create /mnt/var/cache
btrfs subvolume create /mnt/var/tmp

# Update mirrors and install base system
reflector --country GB --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode vim nano cryptsetup \
    btrfs-progs dosfstools util-linux git unzip sbctl kitty networkmanager sudo sddm plasma firefox dolphin

# Configure locale and system settings
sed -i -e '/^#en_GB.UTF-8/s/^#//' /mnt/etc/locale.gen
echo "KEYMAP=${KEYMAP}" > /mnt/etc/vconsole.conf
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /mnt/etc/localtime
echo "${HOSTNAME}" > /mnt/etc/hostname
arch-chroot /mnt locale-gen

# Create user
arch-chroot /mnt useradd -G wheel -m "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | arch-chroot /mnt chpasswd
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers

# Setup Unified Kernel Image
echo "quiet rw" > /mnt/etc/kernel/cmdline
mkdir -p /mnt/efi/EFI/Linux

# Configure mkinitcpio
cat > /mnt/etc/mkinitcpio.conf << EOF
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)
EOF

# Configure mkinitcpio preset
cat > /mnt/etc/mkinitcpio.d/linux.preset << EOF
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default' 'fallback')
default_uki="/efi/EFI/Linux/arch-linux.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
fallback_uki="/efi/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
EOF

# Generate UKIs
arch-chroot /mnt mkinitcpio -P

# Enable services
systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager sddm
systemctl --root /mnt mask systemd-networkd
arch-chroot /mnt bootctl install --esp-path=/efi

echo "Base installation complete. Please reboot and follow the post-installation steps for Secure Boot and TPM2 configuration."

reboot
