//
//  DepthDataExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVFoundation
import Foundation

@available(iOS 11.0, *)
extension LuminaCamera: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp _: CMTime, connection _: AVCaptureConnection) {
        DispatchQueue.main.async {
            self.delegate?.depthDataCaptured(camera: self, depthData: depthData)
        }
    }

    func depthDataOutput(_: AVCaptureDepthDataOutput, didDrop _: AVDepthData, timestamp _: CMTime, connection _: AVCaptureConnection, reason _: AVCaptureOutput.DataDroppedReason) {
        LuminaLogger.error(message: "dropped depth data output")
    }
}
