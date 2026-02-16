import SwiftUI

struct RoomPickerView: View {
    @Binding var selectedRoom: Room?
    let rooms: [Room]
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddRoom = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                if rooms.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.sm) {
                            ForEach(rooms) { room in
                                Button(action: {
                                    selectedRoom = room
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    HStack(spacing: Theme.Spacing.md) {
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Theme.Colors.gold)
                                            .frame(width: 40, height: 40)
                                            .background(Theme.Colors.gold.opacity(0.1))
                                            .cornerRadius(10)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(room.name)
                                                .font(Theme.Fonts.body())
                                                .foregroundColor(Theme.Colors.textPrimary)
                                            
                                            if let location = room.location {
                                                Text(location)
                                                    .font(Theme.Fonts.caption())
                                                    .foregroundColor(Theme.Colors.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedRoom?.id == room.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Theme.Colors.accent)
                                        }
                                    }
                                    .padding()
                                    .cardStyle()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddRoom = true }) {
                        Image(systemName: "plus.circle.fill")
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
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No Rooms Yet")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text("Create a room to organize your items")
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
}
