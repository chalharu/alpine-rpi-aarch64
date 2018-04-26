#!/bin/bash -eu

BUILDDIR=/build
OUTDIR=$BUILDDIR/output

mkdir -p $BUILDDIR/alpine
mkdir -p $BUILDDIR/kernel-build
mkdir -p $BUILDDIR/initramfs
mkdir -p $BUILDDIR/modloop
mkdir -p $BUILDDIR/b43

cd $BUILDDIR
git clone --depth 1 --branch rpi-4.16.y https://github.com/raspberrypi/linux.git kernel
git clone --depth 1 https://github.com/raspberrypi/firmware.git pi-firmware
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git linux-firmware
wget -q http://dl-cdn.alpinelinux.org/alpine/v3.7/releases/aarch64/alpine-uboot-3.7.0-aarch64.tar.gz
wget -q http://mirror2.openwrt.org/sources/broadcom-wl-4.150.10.5.tar.bz2

cd $BUILDDIR/alpine
tar zxf $BUILDDIR/alpine-uboot-3.7.0-aarch64.tar.gz
cd $BUILDDIR/initramfs
gunzip -c $BUILDDIR/alpine/boot/initramfs-vanilla | cpio -i

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
export LOCALVERSION=

cd $BUILDDIR/kernel
make kernelversion > $BUILDDIR/kernelversion
KERNELVERSION=$(cat $BUILDDIR/kernelversion)
echo KERNELVERSION="$KERNELVERSION"
make O=$BUILDDIR/kernel-build bcmrpi3_defconfig
scripts/kconfig/merge_config.sh -O $BUILDDIR/kernel-build/ $BUILDDIR/kernel-build/.config $BUILDDIR/scripts/config.add
make O=$BUILDDIR/kernel-build -j8
rm -rf $BUILDDIR/initramfs/lib/modules/4.*
make modules_install O=$BUILDDIR/kernel-build INSTALL_MOD_PATH=$BUILDDIR/initramfs/

cd $BUILDDIR/initramfs
find . | cpio -H newc -o | gzip -9 > $BUILDDIR/initramfs-rpi3-cpio

cd $BUILDDIR
mkimage -A arm64 -O linux -T ramdisk -d initramfs-rpi3-cpio initramfs-rpi3
mkdir -p $BUILDDIR/modloop/lib/firmware

cd $BUILDDIR/linux-firmware
DESTDIR=$BUILDDIR/modloop make install

cd $BUILDDIR/b43
tar xjf $BUILDDIR/broadcom-wl-4.150.10.5.tar.bz2 --strip=1
b43-fwcutter -w $BUILDDIR/modloop/lib/firmware $BUILDDIR/b43/driver/wl_apsta_mimo.o
mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "raspberry-pi" -d $BUILDDIR/scripts/boot.txt $BUILDDIR/boot.scr
cp -R $BUILDDIR/initramfs/lib/modules $BUILDDIR/modloop/lib/
mksquashfs $BUILDDIR/modloop/lib/ $BUILDDIR/modloop-rpi3 -comp xz -Xdict-size 100%

mkdir -p $OUTDIR/boot
mkdir -p $OUTDIR/firmware
cp $BUILDDIR/kernel-build/arch/arm64/boot/Image $OUTDIR/boot/Image
cp $BUILDDIR/kernel-build/arch/arm64/boot/dts/broadcom/bcm2710-rpi-3-b.dtb $OUTDIR/
cp $BUILDDIR/kernel-build/arch/arm64/boot/dts/broadcom/bcm2710-rpi-3-b-plus.dtb $OUTDIR/
cp $BUILDDIR/initramfs-rpi3 $OUTDIR/boot/
cp $BUILDDIR/modloop-rpi3 $OUTDIR/boot/
cp $BUILDDIR/boot.scr $OUTDIR/boot/
cp $BUILDDIR/pi-firmware/boot/bootcode.bin $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/start.elf $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/fixup.dat $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/start_cd.elf $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/fixup_cd.dat $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/start_x.elf $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/fixup_x.dat $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/start_db.elf $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/fixup_db.dat $OUTDIR/
cp $BUILDDIR/pi-firmware/boot/bcm2710-rpi-cm3.dtb $OUTDIR/
cp $BUILDDIR/alpine/alpine.apkovl.tar.gz $OUTDIR/
cp -R $BUILDDIR/alpine/apks $OUTDIR/
cp -R $BUILDDIR/modloop/lib/firmware/brcm $OUTDIR/firmware
cp -R $BUILDDIR/modloop/lib/firmware/b43 $OUTDIR/firmware
cp $BUILDDIR/u-boot.bin $OUTDIR/boot/
cp $BUILDDIR/scripts/config.txt $OUTDIR/
cp $BUILDDIR/scripts/cmdline.txt $OUTDIR/
cd $OUTDIR && tar Jcf "$BUILDDIR/alpine-rpi-3.7.0-aarch64-$KERNELVERSION.tar.xz" .