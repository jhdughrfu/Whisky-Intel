//
//  RuntimeInstallerView.swift
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

import SwiftUI
import WhiskyKit

/// One-click runtime installer for maximum Windows app compatibility
struct RuntimeInstallerView: View {
    let bottle: Bottle
    @Environment(\.dismiss) var dismiss
    @State private var installingRuntime: String?
    @State private var installedRuntimes: Set<String> = []
    @State private var installLog: String = ""
    @State private var showLog: Bool = false
    @State private var installAllMode: Bool = false
    @State private var allInstallProgress: Int = 0
    @State private var allInstallTotal: Int = 0

    struct RuntimePack: Identifiable {
        let id: String
        let name: String
        let icon: String
        let description: String
        let winetricksVerbs: [String]
        let category: Category

        enum Category: String, CaseIterable {
            case essential = "Essential"
            case directx = "DirectX & Graphics"
            case dotnet = ".NET Framework"
            case vcredist = "Visual C++"
            case fonts = "Fonts"
            case extras = "Extras"
        }
    }

    let runtimePacks: [RuntimePack] = [
        // Essential
        RuntimePack(
            id: "essentials", name: "⚡ Essential Pack",
            icon: "bolt.fill",
            description: "All-in-one: VCRedist 2015-2022, .NET 4.8, DirectX, corefonts",
            winetricksVerbs: ["vcrun2022", "dotnet48", "d3dx9", "corefonts", "dxvk"],
            category: .essential
        ),

        // DirectX
        RuntimePack(
            id: "d3dx9", name: "DirectX 9",
            icon: "cube.fill",
            description: "Direct3D 9 libraries — required by most older games",
            winetricksVerbs: ["d3dx9"],
            category: .directx
        ),
        RuntimePack(
            id: "d3dx10", name: "DirectX 10",
            icon: "cube.fill",
            description: "Direct3D 10 libraries",
            winetricksVerbs: ["d3dx10"],
            category: .directx
        ),
        RuntimePack(
            id: "d3dx11_43", name: "DirectX 11",
            icon: "cube.fill",
            description: "Direct3D 11 libraries",
            winetricksVerbs: ["d3dx11_43"],
            category: .directx
        ),
        RuntimePack(
            id: "dxvk", name: "DXVK",
            icon: "paintbrush.pointed.fill",
            description: "Translates DirectX 9/10/11 → Vulkan → Metal for better performance",
            winetricksVerbs: ["dxvk"],
            category: .directx
        ),

        // .NET
        RuntimePack(
            id: "dotnet40", name: ".NET 4.0",
            icon: "circle.hexagongrid.fill",
            description: "Microsoft .NET Framework 4.0",
            winetricksVerbs: ["dotnet40"],
            category: .dotnet
        ),
        RuntimePack(
            id: "dotnet48", name: ".NET 4.8",
            icon: "circle.hexagongrid.fill",
            description: "Microsoft .NET Framework 4.8 — covers most modern .NET apps",
            winetricksVerbs: ["dotnet48"],
            category: .dotnet
        ),
        RuntimePack(
            id: "dotnet35sp1", name: ".NET 3.5 SP1",
            icon: "circle.hexagongrid.fill",
            description: "Microsoft .NET Framework 3.5 SP1 — for older apps",
            winetricksVerbs: ["dotnet35sp1"],
            category: .dotnet
        ),

        // VC Redist
        RuntimePack(
            id: "vcrun2019", name: "VC++ 2015-2019",
            icon: "gearshape.2.fill",
            description: "Visual C++ 2015-2019 Redistributable",
            winetricksVerbs: ["vcrun2019"],
            category: .vcredist
        ),
        RuntimePack(
            id: "vcrun2022", name: "VC++ 2015-2022",
            icon: "gearshape.2.fill",
            description: "Visual C++ 2015-2022 Redistributable (latest)",
            winetricksVerbs: ["vcrun2022"],
            category: .vcredist
        ),
        RuntimePack(
            id: "vcrun2010", name: "VC++ 2010",
            icon: "gearshape.2.fill",
            description: "Visual C++ 2010 Redistributable",
            winetricksVerbs: ["vcrun2010"],
            category: .vcredist
        ),
        RuntimePack(
            id: "vcrun6sp6", name: "VC++ 6 SP6",
            icon: "gearshape.2.fill",
            description: "Visual C++ 6 SP6 — for very old apps",
            winetricksVerbs: ["vcrun6sp6"],
            category: .vcredist
        ),

        // Fonts
        RuntimePack(
            id: "corefonts", name: "Core Fonts",
            icon: "textformat",
            description: "Microsoft core fonts (Arial, Times New Roman, etc.)",
            winetricksVerbs: ["corefonts"],
            category: .fonts
        ),
        RuntimePack(
            id: "tahoma", name: "Tahoma Font",
            icon: "textformat",
            description: "Tahoma font — fixes many UI rendering issues",
            winetricksVerbs: ["tahoma"],
            category: .fonts
        ),

        // Extras
        RuntimePack(
            id: "mf", name: "Media Foundation",
            icon: "play.rectangle.fill",
            description: "Windows Media Foundation — for video playback in games",
            winetricksVerbs: ["mf"],
            category: .extras
        ),
        RuntimePack(
            id: "quartz", name: "Quartz (DirectShow)",
            icon: "film",
            description: "quartz.dll — DirectShow video/audio support",
            winetricksVerbs: ["quartz"],
            category: .extras
        ),
        RuntimePack(
            id: "xact", name: "XACT Audio",
            icon: "speaker.wave.3.fill",
            description: "Microsoft XACT audio engine — used by many games",
            winetricksVerbs: ["xact"],
            category: .extras
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("🛠 Runtime Installer")
                        .font(.title2.bold())
                    Text("Install Windows components for maximum app compatibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { installAllEssentials() }) {
                    Label("Install Essentials", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(installingRuntime != nil)
                .help("Installs VC++ 2022, .NET 4.8, DirectX 9, core fonts, and DXVK")

                Button("Done") { dismiss() }
            }
            .padding()

            Divider()

            if installAllMode {
                VStack(spacing: 12) {
                    Text("Installing essential runtimes...")
                        .font(.headline)
                    ProgressView(value: Double(allInstallProgress), total: Double(allInstallTotal))
                        .padding(.horizontal)
                    Text(installingRuntime ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            // Runtime list by category
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(RuntimePack.Category.allCases, id: \.rawValue) { category in
                        let packs = runtimePacks.filter { $0.category == category }
                        if !packs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.rawValue)
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(packs) { pack in
                                    runtimeRow(pack)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            // Log area
            if showLog {
                Divider()
                VStack(alignment: .leading) {
                    HStack {
                        Text("Installation Log")
                            .font(.caption.bold())
                        Spacer()
                        Button("Clear") { installLog = "" }
                            .font(.caption)
                    }
                    ScrollView {
                        Text(installLog)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 600, height: 550)
    }

    @ViewBuilder
    func runtimeRow(_ pack: RuntimePack) -> some View {
        HStack {
            Image(systemName: pack.icon)
                .font(.title3)
                .foregroundColor(
                    installedRuntimes.contains(pack.id) ? .green :
                    pack.category == .essential ? .orange : .blue
                )
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(pack.name)
                    .font(.body.bold())
                Text(pack.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if installingRuntime == pack.id {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 8)
            } else if installedRuntimes.contains(pack.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Install") {
                    installRuntime(pack)
                }
                .disabled(installingRuntime != nil)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    func installRuntime(_ pack: RuntimePack) {
        installingRuntime = pack.id
        let verbs = pack.winetricksVerbs.joined(separator: " ")
        Task {
            await Winetricks.runCommand(command: verbs, bottle: bottle)
            await MainActor.run {
                installedRuntimes.insert(pack.id)
                installingRuntime = nil
            }
        }
    }

    func installAllEssentials() {
        guard let essentials = runtimePacks.first(where: { $0.id == "essentials" }) else { return }
        installAllMode = true
        allInstallTotal = essentials.winetricksVerbs.count
        allInstallProgress = 0

        Task {
            for verb in essentials.winetricksVerbs {
                await MainActor.run {
                    installingRuntime = verb
                }
                await Winetricks.runCommand(command: verb, bottle: bottle)
                await MainActor.run {
                    allInstallProgress += 1
                }
            }
            await MainActor.run {
                installedRuntimes.insert("essentials")
                installingRuntime = nil
                installAllMode = false
            }
        }
    }
}
