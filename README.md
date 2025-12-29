# MAAS Proxmox VE Image Builder

Build Proxmox VE 9.1 images for automated MAAS deployment on bare metal.

Based on Debian 13 (Trixie) with cloud-init integration for seamless MAAS provisioning. All Proxmox services start automatically after deployment.

## Prerequisites

### Build Machine

- Ubuntu 22.04 or later
- Packer installed
- KVM/QEMU support
- Sufficient disk space (~5GB for build artifacts)
- User must be member of the `kvm` group

### MAAS Server

- MAAS 3.x or later
- Network connectivity to build machine
- SSH access for file transfers

## Quick Start

### 1. Install Dependencies

```bash
sudo apt update
sudo apt install -y packer qemu-system-x86 qemu-utils ovmf cloud-image-utils

# Add user to kvm group
sudo usermod -a -G kvm $USER
newgrp kvm
```

### 2. Build Proxmox VE Image

```bash
cd debian

# Install packer ansible plugin
packer plugins install github.com/hashicorp/ansible

# Build image
sg kvm -c "packer build -var 'debian_series=trixie' -var 'debian_version=13' -var 'filename=proxmox-ve-91-cloudimg.tar.gz' ."
```

**Output**: `proxmox-ve-91-cloudimg.tar.gz` (~2.4GB)
**Build time**: ~30-40 minutes

**What's included**:
- Proxmox VE 9.1 (pve-no-subscription)
- Proxmox kernel
- Cloud-init with automatic /etc/hosts configuration
- All services start automatically after deployment

### 3. Upload to MAAS

```bash
# Copy to MAAS server
scp proxmox-ve-91-cloudimg.tar.gz ubuntu@<MAAS_IP>:/home/ubuntu/

# Upload to MAAS
ssh ubuntu@<MAAS_IP>
maas admin boot-resources create \
  name='custom/proxmox-ve-9.1' \
  title='Proxmox VE 9.1 (Debian 13)' \
  architecture='amd64/generic' \
  filetype='tgz' \
  content@=/home/ubuntu/proxmox-ve-91-cloudimg.tar.gz
```

Replace `admin` with your MAAS profile name.

### 4. Deploy

1. MAAS web UI → Select machine → Deploy
2. Choose "Proxmox VE 9.1 (Debian 13)"
3. Web UI available at `https://<machine-ip>:8006` (login: root@pam)

**Requirements**: UEFI boot enabled, SSH key configured in MAAS

## Building Vanilla Debian Images

For vanilla Debian 13 without Proxmox:

```bash
cd debian
sg kvm -c "make debian SERIES=trixie"
```

Output: `debian-13-cloudimg.tar.gz` (~429MB) | Build time: ~10-15 minutes

Upload same as above but use `custom/debian-13` as the name.

## Build Options

### Default Build (Debian 13 with default kernel)

```bash
sg kvm -c "make debian SERIES=trixie"
```

### Build with Custom Kernel

```bash
sg kvm -c "make debian SERIES=trixie KERNEL=6.17.4-1-pve"
```

### Build for ARM64

```bash
sg kvm -c "make debian SERIES=trixie ARCH=arm64"
```

### BIOS Boot (Separate Build Required)

```bash
sg kvm -c "make debian SERIES=trixie BOOT=bios"
```

Note: UEFI and BIOS images must be built separately for Debian 12+.

## Project Structure

```
MAAS-Proxmox/
├── README.md                           # This file
└── debian/
    ├── debian-cloudimg.pkr.hcl        # Main Packer configuration
    ├── debian-cloudimg.variables.pkr.hcl
    ├── variables.pkr.hcl
    ├── meta-data                       # Cloud-init metadata
    ├── user-data-cloudimg             # Cloud-init user data
    ├── ansible/
    │   └── proxmox.yml                # Install Proxmox VE (proxmox branch)
    ├── scripts/
    │   ├── essential-packages.sh      # Install base packages
    │   ├── setup-boot.sh              # Configure bootloader
    │   ├── networking.sh              # Network configuration
    │   ├── install-custom-kernel.sh   # Optional kernel install
    │   ├── setup-curtin.sh            # MAAS integration
    │   └── cleanup.sh                 # Image cleanup
    └── preseed/
        └── curtin_userdata_custom_amd64  # MAAS preseed for Debian
```

## Troubleshooting

### Web UI not accessible after deployment

Check service status:
```bash
ssh debian@<machine-ip>
sudo systemctl status pve-cluster pveproxy pvedaemon
```

All should show `active (running)`. If not, check `/etc/hosts` contains the actual IP (not 127.0.1.1).

### Cannot login via SSH

Default user is `debian`:
```bash
ssh debian@<machine-ip>
```

### Build fails with "permission denied" on /dev/kvm

Add user to kvm group:
```bash
sudo usermod -a -G kvm $USER
newgrp kvm
```

### Image boots to EFI shell

Enable UEFI boot in BIOS/IPMI settings. Legacy BIOS is not supported for Debian 13 images.

## References

- [Canonical packer-maas](https://github.com/canonical/packer-maas) - Original upstream repository
- [MAAS Documentation](https://maas.io/docs)
- [Debian Cloud Images](https://cloud.debian.org/images/cloud/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)

## License

This project uses configuration from Canonical's packer-maas repository (AGPL-3.0).

## Contributing

Contributions welcome! Please submit pull requests or open issues for bugs and feature requests.
