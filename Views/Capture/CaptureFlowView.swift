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
            completion(image)
            picker.dismiss(animated: true)
        }
    }
}
