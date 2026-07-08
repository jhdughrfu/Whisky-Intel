//
//  BottleListEntry.swift
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
import UniformTypeIdentifiers

struct BottleListEntry: View {
    let bottle: Bottle
    @Binding var selected: URL?
    @Binding var refresh: Bool

    @State private var showBottleRename: Bool = false
    @State private var name: String = ""

    var body: some View {
        Text(name)
            .opacity(bottle.isAvailable ? 1.0 : 0.5)
            .onAppear {
                name = bottle.settings.name
            }
            .onChange(of: refresh) { _ in
                name = bottle.settings.name
            }
            .sheet(isPresented: $showBottleRename) {
                RenameView("rename.bottle.title", name: name) { newName in
                    name = newName
                    bottle.rename(newName: newName)
                }
            }
            .contextMenu {
                Button(action: {
                    showBottleRename.toggle()
                }, label: { Label("button.rename", systemImage: "pencil.line") })
                .disabled(!bottle.isAvailable)
                .labelStyle(.titleAndIcon)
                Button(action: {
                    showRemoveAlert(bottle: bottle)
                }, label: { Label("button.removeAlert", systemImage: "trash") })
                .labelStyle(.titleAndIcon)
                Divider()
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = true
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                let newBottePath = url
                                    .appending(path: bottle.url.lastPathComponent)

                                bottle.move(destination: newBottePath)
                                selected = newBottePath
                            }
                        }
                    }
                }, label: { Label("button.moveBottle", systemImage: "shippingbox.and.arrow.backward") })
                .disabled(!bottle.isAvailable)
                .labelStyle(.titleAndIcon)
                Button(action: {
                    let panel = NSSavePanel()
                    panel.canCreateDirectories = true
                    panel.allowedContentTypes = [UTType.gzip]
                    panel.allowsOtherFileTypes = false
                    panel.isExtensionHidden = false
                    panel.nameFieldStringValue = bottle.settings.name + ".tar"
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.url {
                                Task.detached(priority: .background) {
                                    bottle.exportAsArchive(destination: url)
                                }
                            }
                        }
                    }
                }, label: { Label("button.exportBottle", systemImage: "arrowshape.turn.up.right") })
                .disabled(!bottle.isAvailable)
                .labelStyle(.titleAndIcon)
                Divider()
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([bottle.url])
                }, label: { Label("button.showInFinder", systemImage: "folder") })
                .disabled(!bottle.isAvailable)
                .labelStyle(.titleAndIcon)
            }
    }

    func showRemoveAlert(bottle: Bottle) {
        let checkbox = NSButton(checkboxWithTitle: String(localized: "button.removeAlert.checkbox"),
                                target: self, action: nil)
        let alert = NSAlert()
        alert.messageText = String(format: String(localized: "button.removeAlert.msg"),
                                   bottle.settings.name)
        alert.informativeText = String(localized: "button.removeAlert.info")
        alert.alertStyle = .warning
        let delete = alert.addButton(withTitle: String(localized: "button.removeAlert.delete"))
        delete.hasDestructiveAction = true
        alert.addButton(withTitle: String(localized: "button.removeAlert.cancel"))
        if bottle.isAvailable {
            alert.accessoryView = checkbox
        }

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            Task(priority: .userInitiated) {
                if selected == bottle.url {
                    selected = nil
                }

                await bottle.remove(delete: checkbox.state == .on)
            }
        }
    }
}

struct BottleListEntryPreviews: PreviewProvider {
    static var previews: some View {
        BottleListEntry(
            bottle: Bottle(bottleUrl: URL(filePath: "")),
            selected: .constant(nil),
            refresh: .constant(false)
        )
    }
}
