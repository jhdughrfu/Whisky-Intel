//
//  Winetricks.swift
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
import AppKit
import WhiskyKit

enum WinetricksCategories: String {
    case apps
    case benchmarks
    case dlls
    case fonts
    case games
    case settings
}

struct WinetricksVerb: Identifiable {
    var id = UUID()

    var name: String
    var description: String
}

struct WinetricksCategory {
    var category: WinetricksCategories
    var verbs: [WinetricksVerb]
}

class Winetricks {
    static var winetricksURL: URL {
        return firstRunnableExecutable(named: "winetricks", in: winetricksSearchFolders)
            ?? WhiskyWineInstaller.libraryFolder.appending(path: "winetricks")
    }

    static func runCommand(command: String, bottle: Bottle) async {
        let pathPrefix = ([Wine.wineBinFolder.path] + cabextractPathEntries)
            .filter { !$0.isEmpty }
            .joined(separator: ":")
        let pathAssignment: String
        if pathPrefix.isEmpty {
            pathAssignment = "PATH=\"$PATH\""
        } else {
            pathAssignment = "PATH=\(shellQuoted(pathPrefix + ":"))$PATH"
        }
        let winetricksCmd = [
            pathAssignment,
            "WINE=\(shellQuoted(Wine.wineBinary.path))",
            "WINEPREFIX=\(shellQuoted(bottle.url.path))",
            shellQuoted(winetricksURL.path(percentEncoded: false)),
            command
        ].joined(separator: " ")

        let script = """
        tell application "Terminal"
            activate
            do script "\(appleScriptEscaped(winetricksCmd))"
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)

            if let error = error {
                print(error)
                if let description = error["NSAppleScriptErrorMessage"] as? String {
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = String(localized: "alert.message")
                        alert.informativeText = String(localized: "alert.info")
                            + " \(command): "
                            + description
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: String(localized: "button.ok"))
                        alert.runModal()
                    }
                }
            }
        }
    }

    private static var winetricksSearchFolders: [URL] {
        var folders: [URL] = [
            WhiskyWineInstaller.libraryFolder,
            WhiskyWineInstaller.binFolder,
            URL(fileURLWithPath: "/usr/local/bin"),
            URL(fileURLWithPath: "/opt/homebrew/bin")
        ]

        if let resourceURL = Bundle.main.resourceURL {
            folders.append(resourceURL.appending(path: "Wine"))
            folders.append(resourceURL.appending(path: "Wine/bin"))
        }

        if let path = ProcessInfo.processInfo.environment["PATH"] {
            folders.append(contentsOf: path.split(separator: ":").map { URL(fileURLWithPath: String($0)) })
        }

        return uniqueFolders(folders)
    }

    private static var cabextractPathEntries: [String] {
        var folders: [URL] = [
            URL(fileURLWithPath: "/usr/local/bin"),
            URL(fileURLWithPath: "/opt/homebrew/bin")
        ]

        if let resourceURL = Bundle.main.resourceURL {
            folders.append(resourceURL)
            folders.append(resourceURL.appending(path: "Wine"))
            folders.append(resourceURL.appending(path: "Wine/bin"))
        }

        if let executableFolder = Bundle.main.executableURL?.deletingLastPathComponent() {
            folders.append(executableFolder)
        }

        if let path = ProcessInfo.processInfo.environment["PATH"] {
            folders.append(contentsOf: path.split(separator: ":").map { URL(fileURLWithPath: String($0)) })
        }

        return uniqueFolders(folders).compactMap { folder -> String? in
            let cabextract = folder.appending(path: "cabextract")
            return Wine.isRunnableExecutable(at: cabextract) ? folder.path(percentEncoded: false) : nil
        }
    }

    private static func firstRunnableExecutable(named name: String, in folders: [URL]) -> URL? {
        for folder in folders {
            let executable = folder.appending(path: name)
            if Wine.isRunnableExecutable(at: executable) {
                return executable
            }
        }

        return nil
    }

    private static func uniqueFolders(_ folders: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        return folders.filter { folder in
            seenPaths.insert(folder.standardizedFileURL.path).inserted
        }
    }

    private static func shellQuoted(_ value: String) -> String {
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    static func parseVerbs() async -> [WinetricksCategory] {
        // Grab the verbs file
        let verbsURL = WhiskyWineInstaller.libraryFolder.appending(path: "verbs.txt")
        let verbs: String = await { () async -> String in
            do {
                let (data, _) = try await URLSession.shared.data(from: verbsURL)
                return String(data: data, encoding: .utf8) ?? String()
            } catch {
                return String()
            }
        }()

        // Read the file line by line
        let lines = verbs.components(separatedBy: "\n")
        var categories: [WinetricksCategory] = []
        var currentCategory: WinetricksCategory?

        for line in lines {
            // Categories are label as "===== <name> ====="
            if line.starts(with: "=====") {
                // If we have a current category, add it to the list
                if let currentCategory = currentCategory {
                    categories.append(currentCategory)
                }

                // Create a new category
                // Capitalize the first letter of the category name
                let categoryName = line.replacingOccurrences(of: "=====", with: "").trimmingCharacters(in: .whitespaces)
                if let cateogry = WinetricksCategories(rawValue: categoryName) {
                    currentCategory = WinetricksCategory(category: cateogry,
                                                         verbs: [])
                } else {
                    currentCategory = nil
                }
            } else {
                guard currentCategory != nil else {
                    continue
                }

                // If we have a current category, add the verb to it
                // Verbs eg. "3m_library               3M Cloud Library (3M Company, 2015) [downloadable]"
                let verbName = line.components(separatedBy: " ")[0]
                let verbDescription = line.replacingOccurrences(of: "\(verbName) ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentCategory?.verbs.append(WinetricksVerb(name: verbName, description: verbDescription))
            }
        }

        // Add the last category
        if let currentCategory = currentCategory {
            categories.append(currentCategory)
        }

        return categories
    }
}
