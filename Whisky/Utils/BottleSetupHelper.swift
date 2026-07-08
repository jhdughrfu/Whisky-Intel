//
//  BottleSetupHelper.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation
import WhiskyKit

/// Configures a Wine bottle for maximum Windows app compatibility
class BottleSetupHelper {
    /// Apply all compatibility tweaks to a bottle
    static func applyMaxCompat(bottle: Bottle) async throws {
        // 1. Set Windows version to Windows 10 for best compat
        bottle.settings.windowsVersion = .win10

        // 2. Apply Wine registry tweaks for compatibility
        try await applyRegistryTweaks(bottle: bottle)
    }

    /// Apply registry tweaks that improve compatibility
    static func applyRegistryTweaks(bottle: Bottle) async throws {
        let regFile = bottle.url.appending(path: "compat_tweaks.reg")

        let regContent = """
        Windows Registry Editor Version 5.00

        ; ---- DLL Overrides for maximum compatibility ----
        [HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
        "mscoree"="native,builtin"
        "mshtml"="native,builtin"
        "winemenubuilder.exe"=""
        "dwrite"="native,builtin"
        "d3dcompiler_47"="native,builtin"
        "d3d11"="native,builtin"
        "dxgi"="native,builtin"
        "d3d10core"="native,builtin"
        "d3d10"="native,builtin"
        "d3d9"="native,builtin"

        ; ---- Desktop Integration ----
        [HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
        "winemenubuilder.exe"=""

        ; ---- GPU Shader Model support ----
        [HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
        "MaxShaderModelVS"=dword:00000003
        "MaxShaderModelPS"=dword:00000003
        "MaxShaderModelGS"=dword:00000003
        "UseGLSL"="enabled"
        "OffscreenRenderingMode"="fbo"
        "StrictDrawOrdering"="disabled"
        "RenderTargetLockMode"="auto"
        "VideoMemorySize"="2048"

        ; ---- Font smoothing (ClearType) ----
        [HKEY_CURRENT_USER\\Control Panel\\Desktop]
        "FontSmoothing"="2"
        "FontSmoothingType"=dword:00000002
        "FontSmoothingGamma"=dword:00000578
        "FontSmoothingOrientation"=dword:00000001

        ; ---- Sound settings ----
        [HKEY_CURRENT_USER\\Software\\Wine\\DirectSound]
        "HelBuflen"="16384"
        "SndQueueMax"="28"

        ; ---- Disable crash dialogs (just log them) ----
        [HKEY_CURRENT_USER\\Software\\Wine\\WineDbg]
        "ShowCrashDialog"=dword:00000000

        ; ---- Explorer desktop mode off (use native macOS windows) ----
        [HKEY_CURRENT_USER\\Software\\Wine\\Explorer\\Desktops]

        ; ---- Internet Explorer version spoof for web-based apps ----
        [HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer]
        "Version"="11.0.19041.1"
        "svcVersion"="11.0.19041.1"

        ; ---- .NET optimization ----
        [HKEY_LOCAL_MACHINE\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full]
        "Release"=dword:000805F4

        """

        try regContent.write(to: regFile, atomically: true, encoding: .utf8)

        // Import the reg file using Wine's regedit
        for await _ in try Wine.runWineProcess(
            name: "regedit",
            args: ["regedit", regFile.path(percentEncoded: false)],
            bottle: bottle,
            environment: [:]
        ) { }

        // Clean up
        try? FileManager.default.removeItem(at: regFile)
    }

    /// Install Wine Mono and Gecko if not present (for .NET and HTML support)
    static func ensureMonoAndGecko(bottle: Bottle) async {
        let cDrive = bottle.url.appending(path: "drive_c")
        let monoDir = cDrive.appending(path: "windows/mono")
        let geckoDir = cDrive.appending(path: "windows/system32/gecko")

        // Wine usually auto-installs Mono and Gecko on first wineboot
        // if the files are available in the share directory.
        // We trigger a wineboot to ensure they're set up.
        if !FileManager.default.fileExists(atPath: monoDir.path) ||
            !FileManager.default.fileExists(atPath: geckoDir.path) {
            do {
                // wineboot initializes the prefix and installs Mono/Gecko
                try await Wine.wineboot(bottle: bottle)
            } catch {
                print("Error during wineboot for Mono/Gecko: \(error)")
            }
        }
    }
}

/// Extension on Wine to expose a process runner for registry imports
extension Wine {
    static func runWineProcess(
        name: String, args: [String], bottle: Bottle, environment: [String: String]
    ) throws -> AsyncThrowingStream<ProcessOutput, Error> {
        let wineBin = wineBinary
        let env = constructWineEnvironment(for: bottle, environment: environment)

        let process = Process()
        let fileHandle = try makeFileHandle()

        process.executableURL = wineBin
        process.arguments = args
        process.environment = env
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return AsyncThrowingStream { continuation in
            process.terminationHandler = { process in
                try? fileHandle.close()
                continuation.yield(.terminated(Int(process.terminationStatus)))
                continuation.finish()
            }

            do {
                try process.run()
                continuation.yield(.started)
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
