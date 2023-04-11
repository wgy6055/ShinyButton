//
//  Fingerprint.swift
//  ShinyButton
//
//  Created by Wang Guanyu on 2023/4/11.
//

import UIKit

class Fingerprint: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        setupLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Method

    private func setupLayer() {
        guard let layer = layer as? CAGradientLayer else {
            return
        }
        layer.type = .radial
        layer.colors = [
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        layer.startPoint = .init(x: 0.5, y: 0.5)
        layer.endPoint = .init(x: 1, y: 1)
    }
}
