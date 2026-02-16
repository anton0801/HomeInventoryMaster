import SwiftUI

struct SearchView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var selectedRoom: Room?
    @State private var selectedCondition: ItemCondition?
    @State private var showFilters = false
    @State private var onlyWithPhotos = false
    @State private var onlyWithWarranty = false
    
    var filteredItems: [Item] {
        var items = coreDataManager.items
        
        // Text search
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand?.localizedCaseInsensitiveContains(searchText) == true ||
                item.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                item.serialNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Category filter
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Room filter
        if let room = selectedRoom {
            items = items.filter { $0.room?.id == room.id }
        }
        
        // Condition filter
        if let condition = selectedCondition {
            items = items.filter { $0.condition == condition }
        }
        
        // Photo filter
        if onlyWithPhotos {
            items = items.filter { !$0.images.isEmpty }
        }
        
        // Warranty filter
        if onlyWithWarranty {
            items = items.filter { $0.warrantyEndDate != nil || $0.isLifetimeWarranty }
        }
        
        return items
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Active filters
                    if hasActiveFilters {
                        activeFiltersBar
                    }
                    
                    // Results
                    if searchText.isEmpty && !hasActiveFilters {
                        emptySearchView
                    } else if filteredItems.isEmpty {
                        noResultsView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilters = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.accent)
                            
                            if hasActiveFilters {
                                Circle()
                                    .fill(Theme.Colors.error)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(
                    selectedCategory: $selectedCategory,
                    selectedRoom: $selectedRoom,
                    selectedCondition: $selectedCondition,
                    onlyWithPhotos: $onlyWithPhotos,
                    onlyWithWarranty: $onlyWithWarranty,
                    rooms: coreDataManager.rooms
                )
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.textSecondary)
                
                TextField("Search items...", text: $searchText)
                    .font(Theme.Fonts.body())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding()
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                if let category = selectedCategory {
                    FilterTag(text: category.rawValue) {
                        selectedCategory = nil
                    }
                }
                
                if let room = selectedRoom {
                    FilterTag(text: room.name) {
                        selectedRoom = nil
                    }
                }
                
                if let condition = selectedCondition {
                    FilterTag(text: condition.rawValue) {
                        selectedCondition = nil
                    }
                }
                
                if onlyWithPhotos {
                    FilterTag(text: "With Photos") {
                        onlyWithPhotos = false
                    }
                }
                
                if onlyWithWarranty {
                    FilterTag(text: "With Warranty") {
                        onlyWithWarranty = false
                    }
                }
                
                Button(action: clearAllFilters) {
                    Text("Clear All")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.error.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Theme.Colors.cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sm) {
                // Result count
                HStack {
                    Text("\(filteredItems.count) \(filteredItems.count == 1 ? "item" : "items") found")
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, Theme.Spacing.sm)
                
                // Items
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    private var emptySearchView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("Search Your Inventory")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Enter a search term or use filters to find items")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No Results Found")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Try adjusting your search or filters")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                Button(action: clearAllFilters) {
                    Text("Clear Filters")
                }
                .secondaryButtonStyle()
                .padding(.horizontal, 40)
            }
        }
        .padding()
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedRoom != nil || selectedCondition != nil || onlyWithPhotos || onlyWithWarranty
    }
    
    private func clearAllFilters() {
        selectedCategory = nil
        selectedRoom = nil
        selectedCondition = nil
        onlyWithPhotos = false
        onlyWithWarranty = false
    }
}

struct FilterTag: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(Theme.Fonts.caption())
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
        }
        .foregroundColor(Theme.Colors.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.Colors.accent.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Binding var selectedCategory: ItemCategory?
    @Binding var selectedRoom: Room?
    @Binding var selectedCondition: ItemCondition?
    @Binding var onlyWithPhotos: Bool
    @Binding var onlyWithWarranty: Bool
    let rooms: [Room]
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Category
                        filterSection(title: "Category") {
                            FlowLayout(spacing: Theme.Spacing.sm) {
                                ForEach(ItemCategory.allCases, id: \.self) { category in
                                    SelectableChip(
                                        text: category.rawValue,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                        }
                        
                        // Room
                        if !rooms.isEmpty {
                            filterSection(title: "Room") {
                                FlowLayout(spacing: Theme.Spacing.sm) {
                                    ForEach(rooms) { room in
                                        SelectableChip(
                                            text: room.name,
                                            isSelected: selectedRoom?.id == room.id
                                        ) {
                                            selectedRoom = selectedRoom?.id == room.id ? nil : room
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Condition
                        filterSection(title: "Condition") {
                            FlowLayout(spacing: Theme.Spacing.sm) {
                                ForEach(ItemCondition.allCases, id: \.self) { condition in
                                    SelectableChip(
                                        text: condition.rawValue,
                                        isSelected: selectedCondition == condition
                                    ) {
                                        selectedCondition = selectedCondition == condition ? nil : condition
                                    }
                                }
                            }
                        }
                        
                        // Additional filters
                        filterSection(title: "Additional Filters") {
                            VStack(spacing: Theme.Spacing.sm) {
                                Toggle(isOn: $onlyWithPhotos) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .foregroundColor(Theme.Colors.accent)
                                        Text("Only items with photos")
                                            .font(Theme.Fonts.body())
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.accent))
                                
                                Toggle(isOn: $onlyWithWarranty) {
                                    HStack {
                                        Image(systemName: "checkmark.shield")
                                            .foregroundColor(Theme.Colors.gold)
                                        Text("Only items with warranty")
                                            .font(Theme.Fonts.body())
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.gold))
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                        selectedRoom = nil
                        selectedCondition = nil
                        onlyWithPhotos = false
                        onlyWithWarranty = false
                    }
                    .foregroundColor(Theme.Colors.error)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            content()
        }
        .padding()
        .cardStyle()
    }
}

struct SelectableChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Theme.Colors.textSecondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
