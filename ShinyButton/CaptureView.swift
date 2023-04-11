//
//  CaptureView.swift
//  ShinyButton
//
//  Created by Wang Guanyu on 2023/4/11.
//

import UIKit
import AVFoundation
import MetalKit
import CoreImage

class CaptureView: UIView {

    private var session: AVCaptureSession?

    private lazy var renderView: MTKView = {
        let view = MTKView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var device: MTLDevice! = MTLCreateSystemDefaultDevice()

    private lazy var commandQueue = device.makeCommandQueue()

    private lazy var context = CIContext(mtlDevice: device)

    private var currentImage: CIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        setupSubview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Method

    private func setupSubview() {
        addSubview(renderView)

        NSLayoutConstraint.activate([
            renderView.leftAnchor.constraint(equalTo: leftAnchor),
            renderView.rightAnchor.constraint(equalTo: rightAnchor),
            renderView.topAnchor.constraint(equalTo: topAnchor),
            renderView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupCaptureSession() {
        stopCapture()

        let session = AVCaptureSession()
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ), let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            return
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        output.connections.first?.videoOrientation = .portrait
        output.connections.first?.isVideoMirrored = true

        session.commitConfiguration()
        self.session = session
    }

    private func setupMetal() {
        renderView.device = device
        renderView.isPaused = true
        renderView.enableSetNeedsDisplay = false
        renderView.framebufferOnly = false
    }

    // MARK: Public Method

    func startCapture() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupMetal()
            setupCaptureSession()
            DispatchQueue.global().async {
                self.session?.startRunning()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    return
                }
                self.setupMetal()
                self.setupCaptureSession()
                DispatchQueue.global().async {
                    self.session?.startRunning()
                }
            }
        default:
            break
        }
    }

    func stopCapture() {
        guard session?.isRunning ?? false else {
            return
        }
        DispatchQueue.global().async {
            self.session?.stopRunning()
        }
    }
}

extension CaptureView: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        guard let buffer = commandQueue?.makeCommandBuffer(),
              let image = currentImage,
              let drawable = view.currentDrawable,
              let filteredImage = applyFilter(image: image) else {
            return
        }

        let offsetY = (view.drawableSize.height - filteredImage.extent.height) / 2 + 200
        let offsetX = (view.drawableSize.width - filteredImage.extent.width) / 2

        context.render(
            filteredImage,
            to: drawable.texture,
            commandBuffer: buffer,
            bounds: .init(origin: .init(x: -offsetX, y: -offsetY), size: view.drawableSize),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        buffer.present(drawable)
        buffer.commit()
    }

    private func applyFilter(image: CIImage) -> CIImage? {
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(image, forKey: kCIInputImageKey)
        blurFilter?.setValue(10, forKey: kCIInputRadiusKey)
        var outputImage = blurFilter?.value(forKey: kCIOutputImageKey) as? CIImage

        let colorFilter = CIFilter(name: "CIColorControls")
        colorFilter?.setValue(outputImage, forKey: kCIInputImageKey)
        colorFilter?.setValue(0.15, forKey: kCIInputBrightnessKey)
        colorFilter?.setValue(0.4, forKey: kCIInputSaturationKey)
//        colorFilter?.setValue(0.7, forKey: kCIInputContrastKey)
        outputImage = colorFilter?.value(forKey: kCIOutputImageKey) as? CIImage

        return outputImage
    }
}

extension CaptureView: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let image = CIImage(cvImageBuffer: buffer)

        currentImage = image
        renderView.draw()
    }
}

