import SwiftUI

struct ThumbnailView: View {
    let image: UIImage
    let aspectMode: AspectMode

    var body: some View {
        FlexibleImage(image: image, aspectMode: aspectMode)
            .frame(width: 64, height: 80)
            .clipped()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
    }
}
