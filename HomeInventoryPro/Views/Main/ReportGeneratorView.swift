import SwiftUI

struct ReportGeneratorView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var reportType: ReportType = .fullInventory
    @State private var selectedRoom: Room?
    @State private var selectedCategory: ItemCategory?
    @State private var isGenerating = false
    @State private var generatedPDFURL: URL?
    @State private var showShareSheet = false
    
    enum ReportType: String, CaseIterable {
        case fullInventory = "Full Inventory"
        case byRoom = "By Room"
        case byCategory = "By Category"
        case warrantyReport = "Warranty Report"
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Report type selector
                    reportTypeSection
                    
                    // Filters based on type
                    if reportType == .byRoom {
                        roomFilterSection
                    } else if reportType == .byCategory {
                        categoryFilterSection
                    }
                    
                    // Preview
                    previewSection
                    
                    // Generate button
                    generateButtonSection
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Generate Report")
        .sheet(isPresented: $showShareSheet) {
            if let url = generatedPDFURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.Colors.accent)
            
            Text("Create PDF Report")
                .font(Theme.Fonts.title(size: 24))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Generate a professional inventory report for insurance or personal records")
                .font(Theme.Fonts.body(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var reportTypeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Report Type")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Button(action: {
                        withAnimation {
                            reportType = type
                        }
                    }) {
                        HStack {
                            Image(systemName: reportType == type ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(reportType == type ? Theme.Colors.accent : Theme.Colors.textSecondary)
                            
                            Text(type.rawValue)
                                .font(Theme.Fonts.body())
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Spacer()
                        }
                        .padding()
                        .background(reportType == type ? Theme.Colors.accent.opacity(0.1) : Theme.Colors.background)
                        .cornerRadius(Theme.CornerRadius.sm)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var roomFilterSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Select Room")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Menu {
                ForEach(coreDataManager.rooms) { room in
                    Button(action: { selectedRoom = room }) {
                        Text(room.name)
                    }
                }
            } label: {
                HStack {
                    Text(selectedRoom?.name ?? "Choose a room")
                        .font(Theme.Fonts.body())
                        .foregroundColor(selectedRoom == nil ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding()
                .background(Theme.Colors.background)
                .cornerRadius(Theme.CornerRadius.sm)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Select Category")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Menu {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category.rawValue)
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory?.rawValue ?? "Choose a category")
                        .font(Theme.Fonts.body())
                        .foregroundColor(selectedCategory == nil ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding()
                .background(Theme.Colors.background)
                .cornerRadius(Theme.CornerRadius.sm)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Report Preview")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.sm) {
                PreviewRow(label: "Items to include", value: "\(filteredItems.count)")
                PreviewRow(label: "Total value", value: totalValue)
                PreviewRow(label: "Format", value: "PDF")
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var generateButtonSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: generateReport) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Generating...")
                    } else {
                        Image(systemName: "doc.badge.plus")
                        Text("Generate PDF Report")
                    }
                }
            }
            .primaryButtonStyle()
            .disabled(isGenerating || !canGenerate)
            .opacity(canGenerate ? 1.0 : 0.6)
            
            Button(action: generateCSV) {
                HStack {
                    Image(systemName: "tablecells")
                    Text("Export as CSV")
                }
            }
            .secondaryButtonStyle()
            .disabled(isGenerating)
        }
    }
    
    private var filteredItems: [Item] {
        var items = coreDataManager.items
        
        switch reportType {
        case .fullInventory:
            return items
        case .byRoom:
            if let room = selectedRoom {
                return items.filter { $0.room?.id == room.id }
            }
        case .byCategory:
            if let category = selectedCategory {
                return items.filter { $0.category == category }
            }
        case .warrantyReport:
            return items.filter { $0.warrantyEndDate != nil || $0.isLifetimeWarranty }
        }
        
        return []
    }
    
    private var totalValue: String {
        let total = filteredItems.reduce(0) { $0 + $1.purchasePrice }
        return total.toCurrency()
    }
    
    private var canGenerate: Bool {
        switch reportType {
        case .fullInventory, .warrantyReport:
            return !filteredItems.isEmpty
        case .byRoom:
            return selectedRoom != nil && !filteredItems.isEmpty
        case .byCategory:
            return selectedCategory != nil && !filteredItems.isEmpty
        }
    }
    
    private func generateReport() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let title: String
            switch reportType {
            case .fullInventory:
                title = "Complete Home Inventory"
            case .byRoom:
                title = "\(selectedRoom?.name ?? "Room") Inventory"
            case .byCategory:
                title = "\(selectedCategory?.rawValue ?? "Category") Inventory"
            case .warrantyReport:
                title = "Warranty Report"
            }
            
            if let url = PDFGenerator.shared.generateInventoryReport(items: filteredItems, title: title) {
                DispatchQueue.main.async {
                    self.generatedPDFURL = url
                    self.isGenerating = false
                    self.showShareSheet = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func generateCSV() {
        let csvString = CSVGenerator.shared.generateCSV(items: filteredItems)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("inventory_export.csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            generatedPDFURL = tempURL
            showShareSheet = true
        } catch {
            print("Error generating CSV: \(error)")
        }
    }
}

struct PreviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.body(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(Theme.Fonts.body(size: 14))
                .foregroundColor(Theme.Colors.textPrimary)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Theme.Colors.background)
        .cornerRadius(Theme.CornerRadius.sm)
    }
}

// MARK: - CSV Generator
class CSVGenerator {
    static let shared = CSVGenerator()
    
    private init() {}
    
    func generateCSV(items: [Item]) -> String {
        var csv = "Name,Brand,Model,Serial Number,Category,Condition,Room,Purchase Date,Purchase Price,Warranty End Date,Notes\n"
        
        for item in items {
            let row = [
                escapeCSV(item.name),
                escapeCSV(item.brand ?? ""),
                escapeCSV(item.modelNumber ?? ""),
                escapeCSV(item.serialNumber ?? ""),
                escapeCSV(item.category.rawValue),
                escapeCSV(item.condition.rawValue),
                escapeCSV(item.room?.name ?? ""),
                escapeCSV(item.purchaseDate?.toString() ?? ""),
                String(item.purchasePrice),
                escapeCSV(item.isLifetimeWarranty ? "Lifetime" : (item.warrantyEndDate?.toString() ?? "")),
                escapeCSV(item.notes ?? "")
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
