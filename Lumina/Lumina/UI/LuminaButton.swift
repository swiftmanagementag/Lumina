//
//  LuminaButton.swift
//  Lumina
//
//  Created by David Okun on 9/11/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

enum SystemButtonType {
    enum FlashState {
        // swiftlint:disable identifier_name
        case on
        case off
        case auto
    }

    case torch
    case cameraSwitch
    case photoCapture
    case cancel
    case shutter
}

final class LuminaButton: UIButton {
    private var squareSystemButtonWidth = 40
    private var squareSystemButtonHeight = 40
    private var cancelButtonWidth = 44
    private var cancelButtonHeight = 44
    private var shutterButtonDimension = 70
    private var style: SystemButtonType?
    private var border: UIView?
    private var _image: UIImage?
    var image: UIImage? {
        get {
            return _image
        }
        set {
            setImage(newValue, for: UIControl.State.normal)
            _image = newValue
        }
    }

    private var _text: String?
    var text: String? {
        get {
            return _text
        }
        set {
            self.setTitle(newValue, for: UIControl.State.normal)
            _text = newValue
        }
    }

    required init() {
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        if let titleLabel = self.titleLabel {
            titleLabel.textColor = UIColor.white
            titleLabel.font = UIFont.systemFont(ofSize: 20)
            titleLabel.textAlignment = .center
        }
    }

    init(with systemStyle: SystemButtonType) {
        super.init(frame: CGRect.zero)
        style = systemStyle
        backgroundColor = UIColor.clear
        if let titleLabel = self.titleLabel {
            titleLabel.textColor = UIColor.white
            titleLabel.font = UIFont.systemFont(ofSize: 20)
        }
        switch systemStyle {
        case .torch:
            image = UIImage(named: "cameraTorchOff", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            frame = CGRect(origin: CGPoint(x: 16, y: 126), size: CGSize(width: squareSystemButtonWidth, height: squareSystemButtonHeight))
        // addButtonShadowEffects()
        case .cameraSwitch:
            image = UIImage(named: "cameraSwitch", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.maxX - 56, y: 16), size: CGSize(width: squareSystemButtonWidth, height: squareSystemButtonHeight))
        //  addButtonShadowEffects()
        case .cancel:
            text = "x"
            // Positioning change
            frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.maxX - 56, y: UIScreen.main.bounds.minY + 56), size: CGSize(width: cancelButtonWidth, height: cancelButtonHeight))
            print(frame)
            layer.cornerRadius = CGFloat(cancelButtonWidth) / 2.0
            layer.masksToBounds = true
            backgroundColor = UIColor.black
            alpha = 0.8
            contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0)
            titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 32)
        // self.titleLabel?.textColor = UIColor.white
        //			self.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 0)
        // self.titleLabel?.layer.shadowOpacity = 0
//            self.titleLabel?.layer.shadowRadius = 0
        case .shutter:
            backgroundColor = UIColor.normalState
            var minY = UIScreen.main.bounds.maxY
            if #available(iOS 11, *) {
                minY = self.safeAreaLayoutGuide.layoutFrame.maxY
            }
            minY -= 80
            frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.midX - 35, y: minY), size: CGSize(width: shutterButtonDimension, height: shutterButtonDimension))
            layer.cornerRadius = CGFloat(shutterButtonDimension / 2)
            layer.borderWidth = 3
            layer.borderColor = UIColor.borderNormalState
        default:
            break
        }
    }

    private func addButtonShadowEffects() {
        layer.shadowOffset = CGSize(width: 0, height: 0)
        // remove shadow
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
    }

    func startRecordingVideo() {
        if style == .shutter {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = UIColor.recordingState
                    self.layer.borderColor = UIColor.borderRecordingState
                    self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                })
            }
        }
    }

    func stopRecordingVideo() {
        if style == .shutter {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = UIColor.normalState
                    self.layer.borderColor = UIColor.borderNormalState
                    self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                })
            }
        }
    }

    func takePhoto() {
        if style == .shutter {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = UIColor.takePhotoState
                    self.layer.borderColor = UIColor.borderTakePhotoState
                }, completion: { _ in
                    UIView.animate(withDuration: 0.1, animations: {
                        self.backgroundColor = UIColor.normalState
                        self.layer.borderColor = UIColor.borderNormalState
                    })
                })
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension LuminaButton {
    func updateTorchIcon(to state: SystemButtonType.FlashState) {
        guard let style = self.style, style == .torch else {
            return
        }
        switch state {
        case .on:
            image = UIImage(named: "cameraTorchOn", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            LuminaLogger.debug(message: "torch icon updated to on")
        case .off:
            image = UIImage(named: "cameraTorchOff", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            LuminaLogger.debug(message: "torch icon updated to off")
        case .auto:
            image = UIImage(named: "cameraTorchAuto", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            LuminaLogger.debug(message: "torch icon updated to auto")
        }
    }
}

private extension UIColor {
    class var normalState: UIColor {
        return UIColor(white: 1.0, alpha: 0.65)
    }

    class var recordingState: UIColor {
        return UIColor.red.withAlphaComponent(0.65)
    }

    class var takePhotoState: UIColor {
        return UIColor.lightGray.withAlphaComponent(0.65)
    }

    class var borderNormalState: CGColor {
        return UIColor.gray.cgColor
    }

    class var borderRecordingState: CGColor {
        return UIColor.red.cgColor
    }

    class var borderTakePhotoState: CGColor {
        return UIColor.darkGray.cgColor
    }
}
