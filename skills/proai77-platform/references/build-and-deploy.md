# ProAI77 Build, CMake, and Deployment Guide

## 1. Native Build on ProAI77
Building directly on the 8-core RK3588 board is fast and eliminates cross-compilation sysroot issues.

### CMakeLists.txt Skeleton:
```cmake
cmake_minimum_required(VERSION 3.20)
project(proai77_vision_app LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Load ProAI77 Compiler Flags
include(cmake/ProAI77Flags.cmake)

# Find System Dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(MPP REQUIRED rockchip_mpp)
pkg_check_modules(RGA REQUIRED librga)
pkg_check_modules(TURBOJPEG REQUIRED libturbojpeg)

# Find MemryX Runtime
find_path(MEMX_INCLUDE_DIR memx/accl/MxAccl.h PATHS /usr/include)
find_library(MEMX_LIB memx_accl PATHS /usr/lib /usr/lib/aarch64-linux-gnu)

add_executable(vision_app
    src/main.cpp
    src/mpp_decoder.cpp
    src/rga_preprocess.cpp
    src/mx3_inference.cpp
    src/neon_postprocess.cpp
)

target_include_directories(vision_app PRIVATE
    include
    ${MPP_INCLUDE_DIRS}
    ${RGA_INCLUDE_DIRS}
    ${MEMX_INCLUDE_DIR}
)

target_link_libraries(vision_app PRIVATE
    ${MPP_LIBRARIES}
    ${RGA_LIBRARIES}
    ${TURBOJPEG_LIBRARIES}
    ${MEMX_LIB}
    pthread
)

# Apply hot-loop -O3 flags to NEON post-processing
proai77_optimize_hot_source(src/neon_postprocess.cpp)
```

## 2. Hybrid C++ / Python Build (`pybind11`)
When building Tier 3 (Hybrid) pipelines:
```cmake
find_package(pybind11 REQUIRED)
pybind11_add_module(proai77_core
    src/bindings.cpp
    src/mpp_decoder.cpp
    src/rga_preprocess.cpp
)
target_link_libraries(proai77_core PRIVATE ${MPP_LIBRARIES} ${RGA_LIBRARIES})
```

## 3. Deployment Directory Layout
Standard production service layout on ProAI77:
```
/opt/proai77/
├── app/
│   ├── bin/
│   │   └── vision_app
│   ├── config.json
│   └── models/
│       └── current_model_c4.dfp
└── logs/
```

Managed via systemd:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now proai77-app.service
journalctl -u proai77-app.service -f
```
