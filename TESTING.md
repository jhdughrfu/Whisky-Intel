# Testing Guidelines

This document outlines the testing guidelines to verify functionality and catch regressions across different architectures.

## Verification Checklist

When testing changes, verify the core user journeys listed below.

### 1. Basic Operations
*   **App Launch**: Verify the application opens and initial screen displays correctly without crashes.
*   **Bottle Creation**: Create a new Wine bottle. Verify configuration directories and structural files are populated.
*   **Programs List**: Confirm that installed applications are detected and listed in the main interface.

### 2. Compatibility Checks (Intel vs. Apple Silicon)

#### On Intel Macs (x86_64)
*   **Runtime Architecture Check**: Verify the app does not crash when querying system details or environment variables.
*   **Winetricks Workaround**: 
    1. Verify that using Winetricks prints a warning or fails when using the bundled arm64 `cabextract`.
    2. Install `cabextract` via Homebrew (`brew install cabextract`).
    3. Verify Winetricks installs packages successfully using the system-installed binary.
*   **GPU Rendering Fallback**: Check that DirectX games run using the DXVK translation layer (verify Metal/Vulkan translator handles shaders without crashing).

#### On Apple Silicon Macs (arm64)
*   **Regression Check**: Confirm that all original Apple Silicon optimizations, including direct D3DMetal translation and MoltenVK pipelines, work without any performance impact.
*   **Winetricks**: Confirm Winetricks runs out-of-the-box using the bundled `cabextract` binary.

---

## Code Verification

Before pushing any modifications, check syntax and project style:
1.  Open the workspace in Xcode to ensure there are no compilation warnings or build-breaking errors.
2.  If SwiftLint is active in the build phases, verify that no SwiftLint violations appear during compilation.
