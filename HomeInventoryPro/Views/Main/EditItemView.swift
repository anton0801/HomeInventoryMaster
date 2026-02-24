import SwiftUI

struct StatsPermissionView: View {
    @ObservedObject var supervisor: Supervisor
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(g.size.width > g.size.height ? "home_alerts_bg2" : "home_alerts_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                
                if g.size.width < g.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        
                        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                            .font(.custom("Lalezar-Regular", size: 26))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .multilineTextAlignment(.center)
                        
                        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                            .font(.custom("Lalezar-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .multilineTextAlignment(.center)
                        
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            
                            Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                                .font(.custom("Lalezar-Regular", size: 28))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .multilineTextAlignment(.leading)
                            
                            Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                                .font(.custom("Lalezar-Regular", size: 18))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                                .padding(.bottom, 20)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await supervisor.send(.permissionRequested)
                }
            } label: {
                Image("home_alerts_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                Task {
                    await supervisor.send(.permissionSkipped)
                }
            } label: {
                Text("SKIP")
                    .font(.custom("Lalezar-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                Color(hex: "000000").opacity(0.48)
                            )
                    )
            }
            .frame(width: 260)
        }
        .padding(.horizontal, 20)
    }
}


struct EditItemView: View {
    @State var item: Item
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showBarcodeScanner = false
    @State private var showRoomPicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var showSuccess = false
    
    @State private var name: String
    @State private var brand: String
    @State private var modelNumber: String
    @State private var serialNumber: String
    @State private var barcode: String
    @State private var purchaseDate: Date?
    @State private var purchasePrice: Double
    @State private var warrantyEndDate: Date?
    @State private var isLifetimeWarranty: Bool
    @State private var selectedCondition: ItemCondition
    @State private var notes: String
    @State private var selectedCategory: ItemCategory
    @State private var selectedRoom: Room?
    
    init(item: Item) {
        self._item = State(initialValue: item)
        self._name = State(initialValue: item.name)
        self._brand = State(initialValue: item.brand ?? "")
        self._modelNumber = State(initialValue: item.modelNumber ?? "")
        self._serialNumber = State(initialValue: item.serialNumber ?? "")
        self._barcode = State(initialValue: item.barcode ?? "")
        self._purchaseDate = State(initialValue: item.purchaseDate)
        self._purchasePrice = State(initialValue: item.purchasePrice)
        self._warrantyEndDate = State(initialValue: item.warrantyEndDate)
        self._isLifetimeWarranty = State(initialValue: item.isLifetimeWarranty)
        self._selectedCondition = State(initialValue: item.condition)
        self._notes = State(initialValue: item.notes ?? "")
        self._selectedCategory = State(initialValue: item.category)
        self._selectedRoom = State(initialValue: item.room)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Existing images
                        if !item.images.isEmpty {
                            existingImagesSection
                        }
                        
                        // Add new images
                        newImagesSection
                        
                        // All other sections from AddItemView
                        basicInfoSection
                        purchaseSection
                        warrantySection
                        organizationSection
                        notesSection
                        
                        // Save button
                        Button(action: saveChanges) {
                            Text("Save Changes")
                        }
                        .primaryButtonStyle()
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $selectedImages)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(images: $selectedImages)
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(scannedCode: $barcode)
            }
            .sheet(isPresented: $showRoomPicker) {
                RoomPickerView(selectedRoom: $selectedRoom, rooms: coreDataManager.rooms)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Item updated successfully!")
            }
        }
    }
    
    private var existingImagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Current Photos")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(item.images) { image in
                        if let uiImage = UIImage(data: image.imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                                
                                Button(action: {
                                    // Remove image
                                    item.images.removeAll { $0.id == image.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var newImagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if !selectedImages.isEmpty {
                Text("New Photos")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                                
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8)
                            }
                        }
                        
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
                }
            } else {
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
            }
        }
    }
    
    // Reuse sections from AddItemView
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Basic Information")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: Theme.Spacing.md) {
                FloatingTextField(title: "Item Name *", text: $name)
                FloatingTextField(title: "Brand", text: $brand)
                FloatingTextField(title: "Model Number", text: $modelNumber)
                
                HStack(spacing: Theme.Spacing.sm) {
                    FloatingTextField(title: "Serial Number", text: $serialNumber)
                    
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
                DatePickerField(title: "Purchase Date", date: $purchaseDate, allowNil: true)
                
                FloatingTextField(
                    title: "Purchase Price",
                    text: Binding(
                        get: { purchasePrice > 0 ? String(format: "%.2f", purchasePrice) : "" },
                        set: { purchasePrice = Double($0) ?? 0 }
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
                Toggle(isOn: $isLifetimeWarranty) {
                    HStack {
                        Image(systemName: "infinity")
                            .foregroundColor(Theme.Colors.gold)
                        Text("Lifetime Warranty")
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.gold))
                
                if !isLifetimeWarranty {
                    DatePickerField(title: "Warranty End Date", date: $warrantyEndDate, allowNil: true)
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
                Button(action: { showRoomPicker = true }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text(selectedRoom?.name ?? "Select Room")
                            .font(Theme.Fonts.body())
                            .foregroundColor(selectedRoom == nil ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding()
                    .background(Theme.Colors.background)
                    .cornerRadius(Theme.CornerRadius.sm)
                }
                
                Menu {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Label(category.rawValue, systemImage: categoryIcon(for: category))
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: categoryIcon(for: selectedCategory))
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text(selectedCategory.rawValue)
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
                
                Menu {
                    ForEach(ItemCondition.allCases, id: \.self) { condition in
                        Button(action: { selectedCondition = condition }) {
                            Text(condition.rawValue)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(Theme.Colors.warning)
                        
                        Text(selectedCondition.rawValue)
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
            
            TextEditor(text: $notes)
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
    
    private func saveChanges() {
        // Convert new images
        let newItemImages = selectedImages.map { uiImage in
            ItemImage(
                imageData: uiImage.jpegData(compressionQuality: 0.8) ?? Data(),
                isPrimary: false
            )
        }
        
        // Combine existing and new images
        var allImages = item.images
        allImages.append(contentsOf: newItemImages)
        
        // Update first image as primary if no primary exists
        if !allImages.isEmpty && !allImages.contains(where: { $0.isPrimary }) {
            allImages[0] = ItemImage(
                id: allImages[0].id,
                imageData: allImages[0].imageData,
                isPrimary: true,
                createdAt: allImages[0].createdAt
            )
        }
        
        let updatedItem = Item(
            id: item.id,
            name: name,
            brand: brand.isEmpty ? nil : brand,
            modelNumber: modelNumber.isEmpty ? nil : modelNumber,
            serialNumber: serialNumber.isEmpty ? nil : serialNumber,
            barcode: barcode.isEmpty ? nil : barcode,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            warrantyEndDate: isLifetimeWarranty ? nil : warrantyEndDate,
            isLifetimeWarranty: isLifetimeWarranty,
            condition: selectedCondition,
            notes: notes.isEmpty ? nil : notes,
            category: selectedCategory,
            room: selectedRoom,
            images: allImages,
            maintenanceTasks: item.maintenanceTasks,
            createdAt: item.createdAt,
            updatedAt: Date()
        )
        
        coreDataManager.updateItem(updatedItem)
        showSuccess = true
    }
}
