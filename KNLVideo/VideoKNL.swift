//
//  VideoKNL.swift
//  KNLVideo
//
//  Created by Volhan Salai on 5/29/19.
//  Copyright © 2019 Volhan Salai. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

class VideoKNL {
    static func startMediaBrowser(delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate, sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = sourceType
        mediaUI.mediaTypes = [kUTTypeMovie as String]
        mediaUI.allowsEditing = false
        mediaUI.delegate = delegate
        mediaUI.videoQuality = .typeHigh
        delegate.present(mediaUI, animated: true, completion: nil)
    }
    
    static func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let scaleToFitRatio = 1920.0 / assetTrack.naturalSize.width
        
        let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
        let concat = assetTrack.preferredTransform.concatenating(scaleFactor)
        instruction.setTransform(concat, at: .zero)
        
        return instruction
    }
}
