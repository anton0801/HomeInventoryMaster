import SwiftUI

struct ItemDetailView: View {
    let item: Item
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Image gallery header
                    imageGallerySection
                    
                    // Content
                    VStack(spacing: Theme.Spacing.lg) {
                        // Main info card
                        mainInfoSection
                        
                        // Details
                        detailsSection
                        
                        // Warranty info
                        if item.warrantyEndDate != nil || item.isLifetimeWarranty {
                            warrantySection
                        }
                        
                        // Maintenance tasks
                        if !item.maintenanceTasks.isEmpty {
                            maintenanceSection
                        }
                        
                        // Action buttons
                        actionButtonsSection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditItemView(item: item)
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageViewerView(images: item.images, selectedIndex: $selectedImageIndex)
        }
        .alert("Delete Item", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                coreDataManager.deleteItem(item)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
    
    private var imageGallerySection: some View {
        ZStack(alignment: .bottomLeading) {
            if item.images.isEmpty {
                // Placeholder
                ZStack {
                    LinearGradient(
                        colors: [Theme.Colors.accent.opacity(0.3), Theme.Colors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                }
                .frame(height: 300)
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(item.images.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: item.images[index].imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .clipped()
                                .tag(index)
                                .onTapGesture {
                                    showImageViewer = true
                                }
                        }
                    }
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)
            
            // Image count badge
            if item.images.count > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 12))
                    Text("\(item.images.count)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .padding()
            }
        }
    }
    
    private var mainInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Title
            Text(item.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Brand and model
            if let brand = item.brand {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(brand)
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    if let model = item.modelNumber {
                        Text("•")
                            .foregroundColor(Theme.Colors.textSecondary)
                        Text(model)
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            
            // Category and condition badges
            HStack(spacing: Theme.Spacing.sm) {
                CategoryBadge(category: item.category)
                ConditionBadge(condition: item.condition)
            }
            
            Divider()
                .padding(.vertical, Theme.Spacing.sm)
            
            // Price
            if item.purchasePrice > 0 {
                HStack {
                    Text("Purchase Price")
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(item.purchasePrice.toCurrency())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var detailsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let room = item.room {
                DetailRow(
                    icon: "house.fill",
                    title: "Room",
                    value: room.name,
                    color: Theme.Colors.gold
                )
            }
            
            if let purchaseDate = item.purchaseDate {
                DetailRow(
                    icon: "calendar",
                    title: "Purchase Date",
                    value: purchaseDate.toString(),
                    color: Theme.Colors.accent
                )
            }
            
            if let serialNumber = item.serialNumber {
                DetailRow(
                    icon: "number",
                    title: "Serial Number",
                    value: serialNumber,
                    color: Theme.Colors.success
                )
            }
            
            if let notes = item.notes {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.warning)
                            .frame(width: 24)
                        
                        Text("Notes")
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Text(notes)
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.leading, 32)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.background)
                .cornerRadius(Theme.CornerRadius.sm)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: item.warrantyStatus.icon)
                    .font(.system(size: 20))
                    .foregroundColor(item.warrantyStatus.color)
                
                Text("Warranty")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                if item.isLifetimeWarranty {
                    Text("Lifetime")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.gold.opacity(0.1))
                        .cornerRadius(12)
                } else if let warrantyDate = item.warrantyEndDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(warrantyDate.toString())
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        let days = warrantyDate.daysUntil()
                        if days >= 0 {
                            Text("\(days) days left")
                                .font(Theme.Fonts.caption(size: 11))
                                .foregroundColor(item.warrantyStatus.color)
                        } else {
                            Text("Expired")
                                .font(Theme.Fonts.caption(size: 11))
                                .foregroundColor(Theme.Colors.error)
                        }
                    }
                }
            }
            
            // Warranty progress bar
            if !item.isLifetimeWarranty, let warrantyDate = item.warrantyEndDate, let purchaseDate = item.purchaseDate {
                let totalDays = Calendar.current.dateComponents([.day], from: purchaseDate, to: warrantyDate).day ?? 0
                let remainingDays = warrantyDate.daysUntil()
                let progress = totalDays > 0 ? Double(totalDays - remainingDays) / Double(totalDays) : 1.0
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.warrantyStatus.color.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.warrantyStatus.color)
                            .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.accent)
                
                Text("Maintenance Tasks")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            ForEach(item.maintenanceTasks) { task in
                MaintenanceTaskRow(task: task)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            NavigationLink(destination: AddMaintenanceTaskView(item: item)) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Maintenance Task")
                }
            }
            .secondaryButtonStyle()
            
            Button(action: shareItem) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Item")
                }
            }
            .secondaryButtonStyle()
        }
    }
    
    private func shareItem() {
        // Implementation for sharing
    }
}

// MARK: - Supporting Components
struct CategoryBadge: View {
    let category: ItemCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.system(size: 12))
            Text(category.rawValue)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(Theme.Colors.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.Colors.accent.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var categoryIcon: String {
        switch category {
        case .electronics: return "cpu"
        case .furniture: return "bed.double.fill"
        case .clothing: return "tshirt.fill"
        case .kitchen: return "fork.knife"
        case .tools: return "hammer.fill"
        case .other: return "square.grid.2x2"
        }
    }
}

struct ConditionBadge: View {
    let condition: ItemCondition
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
            Text(condition.rawValue)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(conditionColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(conditionColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var conditionColor: Color {
        switch condition {
        case .new: return Theme.Colors.success
        case .good: return Theme.Colors.accent
        case .fair: return Theme.Colors.warning
        case .needsRepair: return Theme.Colors.error
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(value)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.Colors.background)
        .cornerRadius(Theme.CornerRadius.sm)
    }
}

struct MaintenanceTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if let nextDue = task.nextDueDate {
                    Text("Due: \(nextDue.toString())")
                        .font(Theme.Fonts.caption(size: 12))
                        .foregroundColor(task.isOverdue ? Theme.Colors.error : Theme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.Colors.error)
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Theme.Colors.success.opacity(0.5))
            }
        }
        .padding()
        .background(Theme.Colors.background)
        .cornerRadius(Theme.CornerRadius.sm)
    }
}
