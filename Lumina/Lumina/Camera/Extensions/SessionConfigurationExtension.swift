//
//  SessionConfigurationExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVFoundation
import Foundation

extension LuminaCamera {
    func requestVideoPermissions() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                LuminaLogger.notice(message: "successfully enabled video permissions")
                self.sessionQueue.resume()
                self.delegate?.cameraSetupCompleted(camera: self, result: .requiresUpdate)
            } else {
                LuminaLogger.warning(message: "video permissions were not allowed - video feed will not show")
                self.delegate?.cameraSetupCompleted(camera: self, result: .videoPermissionDenied)
            }
        }
    }

    func requestAudioPermissions() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { success in
            if success {
                LuminaLogger.notice(message: "successfully enabled audio permissions")
                self.sessionQueue.resume()
                self.delegate?.cameraSetupCompleted(camera: self, result: .requiresUpdate)
            } else {
                LuminaLogger.warning(message: "audio permissions were not allowed - audio feed will not be present")
                self.delegate?.cameraSetupCompleted(camera: self, result: .audioPermissionDenied)
            }
        }
    }

    func updateOutputVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        videoBufferQueue.async {
            for output in self.session.outputs {
                guard let connection = output.connection(with: AVMediaType.video) else {
                    continue
                }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation
                }
            }
        }
    }

    func restartVideo() {
        LuminaLogger.notice(message: "restarting video feed")
        if session.isRunning {
            stop()
            updateVideo { result in
                if result == .videoSuccess {
                    self.start()
                } else {
                    self.delegate?.cameraSetupCompleted(camera: self, result: result)
                }
            }
        }
    }

    func updateAudio(_ completion: @escaping (_ result: CameraSetupResult) -> Void) {
        sessionQueue.async {
            self.purgeAudioDevices()
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
            case .authorized:
                guard let audioInput = self.getNewAudioInputDevice() else {
                    return completion(CameraSetupResult.invalidAudioInput)
                }
                guard self.session.canAddInput(audioInput) else {
                    return completion(CameraSetupResult.invalidAudioInput)
                }
                self.audioInput = audioInput
                self.session.addInput(audioInput)
                return completion(CameraSetupResult.audioSuccess)
            case .denied:
                return completion(CameraSetupResult.audioPermissionDenied)
            case .notDetermined:
                return completion(CameraSetupResult.audioRequiresAuthorization)
            case .restricted:
                return completion(CameraSetupResult.audioPermissionRestricted)
            @unknown default:
                return completion(CameraSetupResult.unknownError)
            }
        }
    }

    func updateVideo(_ completion: @escaping (_ result: CameraSetupResult) -> Void) {
        sessionQueue.async {
            self.purgeVideoDevices()
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized:
                return completion(self.videoSetupApproved())
            case .denied:
                return completion(CameraSetupResult.videoPermissionDenied)
            case .notDetermined:
                return completion(CameraSetupResult.videoRequiresAuthorization)
            case .restricted:
                return completion(CameraSetupResult.videoPermissionRestricted)
            @unknown default:
                return completion(CameraSetupResult.unknownError)
            }
        }
    }

    private func videoSetupApproved() -> CameraSetupResult {
        torchState = .off
        session.sessionPreset = .high // set to high here so that device input can be added to session. resolution can be checked for update later
        guard let videoInput = getNewVideoInputDevice() else {
            return .invalidVideoInput
        }
        if let failureResult = checkSessionValidity(for: videoInput) {
            return failureResult
        }
        self.videoInput = videoInput
        session.addInput(videoInput)
        if streamFrames {
            LuminaLogger.notice(message: "adding video data output to session")
            session.addOutput(videoDataOutput)
        }
        session.addOutput(photoOutput)
        session.commitConfiguration()
        if session.canSetSessionPreset(resolution.foundationPreset()) {
            LuminaLogger.notice(message: "creating video session with resolution: \(resolution.rawValue)")
            session.sessionPreset = resolution.foundationPreset()
        }
        configureVideoRecordingOutput(for: session)
        configureMetadataOutput(for: session)
        configureHiResPhotoOutput(for: session)
        configureLivePhotoOutput(for: session)
        configureDepthDataOutput(for: session)
        configureFrameRate()
        return .videoSuccess
    }

    private func checkSessionValidity(for input: AVCaptureDeviceInput) -> CameraSetupResult? {
        guard session.canAddInput(input) else {
            LuminaLogger.error(message: "cannot add video input")
            return .invalidVideoInput
        }
        guard session.canAddOutput(videoDataOutput) else {
            LuminaLogger.error(message: "cannot add video data output")
            return .invalidVideoDataOutput
        }
        guard session.canAddOutput(photoOutput) else {
            LuminaLogger.error(message: "cannot add photo output")
            return .invalidPhotoOutput
        }
        guard session.canAddOutput(metadataOutput) else {
            LuminaLogger.error(message: "cannot add video metadata output")
            return .invalidVideoMetadataOutput
        }
        if recordsVideo == true {
            guard session.canAddOutput(videoFileOutput) else {
                LuminaLogger.error(message: "cannot add video file output for recording video")
                return .invalidVideoFileOutput
            }
        }
        if #available(iOS 11.0, *), let depthDataOutput = depthDataOutput {
            guard self.session.canAddOutput(depthDataOutput) else {
                LuminaLogger.error(message: "cannot add depth data output with this settings map")
                return .invalidDepthDataOutput
            }
        }
        return nil
    }

    private func configureVideoRecordingOutput(for _: AVCaptureSession) {
        if recordsVideo {
            // adding this invalidates the video data output
            LuminaLogger.notice(message: "adding video file output")
            session.addOutput(videoFileOutput)
            if let connection = videoFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        }
    }

    private func configureHiResPhotoOutput(for _: AVCaptureSession) {
        if captureHighResolutionImages && photoOutput.isHighResolutionCaptureEnabled {
            LuminaLogger.notice(message: "enabling high resolution photo capture")
            photoOutput.isHighResolutionCaptureEnabled = true
        } else if captureHighResolutionImages {
            LuminaLogger.error(message: "cannot capture high resolution images with current settings")
            captureHighResolutionImages = false
        }
    }

    private func configureLivePhotoOutput(for _: AVCaptureSession) {
        if captureLivePhotos && photoOutput.isLivePhotoCaptureSupported {
            LuminaLogger.notice(message: "enabling live photo capture")
            photoOutput.isLivePhotoCaptureEnabled = true
        } else if captureLivePhotos {
            LuminaLogger.error(message: "cannot capture live photos with current settings")
            captureLivePhotos = false
        }
    }

    private func configureMetadataOutput(for session: AVCaptureSession) {
        if trackMetadata {
            LuminaLogger.notice(message: "adding video metadata output")
            session.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        }
    }

    private func configureDepthDataOutput(for session: AVCaptureSession) {
        if #available(iOS 11.0, *) {
            if self.captureDepthData && self.photoOutput.isDepthDataDeliverySupported {
                LuminaLogger.notice(message: "enabling depth data delivery")
                self.photoOutput.isDepthDataDeliveryEnabled = true
            } else if self.captureDepthData {
                LuminaLogger.error(message: "cannot capture depth data with these settings")
                self.captureDepthData = false
            }
        } else {
            LuminaLogger.error(message: "cannot capture depth data - must use iOS 11.0 or higher")
            captureDepthData = false
        }
        if #available(iOS 11.0, *) {
            if self.streamDepthData, let depthDataOutput = self.depthDataOutput {
                LuminaLogger.notice(message: "adding streaming depth data output to capture session")
                session.addOutput(depthDataOutput)
                session.commitConfiguration()
            }
        }
    }
}
