import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func didScanBarcode(_ code: String) {
            parent.scannedCode = code
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func didFailScanning(with error: String) {
            print("Barcode scanning error: \(error)")
        }
    }
}

protocol BarcodeScannerDelegate: AnyObject {
    func didScanBarcode(_ code: String)
    func didFailScanning(with error: String)
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeScannerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let scannerOverlay = ScannerOverlayView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScanner()
        setupUI()
    }
    
    private func setupScanner() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFailScanning(with: "Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didFailScanning(with: "Could not create video input")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didFailScanning(with: "Could not add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .qr, .code128, .code39, .code93, .upce
            ]
        } else {
            delegate?.didFailScanning(with: "Could not add metadata output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    private func setupUI() {
        // Add overlay
        scannerOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerOverlay)
        
        NSLayoutConstraint.activate([
            scannerOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            scannerOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scannerOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Align barcode within frame"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanBarcode(stringValue)
        }
    }
}

class ScannerOverlayView: UIView {
    private let scannerFrame = CGRect(x: 50, y: 200, width: UIScreen.main.bounds.width - 100, height: 200)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Dimmed overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        context.fill(rect)
        
        // Clear scanning area
        context.setBlendMode(.clear)
        context.fill(scannerFrame)
        context.setBlendMode(.normal)
        
        // Draw corners
        let cornerLength: CGFloat = 30
        let cornerWidth: CGFloat = 4
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(cornerWidth)
        context.setLineCap(.round)
        
        // Top-left corner
        context.move(to: CGPoint(x: scannerFrame.minX, y: scannerFrame.minY + cornerLength))
        context.addLine(to: CGPoint(x: scannerFrame.minX, y: scannerFrame.minY))
        context.addLine(to: CGPoint(x: scannerFrame.minX + cornerLength, y: scannerFrame.minY))
        
        // Top-right corner
        context.move(to: CGPoint(x: scannerFrame.maxX - cornerLength, y: scannerFrame.minY))
        context.addLine(to: CGPoint(x: scannerFrame.maxX, y: scannerFrame.minY))
        context.addLine(to: CGPoint(x: scannerFrame.maxX, y: scannerFrame.minY + cornerLength))
        
        // Bottom-right corner
        context.move(to: CGPoint(x: scannerFrame.maxX, y: scannerFrame.maxY - cornerLength))
        context.addLine(to: CGPoint(x: scannerFrame.maxX, y: scannerFrame.maxY))
        context.addLine(to: CGPoint(x: scannerFrame.maxX - cornerLength, y: scannerFrame.maxY))
        
        // Bottom-left corner
        context.move(to: CGPoint(x: scannerFrame.minX + cornerLength, y: scannerFrame.maxY))
        context.addLine(to: CGPoint(x: scannerFrame.minX, y: scannerFrame.maxY))
        context.addLine(to: CGPoint(x: scannerFrame.minX, y: scannerFrame.maxY - cornerLength))
        
        context.strokePath()
    }
}
