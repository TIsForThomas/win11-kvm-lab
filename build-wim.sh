#!/bin/bash
# Export ONE edition out of the media's multi-edition install.wim.
#
# Why this exists: a stock multi-edition install.wim is often over 4 GiB, and
# ISO9660 has a 4 GiB per-file limit. xorriso here has no -udf emulation, and
# multi-extent ISO9660 is unreliable under Windows Setup's CDFS driver, so the
# fix is to ship a single-edition export instead of splitting the file.
. "$(dirname "$0")/lib.sh"
need wimlib-imagex

SRC="$MEDIA_SRC/sources/install.wim"
[ -f "$SRC" ] || { echo "no install.wim at $SRC -- is MEDIA_SRC right?" >&2; exit 1; }

mkdir -p "$WORK_DIR/overlay/sources"
wimlib-imagex export "$SRC" "$WIM_INDEX" "$WORK_DIR/overlay/sources/install.wim" \
    --compress=LZX --chunk-size=32K
ls -la "$WORK_DIR/overlay/sources/install.wim"
