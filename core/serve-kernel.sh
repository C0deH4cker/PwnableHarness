#!/bin/bash
# serve-kernel.sh — socat+QEMU entrypoint for kernel challenges.
# Listens on $PORT, forks a fresh QEMU VM per connection.
#
# If /ctf/flag.txt exists (bind-mounted by PwnableHarness workdir),
# repack the initramfs to include the real flag before serving.
set -eu

: "${PORT:=9000}"
: "${TIMELIMIT:=120}"
: "${QEMU_ARCH:=x86_64}"
: "${QEMU_CPU:=qemu64}"
: "${QEMU_MEM:=512M}"
: "${QEMU_SMP:=1}"
: "${KERNEL_CMDLINE:=console=ttyS0 quiet panic=-1}"

INITRAMFS=/challenge/initramfs.cpio.gz

if [ -f /ctf/flag.txt ]; then
    WORK=$(mktemp -d)
    cd "$WORK"
    zcat "$INITRAMFS" | cpio -id 2>/dev/null
    cp /ctf/flag.txt flag
    chmod 400 flag
    find . | cpio -o -H newc 2>/dev/null | gzip > /tmp/initramfs-live.cpio.gz
    cd /
    rm -rf "$WORK"
    INITRAMFS=/tmp/initramfs-live.cpio.gz
fi

MACHINE_FLAG=""
case "$QEMU_ARCH" in
    aarch64) MACHINE_FLAG="-M virt" ;;
    riscv64) MACHINE_FLAG="-M virt" ;;
    mipsel)  MACHINE_FLAG="-M malta" ;;
esac

cat > /tmp/run-vm.sh <<VMEOF
#!/bin/sh
exec timeout ${TIMELIMIT} qemu-system-${QEMU_ARCH} \
    ${MACHINE_FLAG} \
    -kernel /challenge/bzImage \
    -initrd ${INITRAMFS} \
    -append "${KERNEL_CMDLINE}" \
    -nographic -m ${QEMU_MEM} -no-reboot \
    -cpu ${QEMU_CPU} -smp ${QEMU_SMP} \
    -monitor none
VMEOF
chmod +x /tmp/run-vm.sh

exec socat \
    "TCP-LISTEN:${PORT},reuseaddr,fork" \
    "EXEC:/tmp/run-vm.sh"
