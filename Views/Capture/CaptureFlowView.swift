import SwiftUI
import UIKit

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var records: RecordsStore

    @State private var showPicker = false
    @State private var currentAngle: PhotoAngle = .front
    @State private var capturedFront: UIImage?
    @State private var capturedSide: UIImage?
    @State private var isSaving = false
    private let imageStore = ImageStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                progressSection
                captureButtons
                previews
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
                    handleCapture(image: image)
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("モード: \(settings.captureMode.title) | 横: \(settings.sideOrientation.title)")
                .font(.subheadline)
            Label(currentStepDescription, systemImage: "camera.viewfinder")
                .font(.headline)
        }
    }

    private var captureButtons: some View {
        HStack {
            if settings.captureMode.requiresFront {
                Button(action: { beginCapture(angle: .front) }) {
                    Label("前を撮影", systemImage: "person.crop.square")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            if settings.captureMode.requiresSide {
                Button(action: { beginCapture(angle: .side(settings.sideOrientation)) }) {
                    Label("横を撮影", systemImage: "person.crop.rectangle")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var previews: some View {
        VStack(spacing: 12) {
            if let front = capturedFront, settings.captureMode.requiresFront {
                CapturePreview(title: "前", image: front, aspectMode: settings.aspectMode) {
                    beginCapture(angle: .front)
                }
            }
            if let side = capturedSide, settings.captureMode.requiresSide {
                let title = settings.sideOrientation == .right ? "横（右向き）" : "横（左向き）"
                CapturePreview(title: title, image: side, aspectMode: settings.aspectMode) {
                    beginCapture(angle: .side(settings.sideOrientation))
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
        .disabled(!canSave)
        .buttonStyle(.borderedProminent)
    }

    private var canSave: Bool {
        (!settings.captureMode.requiresFront || capturedFront != nil) && (!settings.captureMode.requiresSide || capturedSide != nil)
    }

    private var currentStepDescription: String {
        switch currentAngle {
        case .front: return "前を撮影してください"
        case .side(let orientation): return orientation == .right ? "横（右向き）を撮影してください" : "横（左向き）を撮影してください"
        }
    }

    private func beginCapture(angle: PhotoAngle) {
        currentAngle = angle
        showPicker = true
    }

    private func handleCapture(image: UIImage?) {
        guard let image else { return }
        switch currentAngle {
        case .front:
            capturedFront = image
        case .side:
            capturedSide = image
        }
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        Task {
            do {
                let today = Date()
                if let front = capturedFront, settings.captureMode.requiresFront {
                    let url = try imageStore.save(image: front, for: today, angle: .front)
                    records.upsertFront(for: today, imagePath: url.path)
                }
                if let side = capturedSide, settings.captureMode.requiresSide {
                    let url = try imageStore.save(image: side, for: today, angle: .side(settings.sideOrientation))
                    records.upsertSide(for: today, imagePath: url.path, orientation: settings.sideOrientation)
                }
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
    let aspectMode: AspectMode
    let retake: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).bold()
            imageView
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Button("撮り直し", action: retake)
                .font(.footnote)
        }
    }

    private var imageView: some View {
        let uiImage = image
        let base = Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
        return Group {
            if aspectMode == .fourByFive {
                base
                    .aspectRatio(4.0/5.0, contentMode: .fit)
                    .clipped()
            } else {
                base
                    .scaledToFit()
            }
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
