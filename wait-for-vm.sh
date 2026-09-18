#!/bin/bash
# Block until the VM is installed, booted and answering SSH. Exit 0 ready, 1 timeout.
# One line of output per state change, so it is readable in a log.
. "$(dirname "$0")/lib.sh"

MAC=$(cat "$WORK_DIR/$VM.mac")
DEADLINE=$(( $(date +%s) + 5400 ))   # 90 min: an unattended install plus updates
state=""
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
    st=$(sudo virsh domstate "$VM" 2>&1)
    case "$st" in
      *running*) : ;;
      *"shut off"*)
        # Expected, not an error: virt-install's install phase ends with the domain
        # shut off after the guest's first reboot. Start it so the install continues.
        echo "domain shut off (end of install phase) - starting it"
        sudo virsh start "$VM" >/dev/null 2>&1 || true
        sleep 10
        ;;
      *) echo "VM in unexpected state: $st"; exit 1 ;;
    esac
    IP=$(sudo virsh net-dhcp-leases default 2>/dev/null \
         | awk -v m="$MAC" '$3==m {split($5,a,"/"); print a[1]}' | tail -1)
    if [ -z "$IP" ]; then
        [ "$state" = waiting_dhcp ] || { echo "waiting for DHCP lease (install in progress)"; state=waiting_dhcp; }
    else
        [ "$state" = "got_ip_$IP" ] || { echo "VM has IP $IP - waiting for sshd"; state="got_ip_$IP"; }
        if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=8 -o BatchMode=yes "$VM_USER@$IP" \
               'hostname; (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID' 2>/dev/null; then
            echo "$IP" > "$WORK_DIR/$VM.ip"
            echo "READY: ssh works, ip=$IP"
            exit 0
        fi
    fi
    sleep 25
done
echo "TIMEOUT after 90 min"; exit 1
