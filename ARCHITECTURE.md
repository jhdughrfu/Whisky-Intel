# Fork Architecture and Modifications

This document outlines the architectural changes implemented in this fork of Whisky to enable compatibility with Intel Macs and macOS 13.0 (Ventura).

## Overview

Upstream Whisky is designed exclusively for Apple Silicon (ARM64) and targets macOS 14.0 (Sonoma) or newer, leveraging Apple's Game Porting Toolkit. To bring compatibility to Intel (x86_64) platforms and macOS 13.0, build targets, dependency configurations, and system-level architecture checks were modified.

## Architectural Changes

### 1. Universal Binary Build Configuration
The project is configured to compile as a Universal Binary supporting both target architectures:
*   **x86_64** (Intel 64-bit)
*   **arm64** (Apple Silicon)

This was done by replacing hardcoded `ARCHS = arm64` settings with standard architectures `ARCHS = "$(ARCHS_STANDARD)"` across all build targets in `Whisky.xcodeproj/project.pbxproj`.

### 2. Lowered Deployment Targets
The minimum deployment target (`MACOSX_DEPLOYMENT_TARGET`) was lowered from `14.0` to `13.0` across the entire project structure to support macOS Ventura. This affects:
*   The main UI application bundle (Whisky)
*   The helper command-line tool (WhiskyCmd)
*   The thumbnail provider extension (WhiskyThumbnail)
*   The embedded Swift Package dependencies (WhiskyKit)

### 3. Swift Package Platform Configuration
The platform requirements inside `WhiskyKit/Package.swift` were updated to support `.macOS(.v13)` to allow compilation of the internal business logic layers on macOS 13.

### 4. Runtime Architecture Detection
A new enum `SystemArchitecture` was introduced in `Whisky/Utils/Constants.swift` to allow the application to identify the host platform dynamically at runtime:
*   `isAppleSilicon`: Returns `true` if compiling/running on ARM64.
*   `isIntel`: Returns `true` if compiling/running on x86_64.
*   `currentArchitecture`: Returns a human-readable description of the current architecture.

This allows the UI or runtime scripts to conditionally adapt features or show user warnings depending on whether the application is running on an Intel Mac or an Apple Silicon Mac.

## Limitations & Dependencies

*   **cabextract Binary**: The bundled `Libraries/cabextract` is a precompiled ARM64-only binary. On Intel Macs, operations depending on cabextract (such as Winetricks installations) will fail unless an external Intel-compatible `cabextract` executable is installed (e.g., via Homebrew).
*   **Translation Layers**: Apple's `D3DMetal` API translation layer remains Apple Silicon exclusive. On Intel Macs, the app must fall back to alternative translators like DXVK, which runs DirectX over Vulkan/Metal.
