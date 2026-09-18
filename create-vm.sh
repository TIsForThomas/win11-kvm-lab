#!/bin/bash
# Create, or destroy and recreate, the lab VM. Rebuilding from scratch every time
# means a botched unattend costs one command rather than manual cleanup.
#
# The hardware is deliberately close to a real machine: q35 + OVMF with Secure Boot
# and Microsoft keys, an emulated TPM 2.0 (Windows 11 requires both), and SATA
# rather than virtio, because Windows Setup has no in-box virtio storage driver.
. "$(dirname "$0")/lib.sh"
need virt-install

DISK="$WORK_DIR/$VM.qcow2"
ISO="$WORK_DIR/$VM-unattend.iso"
[ -f "$ISO" ] || { echo "no ISO at $ISO -- run build-iso.sh first" >&2; exit 1; }

sudo virsh destroy  "$VM" 2>/dev/null || true
sudo virsh undefine "$VM" --nvram 2>/dev/null || true

rm -f "$DISK"
sudo qemu-img create -f qcow2 "$DISK" "$DISK_SIZE" >/dev/null
sudo chown libvirt-qemu:kvm "$DISK" 2>/dev/null || true
sudo chmod 660 "$DISK"

sudo virt-install \
    --name "$VM" \
    --osinfo win11 \
    --memory "$VM_MEMORY" --vcpus "$VM_VCPUS" --cpu host-passthrough \
    --machine q35 \
    --features smm=on \
    --boot uefi,loader=$OVMF_CODE,loader.secure=yes,loader.readonly=yes,loader.type=pflash,nvram.template=$OVMF_VARS \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --disk path="$DISK",bus=sata,serial="$DISK_SERIAL",cache=writeback \
    --cdrom "$ISO" \
    --network network=default,model=e1000e \
    --graphics vnc,listen=127.0.0.1 \
    --video qxl \
    --noautoconsole

sudo virsh dumpxml "$VM" | grep -oP "mac address='\K[^']+" > "$WORK_DIR/$VM.mac"
echo "created; mac $(cat "$WORK_DIR/$VM.mac")"
