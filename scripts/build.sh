#!/bin/bash -eux

function teardown() {
    umount -l "$CHROOTDIR/build/output"
    umount -l "$CHROOTDIR/build/pi-firmware"
    umount -l "$CHROOTDIR/build/linux-firmware"
    umount -l "$CHROOTDIR/build/alpine"
    umount -l "$CHROOTDIR/build/broadcom-wl"

    chmod a+rw -R "$CHROOTDIR/build/output"
}

mkdir -p "$CHROOTDIR"
mkdir -p "${CACHEDIR}/output"

mkdir -p "$CHROOTDIR/build/pi-firmware"
mkdir -p "$CHROOTDIR/build/linux-firmware"
mkdir -p "$CHROOTDIR/build/alpine"
mkdir -p "$CHROOTDIR/build/broadcom-wl"
mkdir -p "$CHROOTDIR/build/output"

mkdir -p "${TRAVIS_BUILD_DIR}/pi-firmware"
mkdir -p "${TRAVIS_BUILD_DIR}/linux-firmware"
mkdir -p "${TRAVIS_BUILD_DIR}/alpine"
mkdir -p "${TRAVIS_BUILD_DIR}/broadcom-wl"

tar zxfpC "${CACHEDIR}/pi-firmware.tar.gz" "${TRAVIS_BUILD_DIR}/pi-firmware"
tar zxfpC "${CACHEDIR}/linux-firmware.tar.gz" "${TRAVIS_BUILD_DIR}/linux-firmware"
tar zxfpC "${CACHEDIR}/alpine-uboot-3.10.0-aarch64.tar.gz" "${TRAVIS_BUILD_DIR}/alpine"
tar jxfpC "${CACHEDIR}/broadcom-wl-4.150.10.5.tar.bz2" "${TRAVIS_BUILD_DIR}/broadcom-wl" --strip=1

trap teardown EXIT

mount -o bind "${TRAVIS_BUILD_DIR}/pi-firmware" "$CHROOTDIR/build/pi-firmware"
mount -o bind "${TRAVIS_BUILD_DIR}/linux-firmware" "$CHROOTDIR/build/linux-firmware"
mount -o bind "${TRAVIS_BUILD_DIR}/alpine" "$CHROOTDIR/build/alpine"
mount -o bind "${TRAVIS_BUILD_DIR}/broadcom-wl" "$CHROOTDIR/build/broadcom-wl"
mount -o bind "${CACHEDIR}/output" "$CHROOTDIR/build/output"

chroot $CHROOTDIR /build/scripts/build_chroot.sh
