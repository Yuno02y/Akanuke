import SwiftUI

struct ThumbnailView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 80)
            .clipped()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
    }
}
