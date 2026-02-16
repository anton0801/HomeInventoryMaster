import SwiftUI

struct ItemCard: View {
    let item: Item
    @State private var imageScale: CGFloat = 0.9
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Image
            Group {
                if let firstImage = item.images.first,
                   let uiImage = UIImage(data: firstImage.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        .scaleEffect(imageScale)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accent.opacity(0.2), Theme.Colors.accent.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
                    }
                    .frame(width: 80, height: 80)
                    .scaleEffect(imageScale)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(Theme.Fonts.headline(size: 17))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon(for: item.category))
                            .font(.system(size: 10))
                        Text(item.category.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Theme.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.accent.opacity(0.1))
                    .cornerRadius(6)
                    
                    // Warranty status
                    if item.warrantyEndDate != nil || item.isLifetimeWarranty {
                        HStack(spacing: 4) {
                            Image(systemName: item.warrantyStatus.icon)
                                .font(.system(size: 10))
                            if !item.isLifetimeWarranty, let date = item.warrantyEndDate {
                                Text(date.toString(format: "MMM yyyy"))
                                    .font(.system(size: 11, weight: .medium))
                            } else {
                                Text("Lifetime")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .foregroundColor(item.warrantyStatus.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.warrantyStatus.color.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .cardStyle()
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                imageScale = 1.0
            }
        }
    }
    
    private func categoryIcon(for category: ItemCategory) -> String {
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
