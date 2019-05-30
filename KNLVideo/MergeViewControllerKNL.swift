//
//  MergeViewControllerKNL.swift
//  KNLVideo
//
//  Created by Volhan Salai on 5/28/19.
//  Copyright © 2019 Volhan Salai. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import AVFoundation

class MergeViewControllerKNL: UIViewController {
    var firstVideo: AVAsset?
    var secondVideo: AVAsset?
    var loadingFirstVideo = false
    let hdVideoSize = CGSize(width: 1920.0, height: 1080.0)
    
    @IBOutlet weak var activityMonitor: UIActivityIndicatorView!
    @IBOutlet weak var firstVideoButton: UIButton!
    @IBOutlet weak var secondVideoButton: UIButton!
    @IBOutlet weak var animationButton: UIButton!
    @IBOutlet weak var mergeButton: UIButton!

    @IBAction func loadFirstVideo(_ sender: Any) {
        if savedVideosAvailable() {
            self.loadingFirstVideo = true
            VideoKNL.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @IBAction func loadSecondVideo(_ sender: Any) {
        if savedVideosAvailable() {
            loadingFirstVideo = false
            VideoKNL.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @IBAction func loadAnimation(_ sender: Any) {
    }
    
    
    @IBAction func merge(_ sender: Any) {
        guard let firstVideo = self.firstVideo, let secondVideo = self.secondVideo else {
            let alert = UIAlertController(title: "Videos not selected", message: "Please select both videos to merge them", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        self.processing()
        
        let composition = AVMutableComposition()
        guard let firstTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: firstVideo.duration), of: firstVideo.tracks(withMediaType: .video)[0], at: .zero)
        } catch {
            print("first track failed")
            return
        }
        
        guard let secondTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        
        do {
            try secondTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: secondVideo.duration), of: secondVideo.tracks(withMediaType: .video)[0], at: firstVideo.duration)
        } catch {
            print("second track failed")
            return
        }
        
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: CMTimeAdd(firstVideo.duration, secondVideo.duration))
        
        let firstInstruction = VideoKNL.videoCompositionInstruction(firstTrack, asset: firstVideo)
        firstInstruction.setOpacity(0.0, at: firstVideo.duration)
        let secondInstruction = VideoKNL.videoCompositionInstruction(secondTrack, asset: secondVideo)
        
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = hdVideoSize
        mainComposition.renderScale = 1.0
        
        self.applyAnimationToVideo(composition: mainComposition)
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                self.exportDidFinish(session: exporter)
            }
        }
    }
    
    func processing() {
        if self.activityMonitor.isAnimating {
            self.activityMonitor.stopAnimating()
            self.firstVideoButton.isHidden = false
            self.secondVideoButton.isHidden = false
            self.animationButton.isHidden = false
            self.mergeButton.isHidden = false
        } else {
            self.firstVideoButton.isHidden = true
            self.secondVideoButton.isHidden = true
            self.animationButton.isHidden = true
            self.mergeButton.isHidden = true
            self.activityMonitor.startAnimating()
        }
    }
    
    func savedVideosAvailable() -> Bool {
        guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else {
            return true
        }
        
        let alert = UIAlertController(title: "Videos not available", message: "No saved videos found", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
        return false
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        self.processing()
        
        self.firstVideo = nil
        self.secondVideo = nil
        
        guard session.status == AVAssetExportSession.Status.completed, let url = session.outputURL else { return }
        
        let saveVideo = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { (success, error) in
                let result = success && (error == nil)
                let title = result ? "Success" : "Error"
                let message = result ? "Video merged and saved" : "Failed to merge and save video"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        }
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    saveVideo()
                }
            }
        } else {
            saveVideo()
        }
    }
    
    func applyAnimationToVideo(composition: AVMutableVideoComposition) {
        let subtitleText = CATextLayer()
//        subtitleText.font = "Superclarendon-Black"
        subtitleText.fontSize = 72
        subtitleText.frame = CGRect(x: 0.0, y: 76.0, width: hdVideoSize.width, height: 100.0)
        subtitleText.string = "TEST"
        subtitleText.alignmentMode = CATextLayerAlignmentMode.center
        subtitleText.foregroundColor = UIColor.white.cgColor
        subtitleText.shadowOpacity = 1.0
        subtitleText.shadowOffset = CGSize(width: 0.0, height: 0.0)
        subtitleText.shadowRadius = 6.0
        
        let textOverlayLayer = CALayer()
        textOverlayLayer.addSublayer(subtitleText)
        textOverlayLayer.frame = CGRect(x: 0.0, y: 0.0, width: hdVideoSize.width, height: hdVideoSize.height)
        
        
        let animateTitle = CABasicAnimation(keyPath: "transform.translation.x")
        animateTitle.duration = 1.0
        
        animateTitle.fromValue = -textOverlayLayer.frame.width
        animateTitle.toValue = 0.0
        animateTitle.beginTime = AVCoreAnimationBeginTimeAtZero
        animateTitle.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        textOverlayLayer.add(animateTitle, forKey: "translation")
        
        
//        let videoLayer = CALayer()
//        videoLayer.frame = CGRect(x: 0, y: 0, width: hdVideoSize.width - borderWidth * 2.0, height: hdVideoSize.height - borderWidth * 2.0)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0.0, y: 0.0, width: hdVideoSize.width, height: hdVideoSize.height)
        parentLayer.masksToBounds = true
        
//        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(textOverlayLayer)
        
//        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: parentLayer, in: parentLayer)
    }
}

extension MergeViewControllerKNL: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            else { return }
        
        let avAsset = AVAsset(url: url)
        var message = ""
        if loadingFirstVideo {
            message = "Video one loaded"
            firstVideo = avAsset
        } else {
            message = "Video two loaded"
            secondVideo = avAsset
        }
        let alert = UIAlertController(title: "Video Loaded", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension MergeViewControllerKNL: UINavigationControllerDelegate {
    
}
