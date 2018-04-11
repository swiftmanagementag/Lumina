//
//  InterfaceHandlerExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaViewController {
    @objc func handlePinchGestureRecognizer(recognizer: UIPinchGestureRecognizer) {
        guard self.position == .back else {
            return
        }
        currentZoomScale = min(maxZoomScale, max(1.0, beginZoomScale * Float(recognizer.scale)))
        Log.verbose("setting zoom scale to \(currentZoomScale)")
    }

    @objc func handleTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        delegate?.tapped(at: recognizer.location(in: view), from: self)
        if position == .back {
            focusCamera(at: recognizer.location(in: view))
        }
    }

    func createUI() {
        Log.verbose("Creating UI")
        self.view.layer.addSublayer(self.previewLayer)
		self.view.addSubview(self.textPromptView)
		self.view.addSubview(self.confidenceView)
		self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.shutterButton)
        self.view.addSubview(self.switchButton)
        self.view.addSubview(self.torchButton)
        self.view.addGestureRecognizer(self.zoomRecognizer)
        self.view.addGestureRecognizer(self.focusRecognizer)
		
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
        Log.verbose("updating UI for orientation: \(orientation.rawValue)")
        guard let connection = self.previewLayer.connection, connection.isVideoOrientationSupported else {
            return
        }
        self.previewLayer.frame = self.view.bounds
        connection.videoOrientation = necessaryVideoOrientation(for: orientation)
        self.camera?.updateOutputVideoOrientation(connection.videoOrientation)
    }

    func updateButtonFrames() {

		var maxY = self.view.frame.maxY
		var minY = self.view.frame.minY
		
		var maxX = self.view.frame.maxX
		var minX = self.view.frame.minX

		if #available(iOS 11, *) {
			minX = self.view.safeAreaLayoutGuide.layoutFrame.minX
			maxX = self.view.safeAreaLayoutGuide.layoutFrame.maxX
			minY = self.view.safeAreaLayoutGuide.layoutFrame.minY
			maxY = self.view.safeAreaLayoutGuide.layoutFrame.maxY
		}
		if self.view.frame.width > self.view.frame.height {
            self.shutterButton.center = CGPoint(x: maxX - 45, y: self.view.frame.midY)

			self.switchButton.center = CGPoint(x: maxX - 45, y: maxY - 90)
			self.torchButton.center = CGPoint(x: maxX - 45, y: maxY - 30)
		
			self.cancelButton.center = CGPoint(x: self.view.frame.maxX - 36, y: minY + 36)
		} else {
            self.shutterButton.center = CGPoint(x: self.view.frame.midX, y: maxY - 45)

			self.switchButton.center = CGPoint(x: maxX - 30, y: maxY - 45)
			self.torchButton.center = CGPoint(x: minX + 30, y: maxY - 45)
			self.cancelButton.center = CGPoint(x: maxX - 36, y: self.view.frame.minY + 36)
		}
		
		self.textPromptView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height * 0.2 )
		self.textPromptView.layoutSubviews()
		
		self.confidenceView.frame = CGRect(x: 0, y: self.textPromptView.frame.height - 2.0, width: self.view.frame.width, height: 2 )
    }

    // swiftlint:disable cyclomatic_complexity
    func handleCameraSetupResult(_ result: CameraSetupResult) {
        Log.verbose("camera set up result: \(result.rawValue)")
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
                self.camera?.updateVideo({ result in
                    self.handleCameraSetupResult(result)
                })
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
