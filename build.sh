#!/usr/bin/env bash
#
# build.sh - Build the davinci-resolve package.
#
# This package dynamically downloads DaVinci Resolve from Blackmagic Design's
# API, so the build requires internet access and ~3GB of disk space.
#
# Usage:
#   ./build.sh               # builds with default makepkg args
#   MAKEPKG_ARGS="-s" ./build.sh   # sync build dependencies via pacman
#
set -euo pipefail

cd "$(dirname "$0")"

MAKEPKG_ARGS="${MAKEPKG_ARGS:-}"

echo "=== Building davinci-resolve ==="
makepkg $MAKEPKG_ARGS

echo "=== Build complete ==="
ls -1 davinci-resolve-*.pkg.tar.zst 2>/dev/null || true
