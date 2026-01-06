import SwiftUI
import AVFoundation

/// Controls capture session lifecycle and photo capture.
final class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async {
            self.captureCompletion = completion
            let settings = AVCapturePhotoSettings()
            if let connection = self.photoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false // we'll bake mirroring manually
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let rawImage = UIImage(data: data)
        else {
            DispatchQueue.main.async { self.captureCompletion?(nil) }
            return
        }

        let normalized = rawImage.normalizedToUp()
        let mirrored = normalized.mirroredHorizontally()
        DispatchQueue.main.async { self.captureCompletion?(mirrored) }
    }

    // MARK: - Session configuration

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
    }
}

// MARK: - Preview

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var manager: CameraManager

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = manager.session
        applyMirroring(to: view.videoPreviewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        applyMirroring(to: uiView.videoPreviewLayer)
    }

    private func applyMirroring(to layer: AVCaptureVideoPreviewLayer) {
        if let connection = layer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            connection.automaticallyAdjustsVideoMirroring = false
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        layer.videoGravity = .resizeAspectFill
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - View

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var records: RecordsStore

    @StateObject private var cameraManager = CameraManager()
    @State private var capturedImage: UIImage?
    @State private var isSaving = false

    private let imageStore = ImageStore()

    var body: some View {
        NavigationStack {
            Group {
                if let image = capturedImage {
                    reviewView(image: image)
                } else {
                    cameraView
                }
            }
            .navigationTitle("撮影")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .onAppear { cameraManager.startSession() }
        .onDisappear { cameraManager.stopSession() }
    }

    private var cameraView: some View {
        VStack(spacing: 16) {
            Text("前を撮影してください")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                CameraPreview(manager: cameraManager)
                    .aspectRatio(4.0/5.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                FaceGuideOverlay()
                    .aspectRatio(4.0/5.0, contentMode: .fit)
                    .allowsHitTesting(false)
            }

            Spacer()

            Button(action: capture) {
                Text("シャッター")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }

    private func reviewView(image: UIImage) -> some View {
        VStack(spacing: 16) {
            Text("確認")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .aspectRatio(4.0/5.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack {
                Button("撮り直し") {
                    capturedImage = nil
                }
                .frame(maxWidth: .infinity)

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
                .disabled(isSaving)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private func capture() {
        cameraManager.capturePhoto { image in
            guard let image else { return }
            capturedImage = image
        }
    }

    private func save() {
        guard let image = capturedImage else { return }
        isSaving = true
        Task {
            do {
                let today = Date()
                let url = try imageStore.saveFront(image: image, for: today)
                records.upsertFront(for: today, imagePath: url.path)
                dismiss()
            } catch {
                print("save error: \(error)")
            }
            isSaving = false
        }
    }
}

// MARK: - Overlay

struct FaceGuideOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let ellipseWidth = width * 0.75
            let ellipseHeight = height * 0.7
            let ellipseRect = CGRect(
                x: (width - ellipseWidth) / 2,
                y: (height - ellipseHeight) / 2,
                width: ellipseWidth,
                height: ellipseHeight
            )

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)

                Path(ellipseIn: ellipseRect)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)

                let eyeY = ellipseRect.midY - ellipseHeight * 0.12
                let eyeOffsetX = ellipseWidth * 0.18
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 10, height: 10)
                    .position(x: ellipseRect.midX - eyeOffsetX, y: eyeY)
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 10, height: 10)
                    .position(x: ellipseRect.midX + eyeOffsetX, y: eyeY)
            }
        }
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    func normalizedToUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func mirroredHorizontally() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: size.width, y: 0)
            ctx.cgContext.scaleBy(x: -1, y: 1)
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
