#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:-v2.12.4}"
PATCHSET="${FATCOW_PATCHSET:-fatcow1}"
TOOLCHAIN="${ARM_GNU_TOOLCHAIN:-/home/rob/.local/opt/gcc-arm-none-eabi-14.2.rel1}"
VENV="${EDGETX_VENV:-$ROOT/.venv-edgetx}"
BUILD="$ROOT/build-tx16mk3"
DIST="$ROOT/dist"

if [[ ! -x "$TOOLCHAIN/bin/arm-none-eabi-gcc" ]]; then
  echo "Missing Arm GNU Toolchain 14.2.rel1 at $TOOLCHAIN" >&2
  exit 2
fi

if [[ ! -x "$VENV/bin/python" ]]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install -q clang libclang lz4 pillow jinja2 pyelftools pydantic asciitree

git -C "$ROOT" submodule update --init --recursive

BASE="$TOOLCHAIN"
INC="$BASE/arm-none-eabi/include/c++/14.2.1:$BASE/arm-none-eabi/include/c++/14.2.1/arm-none-eabi:$BASE/arm-none-eabi/include/c++/14.2.1/backward:$BASE/lib/gcc/arm-none-eabi/14.2.1/include:$BASE/lib/gcc/arm-none-eabi/14.2.1/include-fixed:$BASE/arm-none-eabi/include"
export PATH="$BASE/bin:$PATH"
export CPATH="$INC"
export CPLUS_INCLUDE_PATH="$INC"

rm -rf "$BUILD"
cmake -S "$ROOT" -B "$BUILD" -G Ninja   -DPCB=TX16SMK3   -DTRANSLATIONS=EN   -DCMAKE_BUILD_TYPE=Release   -DPython3_EXECUTABLE="$VENV/bin/python"

cmake --build "$BUILD" --target firmware -j"${JOBS:-6}"

mkdir -p "$DIST"
DESC="$(git -C "$ROOT" describe --tags --always --dirty | tr '/' '-')"
OUT_BASE="EdgeTX-TX16SMK3-${TAG#v}-${PATCHSET}-${DESC}"
cp "$BUILD/arm-none-eabi/firmware.bin" "$DIST/$OUT_BASE.bin"
cp "$BUILD/arm-none-eabi/firmware.uf2" "$DIST/$OUT_BASE.uf2"
sha256sum "$DIST/$OUT_BASE.bin" "$DIST/$OUT_BASE.uf2" > "$DIST/$OUT_BASE.sha256"

echo "Built:"
echo "  $DIST/$OUT_BASE.bin"
echo "  $DIST/$OUT_BASE.uf2"
