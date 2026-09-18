# win11-kvm-lab

A Windows 11 VM on KVM that you can drive from a shell: **Secure Boot on, emulated
TPM 2.0, unattended install, SSH reachable, and rebuildable from scratch with four
commands.**

```bash
cp config.example.sh config.sh && $EDITOR config.sh
./build-wim.sh      # export one edition from the install media
./build-iso.sh      # build an unattended ISO from it
./create-vm.sh      # destroy and recreate the VM
./wait-for-vm.sh    # blocks until SSH answers
./ssh-vm.sh 'Get-ComputerInfo | Select OsName, WindowsBuildLabEx'
```

It exists because testing anything Windows-side from a Linux host is otherwise a
slow manual loop. With this, a change can be tried, observed and reverted without
touching a keyboard attached to real hardware.

## Why it is shaped this way

Every one of these is a trap that cost real time, so they are worth knowing even if
you build your own:

- **SATA, not virtio.** Windows Setup has no in-box virtio storage driver, so a
  virtio disk gives "no drives were found" with no explanation.
- **q35 + `smm=on` + OVMF with Microsoft keys + an emulated TPM 2.0.** Windows 11
  refuses to install without Secure Boot and a TPM, and Secure Boot needs SMM to be
  meaningful.
- **One edition exported out of `install.wim`, not the whole thing.** A stock
  multi-edition `install.wim` is often over 4 GiB, and ISO9660 has a 4 GiB per-file
  limit. `xorriso` here has no `-udf` emulation and multi-extent ISO9660 is
  unreliable under Windows Setup's CDFS driver, so splitting the file is not the
  answer. Exporting one edition is.
- **The domain shuts itself off partway through the install.** That is not a
  failure: `virt-install`'s install phase ends when the guest first reboots.
  `wait-for-vm.sh` treats it as expected and starts the domain again, which is the
  difference between a working unattended build and one that appears to hang.
- **An admin account authorizes SSH via `administrators_authorized_keys`**, not
  `~/.ssh/authorized_keys`. Windows sshd ignores the latter for administrators by
  default, and the failure looks exactly like a bad key. The file also has to be
  writable only by Administrators and SYSTEM or sshd silently refuses it.
- **OpenSSH Server is a Feature-on-Demand**, so it needs to reach Windows Update and
  the first logon can beat the network coming up. `vmsetup.ps1` retries ten times.
- **Partition sizes have almost no slack.** An earlier version asked for a 1024 MiB
  recovery partition with 1022 MiB actually left after GPT overhead and 1 MiB
  alignment. `CreatePartition` failed, `DiskConfiguration` aborted, and Setup fell
  back to the interactive disk-selection page and sat there forever. If you change
  any partition size in `autounattend.xml.in`, recheck the total.

## Things it deliberately does not do

The VM keeps Windows defaults for hibernation, fast startup and activation. Those
are real conditions that anything operating on a Windows disk has to cope with, so
turning them off would make the lab easier and the testing worthless.

No product key is set. An unactivated install is a realistic state, and it is often
exactly the state worth testing against.

## Driving it

`wait-for-vm.sh` caches the guest's IP, so `ssh-vm.sh` needs no arguments:

```bash
./ssh-vm.sh                                  # interactive PowerShell
./ssh-vm.sh 'Get-Service sshd'               # one command
./vmshot.sh                                  # PNG of the console, headless
```

`vmshot.sh` matters more than it looks. Some things genuinely will not run over
SSH: `sysprep.exe` needs an interactive desktop and exits instantly without one, and
a scheduled task with `/IT` does not stand in for that either. When a VM is doing
something invisible, a screenshot is the only way to see it.

### Snapshots, and why not the obvious one

Use a backing-file overlay rather than `virsh snapshot-create-as`: this domain uses
pflash for OVMF, and libvirt internal snapshots do not support it.

```bash
. ./config.sh
sudo virsh dumpxml "$VM" > /tmp/orig.xml
sudo qemu-img create -f qcow2 -b "$WORK_DIR/$VM.qcow2" -F qcow2 "$WORK_DIR/$VM-test.qcow2"
sed "s|$VM.qcow2|$VM-test.qcow2|" /tmp/orig.xml > /tmp/test.xml
sudo virsh define /tmp/test.xml && sudo virsh start "$VM"
# revert:
sudo virsh destroy "$VM"; sudo virsh define /tmp/orig.xml
sudo rm -f "$WORK_DIR/$VM-test.qcow2"
```

That makes a destructive experiment free in both directions, which is the whole
value of a lab VM.

## Requirements

`libvirt`, `qemu-kvm`, `virt-install`, `swtpm` (for the emulated TPM), `xorriso`,
`wimlib-imagex`, and OVMF firmware with the Microsoft keys (`ovmf` on Debian and
Ubuntu). You also need an extracted Windows 11 installation media tree, which this
repo does not and cannot provide.

## Secrets

`config.sh` holds the VM's password and is gitignored. The SSH keypair is generated
on first `build-iso.sh` into `WORK_DIR` and is never committed. `autounattend.xml.in`
and `vmsetup.ps1.in` are templates: the real values are substituted at build time,
into the staging tree, which is deleted afterwards.

The password lands in the built ISO in plain text, because that is how
`autounattend.xml` works. Treat the ISO as a secret, and do not use a password you
use anywhere else.

## License

MIT. See `LICENSE`.
