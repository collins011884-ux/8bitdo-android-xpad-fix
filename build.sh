#!/bin/bash
# Builds the static helper binaries with the Android NDK and packages the Magisk module zip.
# Usage: NDK=/path/to/android-ndk ./build.sh
set -euo pipefail
cd "$(dirname "$0")"
: "${NDK:?set NDK to your Android NDK directory}"
TC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
build() { mkdir -p "module/bin/$1"; "$TC/$2-clang" -O2 -Wall -static -s -o "module/bin/$1/xpad-led-kick" src/xpad-led-kick.c; }
build arm64-v8a aarch64-linux-android21
build armeabi-v7a armv7a-linux-androideabi21
VERSION=$(sed -n 's/^version=//p' module/module.prop)
mkdir -p dist
rm -f "dist/8bitdo-xpad-fix-$VERSION.zip"
(cd module && zip -qr9 "../dist/8bitdo-xpad-fix-$VERSION.zip" .)
echo "built dist/8bitdo-xpad-fix-$VERSION.zip"
