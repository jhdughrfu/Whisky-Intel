//
//  WinePongGame.swift
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

struct WinePongGame: View {
    @State private var ballPosition = CGPoint(x: 200, y: 200)
    @State private var ballVelocity = CGPoint(x: 3.5, y: -3.5)
    @State private var paddleX: CGFloat = 200
    @State private var score: Int = 0
    @State private var highScore: Int = UserDefaults.standard.integer(forKey: "winePongHighScore")
    @State private var gameOver = false
    @State private var gameStarted = false
    @State private var timer: Timer?
    @State private var bricks: [Brick] = []
    @State private var lives: Int = 3
    @State private var combo: Int = 0

    let gameWidth: CGFloat = 400
    let gameHeight: CGFloat = 500
    let paddleWidth: CGFloat = 80
    let paddleHeight: CGFloat = 12
    let ballRadius: CGFloat = 8
    let brickWidth: CGFloat = 50
    let brickHeight: CGFloat = 18

    struct Brick: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var alive: Bool = true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Score bar
            HStack {
                Text("🍷 Score: \(score)")
                    .font(.system(.headline, design: .monospaced))
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<lives, id: \.self) { _ in
                        Text("🍷")
                    }
                }
                Spacer()
                Text("Best: \(highScore)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Game area
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.85))

                // Bricks
                ForEach(bricks.filter { $0.alive }) { brick in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(brick.color)
                        .frame(width: brickWidth - 4, height: brickHeight - 4)
                        .position(x: brick.x, y: brick.y)
                }

                // Ball
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.red, .purple]),
                            center: .center,
                            startRadius: 0,
                            endRadius: ballRadius
                        )
                    )
                    .frame(width: ballRadius * 2, height: ballRadius * 2)
                    .position(ballPosition)
                    .shadow(color: .purple.opacity(0.5), radius: 4)

                // Paddle
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: paddleWidth, height: paddleHeight)
                    .position(x: paddleX, y: gameHeight - 30)
                    .shadow(color: .cyan.opacity(0.4), radius: 6)

                // Game over overlay
                if gameOver {
                    VStack(spacing: 16) {
                        Text("🍷 Game Over!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("Score: \(score)")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        if score >= highScore && score > 0 {
                            Text("🏆 New High Score!")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                        Button("Play Again") {
                            resetGame()
                            startGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                    )
                }

                // Start overlay
                if !gameStarted && !gameOver {
                    VStack(spacing: 16) {
                        Text("🕹️ Wine Pong")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Break the blocks with the ball!\nMove your mouse to control the paddle.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Button("Start Game") {
                            startGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                    )
                }
            }
            .frame(width: gameWidth, height: gameHeight)
            .clipped()
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    paddleX = min(max(location.x, paddleWidth / 2), gameWidth - paddleWidth / 2)
                case .ended:
                    break
                }
            }

            // Combo indicator
            if combo > 1 {
                Text("🔥 \(combo)x Combo!")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .frame(width: gameWidth + 20, height: gameHeight + 80)
        .onAppear {
            resetGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    func resetGame() {
        timer?.invalidate()
        ballPosition = CGPoint(x: gameWidth / 2, y: gameHeight - 60)
        ballVelocity = CGPoint(x: 3.5, y: -3.5)
        paddleX = gameWidth / 2
        score = 0
        lives = 3
        combo = 0
        gameOver = false
        gameStarted = false
        generateBricks()
    }

    func generateBricks() {
        bricks = []
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        let cols = Int(gameWidth / brickWidth)
        let rows = 5

        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * brickWidth + brickWidth / 2
                let y = CGFloat(row) * brickHeight + brickHeight / 2 + 30
                let color = colors[row % colors.count]
                bricks.append(Brick(x: x, y: y, color: color))
            }
        }
    }

    func startGame() {
        gameStarted = true
        gameOver = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            updateGame()
        }
    }

    func updateGame() {
        guard gameStarted && !gameOver else { return }

        // Move ball
        var newX = ballPosition.x + ballVelocity.x
        var newY = ballPosition.y + ballVelocity.y
        var velX = ballVelocity.x
        var velY = ballVelocity.y

        // Wall collisions
        if newX - ballRadius <= 0 || newX + ballRadius >= gameWidth {
            velX = -velX
            newX = max(ballRadius, min(newX, gameWidth - ballRadius))
        }
        if newY - ballRadius <= 0 {
            velY = -velY
            newY = max(ballRadius, newY)
        }

        // Paddle collision
        let paddleTop = gameHeight - 30 - paddleHeight / 2
        if newY + ballRadius >= paddleTop &&
            newY - ballRadius <= paddleTop + paddleHeight &&
            newX >= paddleX - paddleWidth / 2 &&
            newX <= paddleX + paddleWidth / 2 &&
            velY > 0 {

            velY = -abs(velY)
            // Add spin based on where ball hits paddle
            let hitPos = (newX - paddleX) / (paddleWidth / 2)
            velX = velX * 0.5 + hitPos * 4.0
            combo = 0

            // Slight speed increase
            let speed = sqrt(velX * velX + velY * velY)
            let maxSpeed: CGFloat = 7.0
            if speed < maxSpeed {
                velX *= 1.02
                velY *= 1.02
            }
        }

        // Ball fell below paddle
        if newY - ballRadius > gameHeight {
            lives -= 1
            combo = 0
            if lives <= 0 {
                gameOver = true
                timer?.invalidate()
                if score > highScore {
                    highScore = score
                    UserDefaults.standard.set(highScore, forKey: "winePongHighScore")
                }
                return
            } else {
                // Reset ball
                newX = gameWidth / 2
                newY = gameHeight - 60
                velX = 3.5 * (Bool.random() ? 1 : -1)
                velY = -3.5
            }
        }

        // Brick collisions
        var hitBrick = false
        for i in 0..<bricks.count {
            guard bricks[i].alive else { continue }
            let brick = bricks[i]

            if newX + ballRadius > brick.x - brickWidth / 2 &&
                newX - ballRadius < brick.x + brickWidth / 2 &&
                newY + ballRadius > brick.y - brickHeight / 2 &&
                newY - ballRadius < brick.y + brickHeight / 2 {

                bricks[i].alive = false
                combo += 1
                score += 10 * combo
                hitBrick = true

                // Determine bounce direction
                let overlapX = min(
                    abs(newX + ballRadius - (brick.x - brickWidth / 2)),
                    abs(newX - ballRadius - (brick.x + brickWidth / 2))
                )
                let overlapY = min(
                    abs(newY + ballRadius - (brick.y - brickHeight / 2)),
                    abs(newY - ballRadius - (brick.y + brickHeight / 2))
                )

                if overlapX < overlapY {
                    velX = -velX
                } else {
                    velY = -velY
                }
                break
            }
        }

        // Check win condition
        if bricks.allSatisfy({ !$0.alive }) {
            score += 100
            generateBricks()
            // Speed up slightly for next level
            velX *= 1.1
            velY *= 1.1
        }

        ballPosition = CGPoint(x: newX, y: newY)
        ballVelocity = CGPoint(x: velX, y: velY)
    }
}

struct WinePongGame_Previews: PreviewProvider {
    static var previews: some View {
        WinePongGame()
    }
}
