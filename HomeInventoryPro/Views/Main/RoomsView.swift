import SwiftUI

struct RoomsView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showAddRoom = false
    @State private var selectedRoom: Room?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                if coreDataManager.rooms.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.md) {
                            ForEach(coreDataManager.rooms) { room in
                                NavigationLink(destination: RoomDetailView(room: room)) {
                                    RoomCard(room: room, itemCount: itemCount(for: room))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Rooms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddRoom = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddRoom) {
                AddRoomView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "house")
                .font(.system(size: 70))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No Rooms Yet")
                .font(Theme.Fonts.headline(size: 24))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Organize your items by creating rooms")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showAddRoom = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Room")
                }
            }
            .primaryButtonStyle()
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private func itemCount(for room: Room) -> Int {
        coreDataManager.items.filter { $0.room?.id == room.id }.count
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: Room
    let itemCount: Int
    @State private var scale: CGFloat = 0.95
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.gold.opacity(0.3), Theme.Colors.gold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "house.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.Colors.gold)
            }
            .frame(width: 70, height: 70)
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(room.name)
                    .font(Theme.Fonts.headline(size: 20))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if let location = room.location {
                    Text(location)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 12))
                    Text("\(itemCount) items")
                        .font(Theme.Fonts.caption())
                }
                .foregroundColor(Theme.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.Colors.accent.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .cardStyle()
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Room Detail View
struct RoomDetailView: View {
    let room: Room
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showEditRoom = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var roomItems: [Item] {
        coreDataManager.items.filter { $0.room?.id == room.id }
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            if roomItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        // Stats
                        statsSection
                        
                        // Items
                        ForEach(roomItems) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemCard(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(room.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditRoom = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showEditRoom) {
            EditRoomView(room: room)
        }
        .alert("Delete Room", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                coreDataManager.deleteRoom(room)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this room? Items will not be deleted.")
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatBadge(
                icon: "cube.box.fill",
                value: "\(roomItems.count)",
                label: "Items",
                color: Theme.Colors.accent
            )
            
            StatBadge(
                icon: "dollarsign.circle.fill",
                value: totalValue,
                label: "Total Value",
                color: Theme.Colors.gold
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No Items in This Room")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Add items to organize your belongings")
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var totalValue: String {
        let total = roomItems.reduce(0) { $0 + $1.purchasePrice }
        return total.toCurrency()
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(label)
                    .font(Theme.Fonts.caption(size: 11))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Add Room View
struct AddRoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var roomName = ""
    @State private var location = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.lg) {
                    FloatingTextField(title: "Room Name *", text: $roomName)
                        .cardStyle()
                    
                    FloatingTextField(title: "Location (Optional)", text: $location)
                        .cardStyle()
                    
                    Spacer()
                    
                    Button(action: saveRoom) {
                        Text("Add Room")
                    }
                    .primaryButtonStyle()
                    .disabled(roomName.isEmpty)
                    .opacity(roomName.isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func saveRoom() {
        let room = Room(
            name: roomName,
            location: location.isEmpty ? nil : location
        )
        
        coreDataManager.addRoom(room)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Room View
struct EditRoomView: View {
    let room: Room
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var roomName: String
    @State private var location: String
    
    init(room: Room) {
        self.room = room
        _roomName = State(initialValue: room.name)
        _location = State(initialValue: room.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.lg) {
                    FloatingTextField(title: "Room Name *", text: $roomName)
                        .cardStyle()
                    
                    FloatingTextField(title: "Location (Optional)", text: $location)
                        .cardStyle()
                    
                    Spacer()
                    
                    Button(action: saveRoom) {
                        Text("Save Changes")
                    }
                    .primaryButtonStyle()
                    .disabled(roomName.isEmpty)
                    .opacity(roomName.isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func saveRoom() {
        // In a real implementation, you'd update the room
        presentationMode.wrappedValue.dismiss()
    }
}
