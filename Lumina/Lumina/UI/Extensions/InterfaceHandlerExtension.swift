//
//  InterfaceHandlerExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVFoundation
import Foundation

extension LuminaViewController {
    @objc func handlePinchGestureRecognizer(recognizer: UIPinchGestureRecognizer) {
        guard position == .back else {
            return
        }
        currentZoomScale = min(maxZoomScale, max(1.0, beginZoomScale * Float(recognizer.scale)))
        LuminaLogger.notice(message: "setting zoom scale to \(currentZoomScale)")
    }

    @objc func handleTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        delegate?.tapped(at: recognizer.location(in: view), from: self)
        if position == .back {
            focusCamera(at: recognizer.location(in: view))
        }
    }

    func createUI() {
        LuminaLogger.notice(message: "Creating UI")
        view.layer.addSublayer(previewLayer)
        view.addSubview(textPromptView)
        view.addSubview(confidenceView)
        view.addSubview(cancelButton)
        view.addSubview(shutterButton)
        view.addSubview(switchButton)
        view.addSubview(torchButton)

        view.addGestureRecognizer(zoomRecognizer)
        view.addGestureRecognizer(focusRecognizer)

        enableUI(valid: false)
    }

    func enableUI(valid: Bool) {
        DispatchQueue.main.async {
            self.shutterButton.isEnabled = valid
            self.switchButton.isEnabled = valid
            self.torchButton.isEnabled = valid
        }
    }

    func updateUI(orientation: UIInterfaceOrientation) {
        LuminaLogger.notice(message: "updating UI for orientation: \(orientation.rawValue)")
        guard let connection = previewLayer.connection, connection.isVideoOrientationSupported else {
            return
        }
        previewLayer.frame = view.bounds
        connection.videoOrientation = necessaryVideoOrientation(for: orientation)
        camera?.updateOutputVideoOrientation(connection.videoOrientation)
    }

    func updateButtonFrames() {
        var maxY = view.frame.maxY
        var minY = view.frame.minY

        var maxX = view.frame.maxX
        var minX = view.frame.minX

        if #available(iOS 11, *) {
            minX = self.view.safeAreaLayoutGuide.layoutFrame.minX
            maxX = self.view.safeAreaLayoutGuide.layoutFrame.maxX
            minY = self.view.safeAreaLayoutGuide.layoutFrame.minY
            maxY = self.view.safeAreaLayoutGuide.layoutFrame.maxY
        }
        cancelButton.center = CGPoint(x: maxX - 38, y: minY + 30)

        if view.frame.width > view.frame.height {
            shutterButton.center = CGPoint(x: maxX - 45, y: view.frame.midY)
            switchButton.center = CGPoint(x: maxX - 45, y: maxY - 90)
            torchButton.center = CGPoint(x: maxX - 45, y: maxY - 30)
            //		self.cancelButton.center = CGPoint(x: self.view.frame.maxX - 36, y: minY + 36)
        } else {
            shutterButton.center = CGPoint(x: view.frame.midX, y: maxY - 45)
            switchButton.center = CGPoint(x: maxX - 30, y: maxY - 45)
            torchButton.center = CGPoint(x: minX + 30, y: maxY - 45)
            //		self.cancelButton.center = CGPoint(x: maxX - 36, y: self.view.frame.minY + 36)
        }

        textPromptView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height * 0.2)
        textPromptView.layoutSubviews()

        confidenceView.frame = CGRect(x: 0, y: textPromptView.frame.height - 2.0, width: view.frame.width, height: 2)
    }

    // swiftlint:disable cyclomatic_complexity
    func handleCameraSetupResult(_ result: CameraSetupResult) {
        LuminaLogger.notice(message: "camera set up result: \(result.rawValue)")
        DispatchQueue.main.async {
            switch result {
            case .videoSuccess:
                if let camera = self.camera {
                    self.enableUI(valid: true)
                    self.updateUI(orientation: UIApplication.shared.statusBarOrientation)
                    camera.start()
                }
            case .audioSuccess:
                break
            case .requiresUpdate:
                self.camera?.updateVideo { result in
                    self.handleCameraSetupResult(result)
                }
            case .videoPermissionDenied:
                self.textPrompt = "Camera permissions for Lumina have been previously denied - please access your privacy settings to change this."
            case .videoPermissionRestricted:
                self.textPrompt = "Camera permissions for Lumina have been restricted - please access your privacy settings to change this."
            case .videoRequiresAuthorization:
                self.camera?.requestVideoPermissions()
            case .audioPermissionRestricted:
                self.textPrompt = "Audio permissions for Lumina have been restricted - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
            case .audioRequiresAuthorization:
                self.camera?.requestAudioPermissions()
            case .audioPermissionDenied:
                self.textPrompt = "Audio permissions for Lumina have been previously denied - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
            case .invalidVideoDataOutput,
                 .invalidVideoInput,
                 .invalidPhotoOutput,
                 .invalidVideoMetadataOutput,
                 .invalidVideoFileOutput,
                 .invalidAudioInput,
                 .invalidDepthDataOutput:
                self.textPrompt = "\(result.rawValue) - please try again"
            case .unknownError:
                self.textPrompt = "Unknown error occurred while loading Lumina - please try again"
            }
        }
    }

    private func necessaryVideoOrientation(for statusBarOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch statusBarOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
}
