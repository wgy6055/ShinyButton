//
//  ViewController.swift
//  ShinyButton
//
//  Created by Wang Guanyu on 2023/4/6.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .init(hexInt: 0xe0e0e0)

        let button = ShinyButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Button", for: .normal)
        button.setTitleColor(.black.withAlphaComponent(0.7), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 48, weight: .semibold)
        button.layer.cornerRadius = 50
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 300),
            button.heightAnchor.constraint(equalToConstant: 100),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        button.startCapture()
    }

}

extension UIColor {

    convenience init(hexInt: Int, alpha: CGFloat = 1) {
        let componentMask = 0xff
        self.init(
            red: CGFloat((hexInt >> 16) & componentMask) / 255,
            green: CGFloat((hexInt >> 8) & componentMask) / 255,
            blue: CGFloat(hexInt & componentMask) / 255,
            alpha: alpha
        )
    }
}
