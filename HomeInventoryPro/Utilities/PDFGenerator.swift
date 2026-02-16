import PDFKit
import UIKit

class PDFGenerator {
    static let shared = PDFGenerator()
    
    private init() {}
    
    func generateInventoryReport(items: [Item], title: String = "Home Inventory Report") -> URL? {
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("inventory_report.pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                var currentY: CGFloat = 60
                let pageWidth = pageSize.width
                let margin: CGFloat = 40
                
                // Group items by room
                let groupedItems = Dictionary(grouping: items) { $0.room?.name ?? "Uncategorized" }
                let sortedRooms = groupedItems.keys.sorted()
                
                context.beginPage()
                
                // Title page
                currentY = drawTitle(title, at: currentY, context: context, pageWidth: pageWidth)
                currentY += 20
                
                // Summary
                currentY = drawSummary(items: items, at: currentY, context: context, margin: margin, pageWidth: pageWidth)
                
                // Items by room
                for roomName in sortedRooms {
                    guard let roomItems = groupedItems[roomName] else { continue }
                    
                    // Check if we need a new page
                    if currentY > pageSize.height - 200 {
                        context.beginPage()
                        currentY = 60
                    }
                    
                    currentY = drawRoomSection(
                        roomName: roomName,
                        items: roomItems,
                        at: currentY,
                        context: context,
                        margin: margin,
                        pageWidth: pageWidth,
                        pageHeight: pageSize.height
                    )
                }
            }
            
            return tempURL
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }
    
    private func drawTitle(_ title: String, at y: CGFloat, context: UIGraphicsPDFRendererContext, pageWidth: CGFloat) -> CGFloat {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor(Theme.Colors.primary)
        ]
        
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageWidth - titleSize.width) / 2,
            y: y,
            width: titleSize.width,
            height: titleSize.height
        )
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Generated on \(dateFormatter.string(from: Date()))"
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        
        let dateSize = dateString.size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: (pageWidth - dateSize.width) / 2,
            y: y + titleSize.height + 10,
            width: dateSize.width,
            height: dateSize.height
        )
        
        dateString.draw(in: dateRect, withAttributes: dateAttributes)
        
        return y + titleSize.height + dateSize.height + 30
    }
    
    private func drawSummary(items: [Item], at y: CGFloat, context: UIGraphicsPDFRendererContext, margin: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentY = y
        
        // Summary box
        let boxRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 100)
        
        // Background
        context.cgContext.setFillColor(UIColor(Theme.Colors.background).cgColor)
        context.cgContext.fill(boxRect)
        
        // Border
        context.cgContext.setStrokeColor(UIColor(Theme.Colors.accent).cgColor)
        context.cgContext.setLineWidth(2)
        context.cgContext.stroke(boxRect)
        
        currentY += 20
        
        // Total items
        let totalValue = items.reduce(0) { $0 + $1.purchasePrice }
        let warrantyCount = items.filter { $0.warrantyEndDate != nil || $0.isLifetimeWarranty }.count
        
        let summaryText = """
        Total Items: \(items.count)
        Total Value: \(totalValue.toCurrency())
        Items with Warranty: \(warrantyCount)
        """
        
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let summaryRect = CGRect(x: margin + 20, y: currentY, width: pageWidth - 2 * margin - 40, height: 60)
        summaryText.draw(in: summaryRect, withAttributes: summaryAttributes)
        
        return y + 120
    }
    
    private func drawRoomSection(
        roomName: String,
        items: [Item],
        at y: CGFloat,
        context: UIGraphicsPDFRendererContext,
        margin: CGFloat,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) -> CGFloat {
        var currentY = y
        
        // Room header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor(Theme.Colors.primary)
        ]
        
        let headerText = "\(roomName) (\(items.count) items)"
        headerText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        
        currentY += 35
        
        // Draw line
        context.cgContext.setStrokeColor(UIColor(Theme.Colors.textSecondary).cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: margin, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        context.cgContext.strokePath()
        
        currentY += 15
        
        // Items
        for item in items {
            // Check if we need a new page
            if currentY > pageHeight - 150 {
                context.beginPage()
                currentY = 60
            }
            
            currentY = drawItem(
                item,
                at: currentY,
                context: context,
                margin: margin,
                pageWidth: pageWidth
            )
            
            currentY += 10
        }
        
        return currentY + 20
    }
    
    private func drawItem(_ item: Item, at y: CGFloat, context: UIGraphicsPDFRendererContext, margin: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentY = y
        let imageSize: CGFloat = 80
        let contentMargin = margin + imageSize + 15
        
        // Draw image if available
        if let firstImage = item.images.first,
           let uiImage = UIImage(data: firstImage.imageData) {
            let imageRect = CGRect(x: margin, y: currentY, width: imageSize, height: imageSize)
            uiImage.draw(in: imageRect)
            
            // Image border
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.stroke(imageRect)
        } else {
            // Placeholder
            let imageRect = CGRect(x: margin, y: currentY, width: imageSize, height: imageSize)
            context.cgContext.setFillColor(UIColor(Theme.Colors.background).cgColor)
            context.cgContext.fill(imageRect)
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.stroke(imageRect)
            
            let icon = "📦"
            let iconAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40)
            ]
            let iconSize = icon.size(withAttributes: iconAttributes)
            icon.draw(at: CGPoint(
                x: margin + (imageSize - iconSize.width) / 2,
                y: currentY + (imageSize - iconSize.height) / 2
            ), withAttributes: iconAttributes)
        }
        
        // Item name
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.darkText
        ]
        
        item.name.draw(at: CGPoint(x: contentMargin, y: currentY), withAttributes: nameAttributes)
        currentY += 22
        
        // Details
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        var details: [String] = []
        
        if let brand = item.brand {
            details.append("Brand: \(brand)")
        }
        
        details.append("Category: \(item.category.rawValue)")
        details.append("Condition: \(item.condition.rawValue)")
        
        if item.purchasePrice > 0 {
            details.append("Value: \(item.purchasePrice.toCurrency())")
        }
        
        if let purchaseDate = item.purchaseDate {
            details.append("Purchased: \(purchaseDate.toString())")
        }
        
        if item.isLifetimeWarranty {
            details.append("Warranty: Lifetime")
        } else if let warrantyDate = item.warrantyEndDate {
            details.append("Warranty: Until \(warrantyDate.toString())")
        }
        
        if let serialNumber = item.serialNumber {
            details.append("Serial: \(serialNumber)")
        }
        
        for detail in details {
            detail.draw(at: CGPoint(x: contentMargin, y: currentY), withAttributes: detailAttributes)
            currentY += 16
        }
        
        return max(y + imageSize, currentY)
    }
}
