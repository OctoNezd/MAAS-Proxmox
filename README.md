# MAAS Proxmox Images

Build custom Debian images for MAAS deployment, with the goal of deploying Proxmox VE on bare metal.

## Current Status

This repository contains configurations to build both vanilla Debian 13 (Trixie) and Proxmox VE 9.1 images for MAAS deployment.

## Branches

- **main**: Vanilla Debian 13 (Trixie) - UEFI boot only
- **proxmox**: Debian 13 with Proxmox VE 9.1 pre-installed

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
# Install Packer
sudo apt update
sudo apt install -y packer qemu-system-x86 qemu-utils ovmf cloud-image-utils

# Add your user to the kvm group
sudo usermod -a -G kvm $USER
newgrp kvm
```

### 2. Build Debian 13 Image

```bash
cd debian
sg kvm -c "make debian SERIES=trixie"
```

This will create `debian-13-cloudimg.tar.gz` (approximately 429MB).

**Build time**: ~10-15 minutes depending on network speed and system performance.

### 3. Upload to MAAS Server

```bash
# Copy tarball to MAAS server
scp debian-13-cloudimg.tar.gz ubuntu@<MAAS_IP>:/home/ubuntu/debian-13-vanilla.tar.gz

# SSH to MAAS server and upload the image
ssh ubuntu@<MAAS_IP>

maas admin boot-resources create \
  name='custom/debian-13-vanilla' \
  title='Debian 13 Vanilla (Trixie)' \
  architecture='amd64/generic' \
  filetype='tgz' \
  content@=/home/ubuntu/debian-13-vanilla.tar.gz
```

**Important**: Replace `admin` with your MAAS profile name and `<MAAS_IP>` with your MAAS server IP address.

### 4. Install Custom Preseed (Required for Debian)

Debian images require a custom preseed file to configure APT sources correctly during deployment:

```bash
# On MAAS server
sudo cp debian/preseed/curtin_userdata_custom_amd64 \
  /var/snap/maas/current/preseeds/curtin_userdata_custom_amd64

# Restart MAAS to load the preseed
sudo systemctl restart snap.maas.supervisor
```

### 5. Deploy via MAAS

1. Go to MAAS web UI
2. Select a machine
3. Click "Deploy"
4. Choose "Debian 13 Vanilla (Trixie)" from the OS dropdown
5. Complete deployment

**Boot Requirements**: UEFI boot must be enabled. Legacy BIOS is not supported for Debian 13 images.

**Default Credentials**: SSH with your MAAS-configured key as user `debian`.

## Building Proxmox VE Images (proxmox branch)

Build a Debian 13 image with Proxmox VE 9.1 pre-installed:

```bash
git checkout proxmox
cd debian

# Install packer ansible plugin
packer plugins install github.com/hashicorp/ansible

# Build image
sg kvm -c "packer build -var 'debian_series=trixie' -var 'debian_version=13' -var 'filename=proxmox-ve-91-cloudimg.tar.gz' ."
```

Output: `proxmox-ve-91-cloudimg.tar.gz` (~2.4GB) | Build time: ~30-40 minutes

### What's Included

- Proxmox VE 9.1 (pve-no-subscription repository)
- Proxmox kernel (Debian kernel removed)
- Cloud-init configuration for MAAS compatibility
- Automatic /etc/hosts fix for Proxmox cluster filesystem
- All services start automatically on deployment

### Upload to MAAS

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

### Post-Deployment

Web UI available immediately at `https://<machine-ip>:8006` (login: root@pam)

All Proxmox services (pve-cluster, pveproxy, pvedaemon, pvestatd) start automatically.

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

### Image boots to EFI shell

**Cause**: Bootloader not properly installed.

**Fix**: Ensure UEFI boot is enabled in BIOS/IPMI settings, and the custom preseed is installed on the MAAS server.

### Cannot login via SSH

**Default user for Debian images is `debian`, not `ubuntu`:**

```bash
ssh debian@<machine-ip>
```

### Deployment shows wrong Debian version

**Verify the uploaded tarball:**

```bash
# On MAAS server
sudo tar -xzf /var/snap/maas/common/maas/boot-resources/snapshot-*/custom/amd64/generic/debian-13-vanilla/uploaded/root-tgz \
  ./etc/debian_version -O
```

Should output `13.x`. If it shows `12.x`, the wrong file was uploaded.

### Build fails with "permission denied" on /dev/kvm

Ensure your user is in the `kvm` group:

```bash
sudo usermod -a -G kvm $USER
newgrp kvm
```

## Known Issues

- **Debian 13 UEFI boot only**: Separate BIOS builds are required (use `BOOT=bios` make parameter)
- **Legacy boot not working**: Disable legacy boot in BIOS to avoid confusion with multiple boot entries
- **First boot may be slow**: Cloud-init runs package updates and configuration

## References

- [Canonical packer-maas](https://github.com/canonical/packer-maas) - Original upstream repository
- [MAAS Documentation](https://maas.io/docs)
- [Debian Cloud Images](https://cloud.debian.org/images/cloud/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)

## License

This project uses configuration from Canonical's packer-maas repository (AGPL-3.0).

## Contributing

Contributions welcome! Please submit pull requests or open issues for bugs and feature requests.
