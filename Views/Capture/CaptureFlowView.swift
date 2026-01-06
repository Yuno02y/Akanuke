import SwiftUI
import UIKit

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var records: RecordsStore

    @State private var showPicker = false
    @State private var capturedFront: UIImage?
    @State private var isSaving = false
    private let imageStore = ImageStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                progressSection
                captureButton
                preview
                Spacer()
                saveButton
            }
            .padding()
            .navigationTitle("撮影")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(sourceType: .camera) { image in
                    capturedFront = image
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("前を撮影してください", systemImage: "camera.viewfinder")
                .font(.headline)
        }
    }

    private var captureButton: some View {
        Button(action: { showPicker = true }) {
            Label("前を撮影", systemImage: "person.crop.square")
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }

    private var preview: some View {
        VStack(spacing: 12) {
            if let front = capturedFront {
                CapturePreview(title: "前", image: front) {
                    showPicker = true
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            if isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("保存")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
        }
        .disabled(capturedFront == nil)
        .buttonStyle(.borderedProminent)
    }

    private func save() {
        guard let front = capturedFront else { return }
        isSaving = true
        Task {
            do {
                let today = Date()
                let url = try imageStore.saveFront(image: front, for: today)
                records.upsertFront(for: today, imagePath: url.path)
                dismiss()
            } catch {
                print("save error: \(error)")
            }
            isSaving = false
        }
    }
}

struct CapturePreview: View {
    let title: String
    let image: UIImage
    let retake: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).bold()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Button("撮り直し", action: retake)
                .font(.footnote)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .camera
    var completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            let processed = image.flatMap { processImage($0, device: picker.cameraDevice) }
            completion(processed)
            picker.dismiss(animated: true)
        }

        private func processImage(_ image: UIImage, device: UIImagePickerController.CameraDevice) -> UIImage {
            let wasMirrored = image.imageOrientation.isMirrored
            let normalized = normalizeOrientation(image)
            let shouldMirror = device == .front && !wasMirrored
            guard shouldMirror else { return normalized }
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = normalized.scale
            let renderer = UIGraphicsImageRenderer(size: normalized.size, format: format)
            return renderer.image { ctx in
                ctx.cgContext.translateBy(x: normalized.size.width, y: 0)
                ctx.cgContext.scaleBy(x: -1, y: 1)
                normalized.draw(in: CGRect(origin: .zero, size: normalized.size))
            }
        }

        private func normalizeOrientation(_ image: UIImage) -> UIImage {
            if image.imageOrientation == .up { return image }
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = image.scale
            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        }
    }
}

private extension UIImage.Orientation {
    var isMirrored: Bool {
        switch self {
        case .upMirrored, .downMirrored, .leftMirrored, .rightMirrored:
            return true
        default:
            return false
        }
    }
}
