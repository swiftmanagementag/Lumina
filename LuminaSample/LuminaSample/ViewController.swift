//
//  ViewController.swift
//  LuminaSample
//
//  Created by David Okun on 4/21/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import AVKit
import CoreML
import Lumina
import UIKit

class ViewController: UITableViewController {
    @IBOutlet var frontCameraSwitch: UISwitch!
    @IBOutlet var recordsVideoSwitch: UISwitch!
    @IBOutlet var trackImagesSwitch: UISwitch!
    @IBOutlet var trackMetadataSwitch: UISwitch!
    @IBOutlet var capturesLivePhotosSwitch: UISwitch!
    @IBOutlet var capturesDepthDataSwitch: UISwitch!
    @IBOutlet var streamsDepthDataSwitch: UISwitch!
    @IBOutlet var showTextPromptViewSwitch: UISwitch!
    @IBOutlet var frameRateLabel: UILabel!
    @IBOutlet var frameRateSlider: UISlider!
    @IBOutlet var useCoreMLModelSwitch: UISwitch!
    @IBOutlet var resolutionLabel: UILabel!
    @IBOutlet var loggingLevelLabel: UILabel!
    @IBOutlet var maxZoomScaleLabel: UILabel!
    @IBOutlet var maxZoomScaleSlider: UISlider!

    var selectedResolution: CameraResolution = .high1920x1080
    var selectedLoggingLevel: Logger.Level = .critical
    var depthView: UIImageView?
}

extension ViewController { // MARK: IBActions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loggingLevelLabel.text = selectedLoggingLevel.uppercasedStringRepresentation
        if let version = LuminaViewController.getVersion() {
            title = "Lumina Sample v\(version)"
        } else {
            title = "Lumina Sample"
        }
    }

    @IBAction func cameraButtonTapped() {
        LuminaViewController.loggingLevel = selectedLoggingLevel
        let camera = LuminaViewController()
        camera.delegate = self
        camera.position = frontCameraSwitch.isOn ? .front : .back
        camera.recordsVideo = recordsVideoSwitch.isOn
        camera.streamFrames = trackImagesSwitch.isOn
        camera.textPrompt = showTextPromptViewSwitch.isOn ? "This is how to test the text prompt view" : ""
        camera.trackMetadata = trackMetadataSwitch.isOn
        camera.captureLivePhotos = capturesLivePhotosSwitch.isOn
        camera.captureDepthData = capturesDepthDataSwitch.isOn
        camera.streamDepthData = streamsDepthDataSwitch.isOn
        camera.resolution = selectedResolution
        camera.maxZoomScale = (maxZoomScaleLabel.text! as NSString).floatValue
        camera.frameRate = Int(frameRateLabel.text!) ?? 30
        if #available(iOS 11.0, *), useCoreMLModelSwitch.isOn {
            camera.streamingModels = [LuminaModel(model: MobileNet().model, type: "MobileNet"), LuminaModel(model: SqueezeNet().model, type: "SqueezeNet")]
        }
        present(camera, animated: true, completion: nil)
    }

    @IBAction func frameRateSliderChanged() {
        frameRateLabel.text = String(Int(frameRateSlider.value))
    }

    @IBAction func zoomScaleSliderChanged() {
        maxZoomScaleLabel.text = String(format: "%.01f", maxZoomScaleSlider.value)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stillImageOutputSegue" {
            let controller = segue.destination as! ImageViewController
            if let map = sender as? [String: Any] {
                controller.image = map["stillImage"] as? UIImage
                controller.livePhotoURL = map["livePhotoURL"] as? URL
                if #available(iOS 11.0, *) {
                    controller.depthData = map["depthData"] as? AVDepthData
                }
                let positionBool = map["isPhotoSelfie"] as! Bool
                controller.position = positionBool ? .front : .back
            } else { return }
        } else if segue.identifier == "selectResolutionSegue" {
            let controller = segue.destination as! ResolutionViewController
            controller.delegate = self
        } else if segue.identifier == "selectLoggingLevelSegue" {
            let controller = segue.destination as! LoggingViewController
            controller.delegate = self
        }
    }
}

extension ViewController: LuminaDelegate {
    func streamed(videoFrame _: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {
        if #available(iOS 11.0, *) {
            guard let predicted = predictions else {
                return
            }
            var resultString = String()
            for prediction in predicted {
                guard let values = prediction.predictions else {
                    continue
                }
                guard let bestPrediction = values.first else {
                    continue
                }
                resultString.append("\(String(describing: prediction.type)): \(bestPrediction.name)" + "\r\n")
            }
            controller.textPrompt = resultString
        } else {
            print("CoreML not available in iOS 10.0")
        }
    }

    func captured(stillImage: UIImage, livePhotoAt: URL?, depthData: Any?, from controller: LuminaViewController) {
        controller.dismiss(animated: true) {
            self.performSegue(withIdentifier: "stillImageOutputSegue", sender: ["stillImage": stillImage, "livePhotoURL": livePhotoAt as Any, "depthData": depthData as Any, "isPhotoSelfie": controller.position == .front ? true : false])
        }
    }

    func captured(videoAt: URL, from controller: LuminaViewController) {
        controller.dismiss(animated: true) {
            let player = AVPlayer(url: videoAt)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
    }

    func detected(metadata: [Any], from _: LuminaViewController) {
        print(metadata)
    }

    func streamed(videoFrame _: UIImage, from _: LuminaViewController) {
        print("video frame received")
    }

    func streamed(depthData: Any, from controller: LuminaViewController) {
        if #available(iOS 11.0, *) {
            if let data = depthData as? AVDepthData {
                guard let image = data.depthDataMap.normalizedImage(with: controller.position) else {
                    print("could not convert depth data")
                    return
                }
                if let imageView = self.depthView {
                    imageView.removeFromSuperview()
                }
                let newView = UIImageView(frame: CGRect(x: controller.view.frame.minX, y: controller.view.frame.maxY - 300, width: 200, height: 200))
                newView.image = image
                newView.contentMode = .scaleAspectFit
                newView.backgroundColor = UIColor.clear
                controller.view.addSubview(newView)
                controller.view.bringSubviewToFront(newView)
            }
        }
    }

    func dismissed(controller: LuminaViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: LoggingLevelDelegate {
    func didSelect(loggingLevel: Logger.Level, controller _: LoggingViewController) {
        selectedLoggingLevel = loggingLevel
        navigationController?.popToViewController(self, animated: true)
    }
}

extension ViewController: ResolutionDelegate {
    func didSelect(resolution: CameraResolution, controller _: ResolutionViewController) {
        selectedResolution = resolution
        navigationController?.popToViewController(self, animated: true)
    }
}

extension CVPixelBuffer {
    func normalizedImage(with position: CameraPosition) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(self), height: CVPixelBufferGetHeight(self))) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: getImageOrientation(with: position))
        } else {
            return nil
        }
    }

    private func getImageOrientation(with position: CameraPosition) -> UIImage.Orientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return position == .back ? .down : .upMirrored
        case .landscapeRight:
            return position == .back ? .up : .downMirrored
        case .portraitUpsideDown:
            return position == .back ? .left : .rightMirrored
        case .portrait:
            return position == .back ? .right : .leftMirrored
        case .unknown:
            return position == .back ? .right : .leftMirrored
        @unknown default:
            return position == .back ? .right : .leftMirrored
        }
    }
}
