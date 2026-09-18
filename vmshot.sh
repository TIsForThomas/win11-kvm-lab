#!/bin/bash
# Screenshot the VM's console to a PNG, headlessly. virsh emits PNG despite the
# .ppm convention, so nothing needs converting.
#
# This is the only way to see what a VM is doing when it has no SSH yet, or when
# something refuses to run over SSH at all.
. "$(dirname "$0")/lib.sh"
OUT="${1:-$WORK_DIR/$VM-$(date +%H%M%S).png}"
sudo virsh screenshot "$VM" --file "$OUT" >/dev/null
sudo chown "$(id -u):$(id -g)" "$OUT" 2>/dev/null || true
echo "$OUT"
