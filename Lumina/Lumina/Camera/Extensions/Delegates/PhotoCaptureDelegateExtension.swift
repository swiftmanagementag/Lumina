//
//  PhotoCaptureDelegateExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVFoundation
import Foundation

extension LuminaCamera: AVCapturePhotoCaptureDelegate {
    @available(iOS 11.0, *)
    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error _: Error?) {
        LuminaLogger.notice(message: "finished processing photo")
        guard let image = photo.normalizedImage(forCameraPosition: position) else {
            return
        }
        photoCollectionQueue.sync {
            if self.currentPhotoCollection == nil {
                var collection = LuminaPhotoCapture()
                collection.camera = self
                collection.depthData = photo.depthData
                collection.stillImage = image
                self.currentPhotoCollection = collection
            } else {
                guard var collection = self.currentPhotoCollection else {
                    return
                }
                collection.camera = self
                collection.depthData = photo.depthData
                collection.stillImage = image
                self.currentPhotoCollection = collection
            }
        }
    }

    // swiftlint:disable function_parameter_count
    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto _: CMSampleBuffer?, resolvedSettings _: AVCaptureResolvedPhotoSettings, bracketSettings _: AVCaptureBracketedStillImageSettings?, error _: Error?) {
        if #available(iOS 11.0, *) { // make use of AVCapturePhotoOutput
            LuminaLogger.warning(message: "using iOS 11.0 or better - discarding output in favor of AVCapturePhoto methods")
            return
        } else {
            guard let buffer = photoSampleBuffer else {
                return
            }
            guard let image = buffer.normalizedStillImage(forCameraPosition: position) else {
                return
            }
            delegate?.stillImageCaptured(camera: self, image: image, livePhotoURL: nil, depthData: nil)
        }
    }
}
