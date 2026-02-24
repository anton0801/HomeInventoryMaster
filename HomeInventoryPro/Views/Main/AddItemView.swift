import SwiftUI
import PhotosUI
import AVFoundation

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geo.size.width > geo.size.height ? "wifi_problem_bg2" : "wifi_problem_bg")
                    .resizable().scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .opacity(0.4)
                    .blur(radius: 6.5)
                
                Image("wifi_problem_alert")
                    .resizable()
                    .frame(width: 300, height: 260)
            }
        }
        .ignoresSafeArea()
    }
}

struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AddItemViewModel()
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showBarcodeScanner = false
    @State private var showRoomPicker = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Image section
                        imageSection
                        
                        // Basic info
                        basicInfoSection
                        
                        // Purchase details
                        purchaseSection
                        
                        // Warranty section
                        warrantySection
                        
                        // Organization
                        organizationSection
                        
                        // Notes
                        notesSection
                        
                        // Save button
                        Button(action: saveItem) {
                            Text("Save Item")
                        }
                        .primaryButtonStyle()
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(images: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(scannedCode: $viewModel.barcode)
            }
            .sheet(isPresented: $showRoomPicker) {
                RoomPickerView(selectedRoom: $viewModel.selectedRoom, rooms: coreDataManager.rooms)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Item added successfully!")
            }
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Photos")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            if viewModel.selectedImages.isEmpty {
                // Image options
                VStack(spacing: Theme.Spacing.sm) {
                    ImagePickerButton(
                        title: "Take Photo",
                        icon: "camera.fill",
                        color: Theme.Colors.accent
                    ) {
                        showCamera = true
                    }
                    
                    ImagePickerButton(
                        title: "Choose from Gallery",
                        icon: "photo.fill",
                        color: Theme.Colors.gold
                    ) {
                        showImagePicker = true
                    }
                }
                .cardStyle()
            } else {
                // Image gallery
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                                
                                // Remove button
                                Button(action: {
                                    withAnimation {
                                        viewModel.selectedImages.remove(atOffsets: IndexSet(integer: index))
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8)
                            }
                        }
                        
                        // Add more button
                        Button(action: { showImagePicker = true }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(Theme.Colors.accent)
                                
                                Text("Add More")
                                    .font(Theme.Fonts.caption())
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            .frame(width: 120, height: 120)
                            .background(Theme.Colors.accent.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.md)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Basic Information")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.md) {
                FloatingTextField(title: "Item Name *", text: $viewModel.name)
                
                FloatingTextField(title: "Brand", text: $viewModel.brand)
                
                FloatingTextField(title: "Model Number", text: $viewModel.modelNumber)
                
                HStack(spacing: Theme.Spacing.sm) {
                    FloatingTextField(title: "Serial Number", text: $viewModel.serialNumber)
                    
                    Button(action: { showBarcodeScanner = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.accent)
                            .frame(width: 50, height: 50)
                            .background(Theme.Colors.accent.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.sm)
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Purchase Details")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.md) {
                DatePickerField(title: "Purchase Date", date: $viewModel.purchaseDate)
                
                FloatingTextField(
                    title: "Purchase Price",
                    text: Binding(
                        get: { viewModel.purchasePrice > 0 ? String(format: "%.2f", viewModel.purchasePrice) : "" },
                        set: { viewModel.purchasePrice = Double($0) ?? 0 }
                    ),
                    keyboardType: .decimalPad
                )
            }
            .cardStyle()
        }
    }
    
    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Warranty")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.md) {
                Toggle(isOn: $viewModel.isLifetimeWarranty) {
                    HStack {
                        Image(systemName: "infinity")
                            .foregroundColor(Theme.Colors.gold)
                        Text("Lifetime Warranty")
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.gold))
                
                if !viewModel.isLifetimeWarranty {
                    DatePickerField(title: "Warranty End Date", date: $viewModel.warrantyEndDate, allowNil: true)
                }
            }
            .padding()
            .cardStyle()
        }
    }
    
    private var organizationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Organization")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.md) {
                // Room picker
                Button(action: { showRoomPicker = true }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text(viewModel.selectedRoom?.name ?? "Select Room")
                            .font(Theme.Fonts.body())
                            .foregroundColor(viewModel.selectedRoom == nil ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding()
                    .background(Theme.Colors.background)
                    .cornerRadius(Theme.CornerRadius.sm)
                }
                
                // Category picker
                Menu {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        Button(action: { viewModel.selectedCategory = category }) {
                            Label(category.rawValue, systemImage: categoryIcon(for: category))
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: categoryIcon(for: viewModel.selectedCategory))
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text(viewModel.selectedCategory.rawValue)
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding()
                    .background(Theme.Colors.background)
                    .cornerRadius(Theme.CornerRadius.sm)
                }
                
                // Condition picker
                Menu {
                    ForEach(ItemCondition.allCases, id: \.self) { condition in
                        Button(action: { viewModel.selectedCondition = condition }) {
                            Text(condition.rawValue)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(Theme.Colors.warning)
                        
                        Text(viewModel.selectedCondition.rawValue)
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding()
                    .background(Theme.Colors.background)
                    .cornerRadius(Theme.CornerRadius.sm)
                }
            }
            .cardStyle()
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Notes")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            TextEditor(text: $viewModel.notes)
                .frame(height: 120)
                .padding(12)
                .background(Theme.Colors.background)
                .cornerRadius(Theme.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Theme.Colors.textSecondary.opacity(0.2), lineWidth: 1)
                )
                .cardStyle()
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
    
    private func saveItem() {
        guard !viewModel.name.isEmpty else { return }
        
        let images = viewModel.selectedImages.enumerated().map { index, uiImage in
            ItemImage(
                imageData: uiImage.jpegData(compressionQuality: 0.8) ?? Data(),
                isPrimary: index == 0
            )
        }
        
        let item = Item(
            name: viewModel.name,
            brand: viewModel.brand.isEmpty ? nil : viewModel.brand,
            modelNumber: viewModel.modelNumber.isEmpty ? nil : viewModel.modelNumber,
            serialNumber: viewModel.serialNumber.isEmpty ? nil : viewModel.serialNumber,
            barcode: viewModel.barcode.isEmpty ? nil : viewModel.barcode,
            purchaseDate: viewModel.purchaseDate,
            purchasePrice: viewModel.purchasePrice,
            warrantyEndDate: viewModel.isLifetimeWarranty ? nil : viewModel.warrantyEndDate,
            isLifetimeWarranty: viewModel.isLifetimeWarranty,
            condition: viewModel.selectedCondition,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            category: viewModel.selectedCategory,
            room: viewModel.selectedRoom,
            images: images
        )
        
        coreDataManager.addItem(item)
        
        // Schedule notifications
        if let warrantyDate = item.warrantyEndDate {
            NotificationManager.shared.scheduleWarrantyNotification(for: item, daysBefore: 30)
            NotificationManager.shared.scheduleWarrantyNotification(for: item, daysBefore: 7)
        }
        
        showSuccess = true
    }
}

// MARK: - Add Item ViewModel
class AddItemViewModel: ObservableObject {
    @Published var name = ""
    @Published var brand = ""
    @Published var modelNumber = ""
    @Published var serialNumber = ""
    @Published var barcode = ""
    @Published var purchaseDate: Date? = Date()
    @Published var purchasePrice: Double = 0
    @Published var warrantyEndDate: Date?
    @Published var isLifetimeWarranty = false
    @Published var selectedCondition: ItemCondition = .new
    @Published var notes = ""
    @Published var selectedCategory: ItemCategory = .other
    @Published var selectedRoom: Room?
    @Published var selectedImages: [UIImage] = []
}

// MARK: - Supporting Components
struct FloatingTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textSecondary)
                .offset(y: text.isEmpty ? 0 : -25)
                .scaleEffect(text.isEmpty ? 1 : 0.85, anchor: .leading)
            
            TextField("", text: $text)
                .font(Theme.Fonts.body())
                .keyboardType(keyboardType)
                .padding(.top, text.isEmpty ? 0 : 15)
        }
        .padding()
        .background(Theme.Colors.background)
        .cornerRadius(Theme.CornerRadius.sm)
        .animation(.spring(response: 0.3), value: text.isEmpty)
    }
}

struct DatePickerField: View {
    let title: String
    @Binding var date: Date?
    var allowNil: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textSecondary)
            
            DatePicker(
                "",
                selection: Binding(
                    get: { date ?? Date() },
                    set: { date = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(CompactDatePickerStyle())
            .labelsHidden()
        }
        .padding()
        .background(Theme.Colors.background)
        .cornerRadius(Theme.CornerRadius.sm)
    }
}

struct ImagePickerButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(title)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
            }
            .padding()
            .background(Theme.Colors.background)
            .cornerRadius(Theme.CornerRadius.sm)
        }
    }
}
