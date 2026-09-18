# Copy to config.sh and edit. config.sh is gitignored: it holds a password.
#
#   cp config.example.sh config.sh && $EDITOR config.sh

VM=win11lab                       # libvirt domain name
VM_USER=lab                       # the account created inside Windows
ADMIN_PASSWORD='ChangeMe!2026'    # that account's password. Lab use only.

# Where the VM's disk and build artifacts live. Needs room for the qcow2 (sparse,
# so it costs what Windows actually writes, not DISK_SIZE) plus a ~4 GiB ISO.
WORK_DIR="$HOME/win11lab"

# An extracted Windows 11 installation media tree: the folder containing
# sources/install.wim, setup.exe and efi/. Mount an ISO and point at the mountpoint,
# or use a deployment share's media tree.
MEDIA_SRC="/mnt/win11-iso"

# Which image inside sources/install.wim to install. `wimlib-imagex info <wim>`
# lists them. Exporting ONE edition is what keeps the ISO under ISO9660's 4 GiB
# per-file limit; see build-wim.sh.
WIM_INDEX=2

# The SSH key the host drives the VM with. The PUBLIC half is baked into the
# install media and authorized inside Windows.
SSH_KEY="$WORK_DIR/ssh/id_ed25519"

DISK_SIZE=512G                    # sparse. Large on purpose for disk-imaging work.
DISK_SERIAL=LAB-SRC-001           # shows up as the disk serial inside the guest
VM_MEMORY=8192
VM_VCPUS=4

# OVMF firmware with Secure Boot and Microsoft keys. Debian/Ubuntu paths; on
# Fedora these live under /usr/share/edk2/ovmf/.
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.ms.fd
OVMF_VARS=/usr/share/OVMF/OVMF_VARS_4M.ms.fd
