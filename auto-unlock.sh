#!/bin/bash
set -e

# Add argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--partition)
            ENCRYPTED_PARTITION="$2"
            shift 2
            ;;
        -t|--temp-pass)
            TEMP_PASS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-p|--partition PARTITION] [-t|--temp-pass PASSWORD]"
            echo "Options:"
            echo "  -p, --partition    Specify encrypted partition (default: /dev/vda2)"
            echo "  -t, --temp-pass    Specify temporary password (default: ARCH_INSTALL_TEMP_PASS)"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Set default values if not provided
ENCRYPTED_PARTITION=${ENCRYPTED_PARTITION:-"/dev/vda2"}
TEMP_PASS=${TEMP_PASS:-"arch"}

pacman -S --needed tpm2-tools

# Check if secure boot is enabled
if ! sbctl status --json | grep -q '"secure_boot": true'; then
    echo "Error: UEFI Secure Boot is not enabled. Please enable Secure Boot first."
    exit 1
fi

# Enroll the recovery key
PASSWORD="${TEMP_PASS}" systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key > /root/recovery-key.txt
chown root:root /root/recovery-key.txt
chmod 600 /root/recovery-key.txt

# Enroll the TPM2 PCRs
PASSWORD="${TEMP_PASS}" systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/gpt-auto-root-luks

echo "Recovery key saved to /root/recovery-key.txt"
echo "TPM2 PCRs enrolled successfully."

# Remove the temporary password
echo -n "${TEMP_PASS}" | cryptsetup luksRemoveKey "${ENCRYPTED_PARTITION}" -

echo "The system will now reboot. It should automatically unlock the root partition."

sleep 5
reboot
