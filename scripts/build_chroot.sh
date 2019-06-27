#!/bin/bash -eux

BUILDDIR=/build
OUTDIR=$BUILDDIR/output

mkdir -p $BUILDDIR/initramfs
cd $BUILDDIR/initramfs
gunzip -c $BUILDDIR/alpine/boot/initramfs-vanilla | cpio -i
rm -rf $BUILDDIR/initramfs/lib/modules/4.*
tar zxfC "$OUTDIR/kernel/initramfs.tar.gz" "$BUILDDIR/initramfs"
find . | cpio -H newc -o | gzip -9 > $BUILDDIR/initramfs-rpi3-cpio
mkimage -A arm64 -O linux -T ramdisk -d $BUILDDIR/initramfs-rpi3-cpio $BUILDDIR/initramfs-rpi3

mkdir -p $BUILDDIR/modloop/lib/firmware
cd $BUILDDIR/linux-firmware
DESTDIR=$BUILDDIR/modloop make install

b43-fwcutter -w $BUILDDIR/modloop/lib/firmware $BUILDDIR/broadcom-wl/driver/wl_apsta_mimo.o
mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "raspberry-pi" -d $BUILDDIR/scripts/boot.txt $BUILDDIR/boot.scr
cp -R $BUILDDIR/initramfs/lib/modules $BUILDDIR/modloop/lib/
mksquashfs $BUILDDIR/modloop/lib/ $BUILDDIR/modloop-rpi3 -comp xz -Xdict-size 100%

mkdir -p $OUTDIR/all/boot
mkdir -p $OUTDIR/all/firmware

mv $OUTDIR/kernel/Image $OUTDIR/all/boot/
mv $OUTDIR/kernel/bcm2710-rpi-3-b.dtb $OUTDIR/all/
mv $OUTDIR/kernel/bcm2710-rpi-3-b-plus.dtb $OUTDIR/all/
mv $OUTDIR/u-boot/u-boot.bin $OUTDIR/all/boot/

cp $BUILDDIR/initramfs-rpi3 $OUTDIR/all/boot/
cp $BUILDDIR/modloop-rpi3 $OUTDIR/all/boot/
cp $BUILDDIR/boot.scr $OUTDIR/all/boot/
cp $BUILDDIR/pi-firmware/boot/bootcode.bin $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/start.elf $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/fixup.dat $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/start_cd.elf $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/fixup_cd.dat $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/start_x.elf $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/fixup_x.dat $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/start_db.elf $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/fixup_db.dat $OUTDIR/all/
cp $BUILDDIR/pi-firmware/boot/bcm2710-rpi-cm3.dtb $OUTDIR/all/
cp $BUILDDIR/alpine/alpine.apkovl.tar.gz $OUTDIR/all/
cp -R $BUILDDIR/alpine/apks $OUTDIR/all/
cp -R $BUILDDIR/modloop/lib/firmware/brcm $OUTDIR/all/firmware
cp -R $BUILDDIR/modloop/lib/firmware/b43 $OUTDIR/all/firmware
cp $BUILDDIR/scripts/config.txt $OUTDIR/all/
cp $BUILDDIR/scripts/cmdline.txt $OUTDIR/all/
cd $OUTDIR/all && tar Jcf "$OUTDIR/alpine-rpi-3.10.0-aarch64-$KERNELVERSION.tar.xz" .

rm -rf $BUILDDIR/initramfs-rpi3
rm -rf $BUILDDIR/modloop-rpi3
