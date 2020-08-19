//
//  LuminaTextPromptView.swift
//  Lumina
//
//  Created by David Okun on 5/7/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

enum LuminaTextError: Error {
    case fontError
}

extension UIFont {
    static func fontsURLs() -> [URL]? {
        let bundle = Bundle(identifier: "com.okun.io.Lumina")
        let fileNames = ["IBMPlexSans-SemiBold"]
        let newNames = fileNames.map { bundle?.url(forResource: $0, withExtension: "ttf") }
        return newNames as? [URL]
    }

    static func register(from url: URL) throws {
        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
            throw LuminaTextError.fontError
        }
        guard let font = CGFont(fontDataProvider) else {
            throw LuminaTextError.fontError
        }
        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterGraphicsFont(font, &error) else {
            throw error!.takeUnretainedValue()
        }
    }
}

final class LuminaTextPromptView: UIView {
    private var textLabel = UILabel()

    private lazy var blurView: UIVisualEffectView? = {
        var blurEffect: UIBlurEffect = UIBlurEffect()

        if #available(iOS 10.0, *) { // iOS 10.0 and above
            blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light) // prominent,regular,extraLight, light, dark
        } else { // iOS 8.0 and above
            blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark) // extraLight, light, dark
        }
        let bView = UIVisualEffectView(effect: blurEffect)
        bView.frame = self.frame // your view that have any objects
        bView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return bView
    }()

    private static let animationDuration = 0.3

    init() {
        super.init(frame: CGRect.zero)
        if let bView = blurView {
            addSubview(bView)
        }

        textLabel = UILabel()
        textLabel.backgroundColor = UIColor.clear

        textLabel.textColor = UIColor.darkText
        textLabel.textAlignment = .center
        /*
         do {
             if let fonts = UIFont.fontsURLs() {
                 try fonts.forEach { try UIFont.register(from: $0) }
             }
         } catch {
             LuminaLogger.debug(message: "Special fonts already registered")
         }
         if let font = UIFont(name: "IBM Plex Sans", size: 22) {
             self.textLabel.font = font
         } else {
             self.textLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
         }
         */
        textLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping

//        self.textLabel.minimumScaleFactor = 10/UIFont.labelFontSize
//        self.textLabel.adjustsFontSizeToFitWidth = true
//        self.textLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
//        self.textLabel.layer.shadowOpacity = 1
//        self.textLabel.layer.shadowRadius = 6
        addSubview(textLabel)
        backgroundColor = UIColor.clear
        alpha = 0.0
//        self.layer.cornerRadius = 5.0
    }

    func updateText(to text: String) {
        DispatchQueue.main.async {
            if text.isEmpty {
                self.hide(andErase: true)
            } else {
                self.textLabel.text = text
                self.makeAppear()
            }
        }
    }

    func hide(andErase: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration, animations: {
                self.alpha = 0.0
            }, completion: { _ in
                if andErase {
                    self.textLabel.text = ""
                }
            })
        }
    }

    private func makeAppear() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: LuminaTextPromptView.animationDuration) {
                self.alpha = 1
            }
        }
    }

    override func layoutSubviews() {
        let margin: CGFloat = 4.0
        var minY = frame.minY
        if #available(iOS 11, *) {
            minY = self.safeAreaLayoutGuide.layoutFrame.minY
        }
        textLabel.frame = CGRect(origin: CGPoint(x: margin, y: minY + margin), size: CGSize(width: frame.width - 2 * margin, height: frame.height - 2 * margin - minY))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
