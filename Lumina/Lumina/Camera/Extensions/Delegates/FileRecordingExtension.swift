//
//  LuminaCamera+FileOutputRecordingDelegate.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVFoundation
import Foundation

extension LuminaCamera: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from _: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            if error == nil, let delegate = self.delegate {
                delegate.videoRecordingCaptured(camera: self, videoURL: outputFileURL)
            }
        }
    }

    func photoOutput(_: AVCapturePhotoOutput, willBeginCaptureFor _: AVCaptureResolvedPhotoSettings) {
        if captureLivePhotos {
            LuminaLogger.notice(message: "beginning live photo capture")
            delegate?.cameraBeganTakingLivePhoto(camera: self)
        }
    }

    func photoOutput(_: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt _: URL, resolvedSettings _: AVCaptureResolvedPhotoSettings) {
        if captureLivePhotos {
            LuminaLogger.notice(message: "finishing live photo capture")
            delegate?.cameraFinishedTakingLivePhoto(camera: self)
        }
    }

    // swiftlint:disable function_parameter_count
    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration _: CMTime, photoDisplayTime _: CMTime, resolvedSettings _: AVCaptureResolvedPhotoSettings, error _: Error?) {
        photoCollectionQueue.sync {
            if self.currentPhotoCollection == nil {
                var collection = LuminaPhotoCapture()
                collection.camera = self
                collection.livePhotoURL = outputFileURL
                self.currentPhotoCollection = collection
            } else {
                guard var collection = self.currentPhotoCollection else {
                    return
                }
                collection.camera = self
                collection.livePhotoURL = outputFileURL
                self.currentPhotoCollection = collection
            }
        }
    }
}
