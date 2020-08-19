//
//  MetadataOutputDelegateExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVFoundation
import Foundation

extension LuminaCamera: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        LuminaLogger.notice(message: "metadata detected - \(metadataObjects)")
        guard case trackMetadata = true else {
            return
        }
        DispatchQueue.main.async {
            self.delegate?.detected(camera: self, metadata: metadataObjects)
        }
    }
}
