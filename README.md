# Whisky (Intel Compatibility Fork)

This is a modified version of Whisky, a native macOS graphical wrapper for Wine built in SwiftUI. While the upstream project is designed for Apple Silicon and macOS 14.0 (Sonoma) or later, this repository contains modifications to add support for Intel Macs and macOS 13.0 (Ventura) or later.

## Modifications and Changes

The following modifications have been made to build and run the project as a Universal Binary:

* **Xcode Build Configuration**: Configured the build architectures from `arm64` to `$(ARCHS_STANDARD)` across all build targets. This enables building the binary for both Intel (`x86_64`) and Apple Silicon (`arm64`) architectures.
* **macOS Target Lowered**: Lowered the minimum deployment target (`MACOSX_DEPLOYMENT_TARGET`) from `14.0` to `13.0` across the main application target, the helper CLI (WhiskyCmd), and the thumbnail extension.
* **Swift Package Updates**: Updated the platform specification in `WhiskyKit/Package.swift` to support `.macOS(.v13)`.
* **Runtime Architecture Detection**: Added a helper architecture detection utility `SystemArchitecture` in `Whisky/Utils/Constants.swift` to check the executing architecture.

## Known Limitations

Because core features of the Game Porting Toolkit and D3DMetal are designed for Apple Silicon, there are several limitations when running this application on an Intel Mac:

1. **cabextract Binary**: The bundled version of `cabextract` in `Libraries/cabextract` is an ARM64-only binary. Features in Winetricks that depend on `cabextract` will fail on Intel Macs unless you install an Intel-compatible version manually (such as through Homebrew using `brew install cabextract`). Note: this has already been done for you. 
2. **D3DMetal Support**: Apple's `D3DMetal` API translator is optimized for Apple Silicon GPUs. On Intel Macs, you will need to rely on alternative translation layers like DXVK, and performance will be significantly degraded.
3. **Experimental Compatibility**: Intel support is experimental. While basic application installation and launching have been tested, compatibility and performance vary significantly.

| Feature | Intel Mac | Apple Silicon |
| --- | --- | --- |
| App Launch | Expected | Verified |
| Bottle Creation | Expected | Verified |
| Windows Applications | Limited | Full |
| Winetricks | Limited (Requires Homebrew cabextract) | Full |
| D3DMetal | Limited / Not Available | Full |

## Building the Project

### Using Xcode
1. Open `Whisky.xcodeproj` in Xcode.
2. Select the `Whisky` scheme.
3. Choose your build destination.
4. Press `Cmd + R` to build and run.

### Using the Command Line
To build a Universal Binary from the command line, run:
```bash
xcodebuild -project Whisky.xcodeproj \
  -scheme Whisky \
  -configuration Release \
  -arch x86_64 -arch arm64 \
  build
```

## Credits and Acknowledgments

This project is a fork of the original [Whisky](https://github.com/IsaacMarovitz/Whisky) created by IsaacMarovitz. It utilizes the following open-source projects:

* [CrossOver](https://www.codeweavers.com/crossover) by CodeWeavers
* [msync](https://github.com/marzent/wine-msync) by marzent
* [DXVK-macOS](https://github.com/Gcenx/DXVK-macOS) by Gcenx and doitsujin
* [MoltenVK](https://github.com/KhronosGroup/MoltenVK) by KhronosGroup

Licensed under the GPL-3.0 License.

