import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showAddItem: Bool
    
    private let tabs: [(icon: String, title: String)] = [
        ("house.fill", "Home"),
        ("square.grid.2x2.fill", "Rooms"),
        ("", ""),
        ("checkmark.shield.fill", "Warranty"),
        ("magnifyingglass", "Search")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                if index == 2 {
                    // Center Add Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showAddItem = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.accent, Theme.Colors.accentLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 15, x: 0, y: 5)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -20)
                    .frame(maxWidth: .infinity)
                } else {
                    TabBarButton(
                        icon: tabs[index].icon,
                        title: tabs[index].title,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.textSecondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.textSecondary)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}
