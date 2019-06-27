#!/bin/bash -eux

BUILDDIR=/build
OUTDIR=$BUILDDIR/output

export CROSS_COMPILE="ccache aarch64-linux-gnu-"
export ARCH=arm64
export LOCALVERSION=
export CCACHE_DIR=/ccache
export CFLAGS="-pipe -O3 -mcpu=cortex-a53 -funsafe-math-optimizations"
export LDFLAGS="-pipe -O3 -mcpu=cortex-a53 -funsafe-math-optimizations"

cd $BUILDDIR/u-boot
make rpi_3_defconfig && make

mkdir -p $OUTDIR/u-boot
mv $BUILDDIR/u-boot/u-boot.bin $OUTDIR/u-boot/
