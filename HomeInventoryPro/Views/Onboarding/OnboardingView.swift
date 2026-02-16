import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showGetStarted = false
    var onComplete: () -> Void
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background gradient changes per page
            LinearGradient(
                gradient: Gradient(colors: pages[currentPage].backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Page content with parallax
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], currentIndex: currentPage, pageIndex: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 600)
                
                Spacer()
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Theme.Colors.gold : Color.white.opacity(0.4))
                            .frame(width: currentPage == index ? 30 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Get Started button (last page)
                if currentPage == pages.count - 1 {
                    Button(action: {
                        completeOnboarding()
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Theme.Colors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Theme.Colors.gold, Theme.Colors.goldLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Theme.Colors.gold.opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.scale.combined(with: .opacity))
                    .scaleEffect(showGetStarted ? 1 : 0.8)
                    .opacity(showGetStarted ? 1 : 0)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            showGetStarted = true
                        }
                    }
                } else {
                    Color.clear.frame(height: 106)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            onComplete()
        }
    }
}

// MARK: - Individual Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let currentIndex: Int
    let pageIndex: Int
    
    @State private var imageOffset: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.5
    
    var parallaxOffset: CGFloat {
        let diff = CGFloat(currentIndex - pageIndex)
        return diff * 50
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // Animated icon/illustration
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                page.iconColor.opacity(0.3),
                                page.iconColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 20)
                    .scaleEffect(iconScale)
                
                // Icon
                Image(systemName: page.iconName)
                    .font(.system(size: 120, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.iconColor, page.iconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: page.iconColor.opacity(0.3), radius: 30, x: 0, y: 15)
                    .scaleEffect(iconScale)
                    .rotation3DEffect(
                        .degrees(Double(parallaxOffset) * 0.1),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .offset(y: parallaxOffset * 0.3)
            
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .opacity(textOpacity)
                    .offset(y: textOpacity == 1 ? 0 : 20)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
                    .offset(y: textOpacity == 1 ? 0 : 20)
            }
            .offset(y: parallaxOffset * 0.2)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
        }
        .onChange(of: currentIndex) { _ in
            if currentIndex == pageIndex {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    iconScale = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    textOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let backgroundColors: [Color]
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Organize Everything",
            description: "Keep track of all your belongings in one place. Add items with photos, details, and receipts.",
            iconName: "square.grid.3x3.fill",
            iconColor: Theme.Colors.gold,
            backgroundColors: [Theme.Colors.primaryDark, Theme.Colors.primary]
        ),
        OnboardingPage(
            title: "Track Warranties",
            description: "Never miss a warranty deadline. Get timely notifications before your warranties expire.",
            iconName: "checkmark.shield.fill",
            iconColor: Theme.Colors.accent,
            backgroundColors: [Theme.Colors.primary, Theme.Colors.accent.opacity(0.8)]
        ),
        OnboardingPage(
            title: "Schedule Maintenance",
            description: "Set up recurring maintenance tasks and keep your items in perfect condition.",
            iconName: "calendar.badge.clock",
            iconColor: Color(hex: "2D6A4F"),
            backgroundColors: [Theme.Colors.accent.opacity(0.7), Color(hex: "2D6A4F")]
        ),
        OnboardingPage(
            title: "Generate Reports",
            description: "Create professional PDF reports for insurance claims or moving. Export your inventory anytime.",
            iconName: "doc.text.fill",
            iconColor: Theme.Colors.goldLight,
            backgroundColors: [Color(hex: "2D6A4F"), Theme.Colors.primaryDark]
        ),
        OnboardingPage(
            title: "Sync Across Devices",
            description: "Your inventory syncs seamlessly across all your devices with iCloud.",
            iconName: "icloud.fill",
            iconColor: Color.white,
            backgroundColors: [Theme.Colors.primaryDark, Theme.Colors.primary]
        )
    ]
}
