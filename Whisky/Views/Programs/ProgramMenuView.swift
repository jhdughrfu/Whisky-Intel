//
//  ProgramMenuView.swift
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

struct ProgramMenuView: View {
    @ObservedObject var program: Program
    @Binding var path: NavigationPath

    var body: some View {
        Button(action: {
            program.run()
        }, label: { Label("button.run", systemImage: "play") })
        .labelStyle(.titleAndIcon)
        Section("program.settings") {
            Button(action: {
                path.append(program)
            }, label: { Label("program.config", systemImage: "gearshape") })
            .labelStyle(.titleAndIcon)

            let buttonName = program.pinned
            ? String(localized: "button.unpin")
            : String(localized: "button.pin")

            Button(action: {
                program.pinned.toggle()
            }, label: { Label(buttonName, systemImage: "pin") })
            .labelStyle(.titleAndIcon)
            .symbolVariant(program.pinned ? .slash : .none)
        }
    }
}
