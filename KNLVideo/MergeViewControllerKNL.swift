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

class MergeViewControllerKNL: UIViewController {
    var firstVideo: AVAsset?
    var secondVideo: AVAsset?
    var loadingFirstVideo = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        guard let firstVideo = self.firstVideo, let secondVideo = self.secondVideo else { return }
        
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
        let secondInstruction = VideoKNL.videoCompositionInstruction(secondTrack, asset: secondVideo)
        
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
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
