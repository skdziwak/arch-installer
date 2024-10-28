# Arch Linux Automated Installation Script

## ⚠️ Critical Security & Risk Warnings

### Before You Begin
- These scripts will **FORMAT YOUR DISK** and could lead to **DATA LOSS**
- **BACKUP ALL DATA** before proceeding
- Test in a virtual machine first if possible
- Review all script contents before execution
- The authors are not responsible for any damage to your system

### Security Notice: Temporary Password
During installation, a temporary LUKS encryption password (`arch`) is set. **This is a security risk!** You MUST either:
1. Run `auto-unlock.sh` to configure TPM2-based unlocking (recommended)
2. OR manually change the password using `cryptsetup luksChangeKey`

**Failure to remove the temporary password leaves your system vulnerable!**

## System Requirements
- UEFI-capable system
- TPM 2.0 module
- Secure Boot capability
- Internet connection
- Arch Linux installation media

## Installation Steps

1. Boot from Arch Linux installation media

2. Install base system:
```bash
bash <(curl -L https://raw.githubusercontent.com/skdziwak/arch-installer/main/install.sh) --disk=/dev/sda --username=myuser
```

3. Configure Secure Boot:
```bash
sudo su
bash <(curl -L https://raw.githubusercontent.com/skdziwak/arch-installer/main/secureboot.sh)
```
*Note: Ensure your system is in Secure Boot Setup Mode first*

4. Set up TPM2 auto-unlock (removes temporary password):
```bash
sudo su
bash <(curl -L https://raw.githubusercontent.com/skdziwak/arch-installer/main/auto-unlock.sh) --partition=/dev/sda2 --temp-pass=mytemporarypassword
```

5. Save the recovery key from `/root/recovery-key.txt` in a secure location

6. Reboot

### Alternative: Manual Password Change
If not using TPM2 auto-unlock, change the temporary password immediately:
```bash
cryptsetup luksChangeKey /dev/sda2  # Replace with your encrypted partition
```

## Help & Options
All scripts accept `-h` or `--help` for detailed options:
- `install.sh`: Disk, username, hostname, timezone, keymap options
- `auto-unlock.sh`: Partition and temporary password options
- `secureboot.sh`: No additional options

## Support & Security
- This is community software with no official support
- Use GitHub issue tracker for bug reports
- Regular system updates and security maintenance are essential
- No system is completely secure

## Legal Information

### License
MIT License

Copyright (c) 2024 Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

### No Warranty Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.