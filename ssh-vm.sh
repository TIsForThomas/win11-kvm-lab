#!/bin/bash
# Open a shell on the VM, or run a command on it:  ./ssh-vm.sh 'Get-Date'
. "$(dirname "$0")/lib.sh"
IP=$(cat "$WORK_DIR/$VM.ip" 2>/dev/null) || { echo "no cached IP -- run wait-for-vm.sh" >&2; exit 1; }
exec ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
     "$VM_USER@$IP" "$@"
