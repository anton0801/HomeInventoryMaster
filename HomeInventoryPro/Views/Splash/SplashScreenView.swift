import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var particlesAnimation = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var showContent = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background with animation
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.Colors.primaryDark,
                    Theme.Colors.primary,
                    Theme.Colors.accent
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(isAnimating ? 10 : 0))
            .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            
            // Animated particles
            ParticleSystemView(isAnimating: $particlesAnimation)
            
            // Concentric rings
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Theme.Colors.gold.opacity(0.3), lineWidth: 2)
                        .frame(width: 200 + CGFloat(index * 60), height: 200 + CGFloat(index * 60))
                        .rotationEffect(.degrees(ringRotation + Double(index * 120)))
                }
            }
            .opacity(logoOpacity)
            
            VStack(spacing: 20) {
                // Logo with house icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Theme.Colors.accent.opacity(0.6),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                    
                    // House icon
                    Image(systemName: "house.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.gold, Theme.Colors.goldLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Theme.Colors.gold.opacity(0.5), radius: 20, x: 0, y: 10)
                        .rotation3DEffect(
                            .degrees(isAnimating ? 360 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name
                VStack(spacing: 8) {
                    Text("Home Inventory")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("PRO")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.Colors.gold)
                        .tracking(8)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Initial state
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Particle system
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            particlesAnimation = true
        }
        
        // Rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        
        // House rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 2)) {
                isAnimating = true
            }
        }
        
        // Show text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
        
        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                logoOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Particle System
struct ParticleSystemView: View {
    @Binding var isAnimating: Bool
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        }
        .onAppear {
            if isAnimating {
                generateParticles()
            }
        }
        .onChange(of: isAnimating) { value in
            if value {
                generateParticles()
            }
        }
    }
    
    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<30 {
            let particle = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 2...6),
                color: [Theme.Colors.gold, Theme.Colors.accent, Color.white].randomElement()!.opacity(0.6),
                opacity: Double.random(in: 0.3...0.8),
                blur: CGFloat.random(in: 0...3)
            )
            particles.append(particle)
            animateParticle(particle)
        }
    }
    
    private func animateParticle(_ particle: Particle) {
        let animation = Animation
            .linear(duration: Double.random(in: 3...6))
            .repeatForever(autoreverses: false)
        
        withAnimation(animation) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var blur: CGFloat
}
