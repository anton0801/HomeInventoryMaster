import SwiftUI

struct WarrantiesView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var selectedFilter: WarrantyFilter = .all
    
    enum WarrantyFilter: String, CaseIterable {
        case all = "All"
        case expiring = "Expiring Soon"
        case expired = "Expired"
        case lifetime = "Lifetime"
    }
    
    var filteredItems: [Item] {
        let itemsWithWarranty = coreDataManager.items.filter { 
            $0.warrantyEndDate != nil || $0.isLifetimeWarranty 
        }
        
        switch selectedFilter {
        case .all:
            return itemsWithWarranty
        case .expiring:
            return itemsWithWarranty.filter { 
                if let date = $0.warrantyEndDate {
                    let days = date.daysUntil()
                    return days >= 0 && days <= 90
                }
                return false
            }
        case .expired:
            return itemsWithWarranty.filter { 
                if let date = $0.warrantyEndDate {
                    return date.daysUntil() < 0
                }
                return false
            }
        case .lifetime:
            return itemsWithWarranty.filter { $0.isLifetimeWarranty }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter picker
                    filterSection
                    
                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            VStack(spacing: Theme.Spacing.md) {
                                ForEach(filteredItems.sorted(by: { 
                                    warrantyPriority($0) > warrantyPriority($1) 
                                })) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        WarrantyItemCard(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Warranties")
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(WarrantyFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Theme.Colors.cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No Warranties Found")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Add warranty information to your items")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func warrantyPriority(_ item: Item) -> Int {
        if item.isLifetimeWarranty { return 0 }
        
        guard let warrantyDate = item.warrantyEndDate else { return -1 }
        
        let days = warrantyDate.daysUntil()
        if days < 0 { return -2 }
        if days <= 30 { return 1000 - days }
        if days <= 90 { return 500 - days }
        return days
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? 
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accentLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : 
                    LinearGradient(
                        colors: [Theme.Colors.background, Theme.Colors.background],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: isSelected ? Theme.Colors.accent.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
        }
    }
}

struct WarrantyItemCard: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status indicator
            VStack {
                Image(systemName: item.warrantyStatus.icon)
                    .font(.system(size: 24))
                    .foregroundColor(item.warrantyStatus.color)
                
                if !item.isLifetimeWarranty, let warrantyDate = item.warrantyEndDate {
                    let days = warrantyDate.daysUntil()
                    if days >= 0 {
                        Text("\(days)d")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(item.warrantyStatus.color)
                    }
                }
            }
            .frame(width: 50)
            
            // Item info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(Theme.Fonts.headline(size: 17))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                if item.isLifetimeWarranty {
                    HStack(spacing: 4) {
                        Image(systemName: "infinity")
                            .font(.system(size: 11))
                        Text("Lifetime Warranty")
                            .font(Theme.Fonts.caption(size: 12))
                    }
                    .foregroundColor(Theme.Colors.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.gold.opacity(0.1))
                    .cornerRadius(6)
                } else if let warrantyDate = item.warrantyEndDate {
                    Text("Expires: \(warrantyDate.toString())")
                        .font(Theme.Fonts.caption(size: 12))
                        .foregroundColor(item.warrantyStatus.color)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .cardStyle()
    }
}
