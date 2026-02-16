import SwiftUI

struct ImageViewerView: View {
    let images: [ItemImage]
    @Binding var selectedIndex: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(images.indices, id: \.self) { index in
                    if let uiImage = UIImage(data: images[index].imageData) {
                        ZoomableImage(image: uiImage)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Image counter
                Text("\(selectedIndex + 1) / \(images.count)")
                    .font(Theme.Fonts.body())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 40)
            }
        }
    }
}

struct ZoomableImage: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = max(1.0, min(scale * delta, 5.0))
                    }
                    .onEnded { value in
                        lastScale = 1.0
                        if scale < 1.0 {
                            withAnimation {
                                scale = 1.0
                            }
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    scale = scale > 1.0 ? 1.0 : 2.0
                }
            }
    }
}
