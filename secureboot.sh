#!/bin/bash
set -e

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0"
            exit 0
            ;;
    esac
done

# Check if setup mode is enabled
if ! sbctl status --json | grep -q '"setup_mode": true'; then
    echo "Error: UEFI Secure Boot is not in Setup Mode. Please disable Secure Boot or enter Setup Mode first."
    exit 1
fi

sbctl create-keys
sbctl enroll-keys -m

sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
sbctl sign -s /efi/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /efi/EFI/Linux/arch-linux.efi
sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

pacman -S linux

echo "Secure Boot keys enrolled and signed successfully."

reboot