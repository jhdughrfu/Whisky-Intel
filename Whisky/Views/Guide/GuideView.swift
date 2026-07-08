//
//  GuideView.swift
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

struct GuideStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct GuideView: View {
    @Binding var showGuide: Bool
    @State private var currentStep = 0

    private let steps: [GuideStep] = [
        GuideStep(
            icon: "🍷",
            title: "Welcome to Whisky",
            description: "Whisky lets you run Windows apps and games on your Intel Mac using Wine.\n\nNo Windows installation required — just point it at an .exe and go!",
            color: .purple
        ),
        GuideStep(
            icon: "📦",
            title: "Create a Bottle",
            description: "A \"bottle\" is an isolated Windows environment.\n\nClick the + button in the top toolbar to create your first bottle. Each bottle has its own C: drive, settings, and installed programs.",
            color: .blue
        ),
        GuideStep(
            icon: "▶️",
            title: "Run Programs",
            description: "Once you have a bottle, click \"Run\" in the bottom bar to pick a .exe, .msi, or .bat file to run.\n\nInstalled programs will appear in the \"Installed Programs\" tab.",
            color: .green
        ),
        GuideStep(
            icon: "📌",
            title: "Pin Your Favorites",
            description: "Right-click any installed program and choose \"Pin\" to add it to the bottle's quick-launch area.\n\nPinned programs appear as shortcuts at the top of the bottle view.",
            color: .orange
        ),
        GuideStep(
            icon: "⚙️",
            title: "Configure & Tweak",
            description: "Each bottle has its own configuration:\n\n• Windows version (7, 10, 11)\n• Display resolution & Retina mode\n• DXVK & Metal HUD for debugging\n\nExplore the \"Bottle Configuration\" tab!",
            color: .red
        ),
        GuideStep(
            icon: "🎮",
            title: "You're Ready!",
            description: "That's everything you need to know.\n\nTip: Check the Help menu for a mini-game when you need a break! 🕹️\n\nHave fun gaming on your Mac!",
            color: .indigo
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button(action: { showGuide = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding()
            }

            Spacer()

            // Icon
            Text(steps[currentStep].icon)
                .font(.system(size: 64))
                .padding(.bottom, 8)

            // Title
            Text(steps[currentStep].title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 4)

            // Description
            Text(steps[currentStep].description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .frame(height: 140)

            Spacer()

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? steps[currentStep].color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)

            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .frame(width: 100, height: 36)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(width: 100, height: 36)
                        .background(steps[currentStep].color)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "hasSeenGuide")
                        showGuide = false
                    }) {
                        Text("Get Started!")
                            .frame(width: 140, height: 36)
                            .background(steps[currentStep].color)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .frame(width: 500, height: 450)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
        )
    }
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView(showGuide: .constant(true))
    }
}
