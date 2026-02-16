import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab = 0
    @State private var showAddItem = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(showAddItem: $showAddItem)
                    .tag(0)
                
                RoomsView()
                    .tag(1)
                
                WarrantiesView()
                    .tag(2)
                
                MaintenanceView()
                    .tag(3)
                
                SearchView()
                    .tag(4)
            }
            
            CustomTabBar(selectedTab: $selectedTab, showAddItem: $showAddItem)
                .padding(.horizontal)
                .padding(.bottom, 10)
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @Binding var showAddItem: Bool
    @State private var showStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header with stats
                        headerSection
                        
                        // Quick stats cards
                        statsSection
                        
                        // Recent items
                        recentItemsSection
                        
                        // Quick actions
                        quickActionsSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Dashboard")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showStats = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Welcome back")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
            
            Text("Your Home Inventory")
                .font(Theme.Fonts.title(size: 32))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var statsSection: some View {
        VStack {
            HStack(spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Total Items",
                    value: "\(coreDataManager.items.count)",
                    icon: "cube.box.fill",
                    color: Theme.Colors.accent,
                    index: 0,
                    showStats: showStats
                )
                
                StatCard(
                    title: "Rooms",
                    value: "\(coreDataManager.rooms.count)",
                    icon: "house.fill",
                    color: Theme.Colors.gold,
                    index: 1,
                    showStats: showStats
                )
            }
            
            HStack(spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Warranties",
                    value: "\(warrantyCount)",
                    icon: "checkmark.shield.fill",
                    color: Theme.Colors.success,
                    index: 2,
                    showStats: showStats
                )
                
                StatCard(
                    title: "Value",
                    value: totalValue,
                    icon: "dollarsign.circle.fill",
                    color: Theme.Colors.warning,
                    index: 3,
                    showStats: showStats
                )
            }
        }
    }
    
    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Recent Items")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: SearchView()) {
                    Text("See All")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.accent)
                }
            }
            
            if coreDataManager.items.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(coreDataManager.items.prefix(5))) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.sm) {
                QuickActionButton(
                    title: "Add Item",
                    icon: "plus.circle.fill",
                    color: Theme.Colors.accent
                ) {
                    showAddItem = true
                }
                
                NavigationLink(destination: ReportGeneratorView()) {
                    QuickActionButton(
                        title: "Generate Report",
                        icon: "doc.text.fill",
                        color: Theme.Colors.gold
                    ) {}
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: WarrantiesView()) {
                    QuickActionButton(
                        title: "Check Warranties",
                        icon: "checkmark.shield.fill",
                        color: Theme.Colors.success
                    ) {}
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No Items Yet")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Start by adding your first item")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showAddItem = true }) {
                Text("Add Item")
            }
            .primaryButtonStyle()
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .cardStyle()
    }
    
    private var warrantyCount: Int {
        coreDataManager.items.filter { $0.warrantyEndDate != nil || $0.isLifetimeWarranty }.count
    }
    
    private var totalValue: String {
        let total = coreDataManager.items.reduce(0) { $0 + $1.purchasePrice }
        return total.toCurrency()
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let index: Int
    let showStats: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text(title)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .padding()
        .cardStyle()
        .scaleEffect(showStats ? 1 : 0.8)
        .opacity(showStats ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: showStats)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)
                
                Text(title)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding()
            .cardStyle()
        }
    }
}

// MARK: - Dashboard ViewModel
class DashboardViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var rooms: [Room] = []
}
