import SwiftUI

struct ScreenBackdrop<Content: View>: View {
    let imageName: String
    let dim: Double
    let content: Content

    init(imageName: String, dim: Double = 0.16, @ViewBuilder content: () -> Content) {
        self.imageName = imageName
        self.dim = dim
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Palette.bg.overlay {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .opacity(dim)
                }
                .overlay(Color.black.opacity(0.28))
                .clipped()
                .ignoresSafeArea()
            }
    }
}
