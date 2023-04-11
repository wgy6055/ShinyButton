//
//  ShinyButton.swift
//  ShinyButton
//
//  Created by Wang Guanyu on 2023/4/7.
//

import UIKit

class ShinyButton: UIButton {

    private lazy var captureView = {
        let view = CaptureView()
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var innerShadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOffset = .init(width: 0, height: 2)
        layer.shadowOpacity = 1
        layer.shadowRadius = 5
        layer.fillRule = .evenOdd
        return layer
    }()

    private lazy var fingerprintContainer: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var outerLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor(hexInt: 0xf4f4f4).cgColor
        layer.fillRule = .evenOdd
        layer.opacity = 0.5
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupSubviews()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = isHighlighted ? 0 : 0.4;
        layer.shadowRadius = 8
        layer.shadowOffset = .init(width: 0, height: 8)
        layer.shadowPath = UIBezierPath(
            roundedRect: .init(origin: .zero, size: frame.size),
            cornerRadius: layer.cornerRadius
        ).cgPath

        captureView.layer.cornerRadius = layer.cornerRadius

        fingerprintContainer.layer.cornerRadius = layer.cornerRadius
        bringSubviewToFront(fingerprintContainer)

        updateInnerShadow()
        updateOuterLayer()
    }

    // MARK: - Private Method

    private func setupSubviews() {
        addSubview(captureView)
        addSubview(fingerprintContainer)

        sendSubviewToBack(captureView)

        NSLayoutConstraint.activate([
            captureView.leftAnchor.constraint(equalTo: leftAnchor),
            captureView.rightAnchor.constraint(equalTo: rightAnchor),
            captureView.topAnchor.constraint(equalTo: topAnchor),
            captureView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        NSLayoutConstraint.activate([
            fingerprintContainer.leftAnchor.constraint(equalTo: leftAnchor),
            fingerprintContainer.rightAnchor.constraint(equalTo: rightAnchor),
            fingerprintContainer.topAnchor.constraint(equalTo: topAnchor),
            fingerprintContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        layer.addSublayer(innerShadowLayer)
        layer.addSublayer(outerLayer)
    }

    private func updateInnerShadow() {
        let shadowPath = CGMutablePath()
        let inset: CGFloat = 10
        let outerBounds = bounds.insetBy(dx: -inset, dy: -inset)
        let innerBounds = bounds.insetBy(dx: -1, dy: -1)
        shadowPath.addRoundedRect(in: outerBounds, cornerWidth: outerBounds.height * 0.5, cornerHeight: outerBounds.height * 0.5)
        shadowPath.addRoundedRect(in: innerBounds, cornerWidth: innerBounds.height * 0.5, cornerHeight: innerBounds.height * 0.5)

        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height * 0.5).cgPath
        innerShadowLayer.mask = maskLayer
        innerShadowLayer.path = shadowPath
        innerShadowLayer.shadowColor = isHighlighted ? UIColor.black.cgColor : UIColor.white.cgColor
        innerShadowLayer.shadowOpacity = isHighlighted ? 0.5 : 1
    }

    private func updateOuterLayer() {
        let inset: CGFloat = 5
        let outerBounds = bounds.insetBy(dx: 0, dy: -inset)
        let path = CGMutablePath()
        path.addRoundedRect(in: outerBounds, cornerWidth: outerBounds.height * 0.5, cornerHeight: outerBounds.height * 0.5)
        path.addRoundedRect(in: bounds, cornerWidth: bounds.height * 0.5, cornerHeight: bounds.height * 0.5)

        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: outerBounds, cornerRadius: outerBounds.height * 0.5).cgPath
        outerLayer.mask = maskLayer
        outerLayer.path = path
        outerLayer.isHidden = !isHighlighted
    }

    private func setupGesture() {
        addTarget(self, action: #selector(touchDown(sender:for:)), for: .touchDown)
        addTarget(self, action: #selector(touchDragEnter), for: .touchDragEnter)
        addTarget(self, action: #selector(touchUp), for: .touchUpInside)
        addTarget(self, action: #selector(touchUp), for: .touchUpOutside)
        addTarget(self, action: #selector(touchUp), for: .touchCancel)
        addTarget(self, action: #selector(touchUp), for: .touchDragExit)
    }

    @objc
    private func touchDown(sender: UIButton, for event: UIEvent) {
        UIView.animate(withDuration: 0.03) {
            self.transform = .init(scaleX: 0.95, y: 0.95)
        }
        setNeedsLayout()
        if let touch = event.touches(for: sender)?.first {
            let point = touch.location(in: sender)
            addFingerprint(at: point)
        }
    }

    @objc
    private func touchDragEnter() {
        UIView.animate(withDuration: 0.03) {
            self.transform = .init(scaleX: 0.95, y: 0.95)
        }
        setNeedsLayout()
    }

    @objc
    private func touchUp() {
        UIView.animate(withDuration: 0.03) {
            self.transform = .identity
        }
        setNeedsLayout()
    }

    private func addFingerprint(at point: CGPoint) {
        let fingerprint = Fingerprint()
        fingerprint.frame = .init(origin: .zero, size: .init(width: 80, height: 80))
        fingerprint.center = point
        fingerprintContainer.addSubview(fingerprint)
    }

    // MARK: Public Method

    func startCapture() {
        captureView.startCapture()
    }

    func stopCapture() {
        captureView.stopCapture()
    }
}
