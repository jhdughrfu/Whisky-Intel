# Build Instructions

This document provides detailed instructions on how to build the Intel-compatible version of Whisky.

## Prerequisites

To build the application, ensure your development machine meets the following requirements:
*   **Operating System**: macOS 13.0 (Ventura) or later.
*   **IDE**: Xcode 15.0 or later (includes the necessary Swift compiler toolchain).
*   **Package Manager**: Homebrew (optional, but highly recommended for dependency management).

---

## Build Options

### Option 1: Building with Xcode (GUI)

1.  Open the project in Xcode:
    ```bash
    open Whisky.xcodeproj
    ```
2.  In the Xcode scheme selector (at the top of the window), select **Whisky**.
3.  Set the run destination to **My Mac** or **Any Mac**.
4.  Build the project by pressing `Cmd + B`, or run it immediately by pressing `Cmd + R`.
5.  Once compiled, the resulting application bundle will be located in Xcode's `DerivedData` directory.

### Option 2: Building via Command Line (Terminal)

You can build the targets directly from the terminal using `xcodebuild`. 

#### Build as a Universal Binary (Default)
To build a binary that runs natively on both Intel and Apple Silicon Macs:
```bash
xcodebuild -project Whisky.xcodeproj \
  -scheme Whisky \
  -configuration Release \
  -arch x86_64 -arch arm64 \
  build
```

#### Build for Intel Only
To build specifically for Intel (x86_64) platforms:
```bash
xcodebuild -project Whisky.xcodeproj \
  -scheme Whisky \
  -configuration Release \
  -arch x86_64 \
  build
```

#### Build for Apple Silicon Only
To build specifically for Apple Silicon (ARM64) platforms:
```bash
xcodebuild -project Whisky.xcodeproj \
  -scheme Whisky \
  -configuration Release \
  -arch arm64 \
  build
```

### Option 3: Using the Build Script
A helper build script is provided in the repository. Run it to configure dependencies and compile:
```bash
./build.sh
```
The script handles dependency checks and builds the project output inside the `.build-intel/` directory.
