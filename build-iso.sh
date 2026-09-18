#!/bin/bash
# Build an unattended install ISO from an extracted media tree.
#
# Staging is a symlink farm (cp -as), so nothing is copied except the ISO itself.
# The autounattend and the first-logon script are generated here from their .in
# templates, so the password and SSH key live in config.sh and never in git.
. "$(dirname "$0")/lib.sh"
need xorriso; need ssh-keygen

STAGE="$WORK_DIR/stage"
OUT="$WORK_DIR/$VM-unattend.iso"

[ -f "$WORK_DIR/overlay/sources/install.wim" ] || { echo "run build-wim.sh first" >&2; exit 1; }

# The host's key to drive the VM with. Generated once, never committed.
if [ ! -f "$SSH_KEY" ]; then
    mkdir -p "$(dirname "$SSH_KEY")"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "$VM lab" >/dev/null
    echo "generated $SSH_KEY"
fi
PUBKEY="$(cat "$SSH_KEY.pub")"

gen() {  # template -> staged file, with the secrets substituted in
    sed -e "s|@@ADMIN_PASSWORD@@|$ADMIN_PASSWORD|g" \
        -e "s|@@VM_USER@@|$VM_USER|g" \
        -e "s|@@SSH_PUBKEY@@|$PUBKEY|g" "$1" > "$2"
}

rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -as "$MEDIA_SRC/." "$STAGE/"
ln -sf "$WORK_DIR/overlay/sources/install.wim" "$STAGE/sources/install.wim"
gen "$(dirname "$0")/autounattend.xml.in" "$STAGE/autounattend.xml"
gen "$(dirname "$0")/vmsetup.ps1.in"      "$STAGE/vmsetup.ps1"

# UEFI El Torito entry only: this VM boots OVMF, never legacy BIOS.
xorriso -as mkisofs \
    -iso-level 3 -J -joliet-long -R -follow-links \
    -V "WINLAB" \
    -e 'efi/microsoft/boot/efisys_noprompt.bin' -no-emul-boot \
    -o "$OUT" "$STAGE"

rm -rf "$STAGE"
ls -la "$OUT"
