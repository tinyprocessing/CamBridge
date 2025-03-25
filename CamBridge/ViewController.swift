import AVFoundation
import Combine
import Foundation
import UIKit

protocol CameraFeedSource {
    func startCapture()
}

class RealCameraFeed: CameraFeedSource {
    private let captureSession = AVCaptureSession()
    private let previewLayer: AVCaptureVideoPreviewLayer

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
    }

    func startCapture() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        captureSession.addInput(input)
        previewLayer.session = captureSession
        previewLayer.videoGravity = .resizeAspectFill
        captureSession.startRunning()
    }
}

class MockCameraFeed: CameraFeedSource {
    private weak var view: UIView?
    private var imageView = UIImageView()
    private var cancellable: AnyCancellable?
    private var communicationManager: InterProcessCommunicator

    init(view: UIView, communicationManager: InterProcessCommunicator) {
        self.view = view
        self.communicationManager = communicationManager
        setupImageView()
        subscribeToImagePublisher()
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view?.bounds ?? .zero
        view?.addSubview(imageView)
    }

    private func subscribeToImagePublisher() {
        cancellable = communicationManager.imagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.imageView.image = image
            }
    }

    func startCapture() {}

    func stopCapture() {
        cancellable?.cancel()
        cancellable = nil
    }
}

class ViewController: UIViewController {
    private var cameraFeed: CameraFeedSource?
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let communicationManager = InterProcessCommunicator()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraFeed()
        communicationManager.connect()
    }

    private func setupCameraFeed() {
        #if targetEnvironment(simulator)
        cameraFeed = MockCameraFeed(view: view, communicationManager: communicationManager)
        #else
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        cameraFeed = RealCameraFeed(previewLayer: previewLayer)
        #endif
        cameraFeed?.startCapture()
    }
}
