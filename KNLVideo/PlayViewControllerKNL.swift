//
//  PlayViewControllerKNL.swift
//  KNLVideo
//
//  Created by Volhan Salai on 5/28/19.
//  Copyright © 2019 Volhan Salai. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class PlayViewControllerKNL: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func playVideo(_ sender: Any) {
        VideoKNL.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
}

extension PlayViewControllerKNL: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == (kUTTypeMovie as String), let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
        
        dismiss(animated: true) {
            let player = AVPlayer(url: url)
            let vcPlayer = AVPlayerViewController()
            vcPlayer.player = player
            self.present(vcPlayer, animated: true, completion: nil)
        }
    }
}

extension PlayViewControllerKNL: UINavigationControllerDelegate {
    
}
