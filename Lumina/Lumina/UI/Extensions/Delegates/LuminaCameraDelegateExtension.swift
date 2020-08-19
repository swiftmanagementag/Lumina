//
//  LuminaCameraDelegateExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import CoreML
import Foundation

extension LuminaViewController: LuminaCameraDelegate {
    func videoFrameCaptured(camera _: LuminaCamera, frame: UIImage, predictedObjects: [LuminaRecognitionResult]?) {
        delegate?.streamed(videoFrame: frame, with: predictedObjects, from: self)
    }

    func videoRecordingCaptured(camera _: LuminaCamera, videoURL: URL) {
        delegate?.captured(videoAt: videoURL, from: self)
    }

    func finishedFocus(camera _: LuminaCamera) {
        DispatchQueue.main.async {
            self.isUpdating = false
        }
    }

    func stillImageCaptured(camera: LuminaCamera, image: UIImage, livePhotoURL: URL?, depthData: Any?) {
        camera.currentPhotoCollection = nil
        delegate?.captured(stillImage: image, livePhotoAt: livePhotoURL, depthData: depthData, from: self)
    }

    func videoFrameCaptured(camera _: LuminaCamera, frame: UIImage) {
        delegate?.streamed(videoFrame: frame, from: self)
    }

    func detected(camera _: LuminaCamera, metadata: [Any]) {
        delegate?.detected(metadata: metadata, from: self)
    }

    func cameraSetupCompleted(camera _: LuminaCamera, result: CameraSetupResult) {
        handleCameraSetupResult(result)
    }

    func cameraBeganTakingLivePhoto(camera _: LuminaCamera) {
        DispatchQueue.main.async {
            self.textPrompt = "Capturing live photo..."
        }
    }

    func cameraFinishedTakingLivePhoto(camera _: LuminaCamera) {
        DispatchQueue.main.async {
            self.textPrompt = ""
        }
    }

    func depthDataCaptured(camera _: LuminaCamera, depthData: Any) {
        delegate?.streamed(depthData: depthData, from: self)
    }
}
