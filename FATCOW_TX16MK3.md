# Fat Cow TX16S MK3 EdgeTX workflow

Base upstream release: `v2.12.4`

Branches:
- `upstream-tracking`: pristine upstream release baseline.
- `tx16mk3-mavlink`: Fat Cow TX16S MK3 patches.

Build:
```bash
tools/fatcow-build-tx16mk3.sh v2.12.4
```

The build uses Arm GNU Toolchain 14.2.Rel1 from
`/home/rob/.local/opt/gcc-arm-none-eabi-14.2.rel1`, a repo-local Python
virtual environment, and the official EdgeTX submodules.

Current design target:
- keep the existing CRSF/Yaapu telemetry path intact;
- add a laptop-facing USB CDC MAVLink bridge without stopping RF;
- bridge USB bytes to/from the internal CRSF/mLRS module with minimal EdgeTX
  policy or MAVLink parsing;
- keep image buffering/routing in the mLRS ESP32, not Lua;
- leave Wi-Fi MAVLink out of the critical path for now.

Likely EdgeTX patch points:
- `radio/src/main.cpp`: USB mode selection/lifecycle.
- `radio/src/hal/usb_driver.{h,cpp}`: USB mode state.
- `radio/src/targets/common/arm/stm32/usbd_cdc.cpp`: CDC RX/TX callbacks.
- `radio/src/serial.cpp`: VCP serial plumbing.
- `radio/src/pulses/crossfire.cpp`: internal CRSF module RX/TX ownership.
- `radio/src/hal/module_port.{h,cpp}`: internal module serial access.
- `radio/src/boards/generic_stm32/module_ports.cpp`: TX16 internal module UART.
