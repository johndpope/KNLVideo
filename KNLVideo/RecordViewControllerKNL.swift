//
//  RecordViewControllerKNL.swift
//  KNLVideo
//
//  Created by Volhan Salai on 5/28/19.
//  Copyright © 2019 Volhan Salai. All rights reserved.
//

import UIKit
import MobileCoreServices

class RecordViewControllerKNL: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func recordVideo(_ sender: Any) {
        VideoKNL.startMediaBrowser(delegate: self, sourceType: .camera)
    }
    
    @objc func video (_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

extension RecordViewControllerKNL: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == (kUTTypeMovie as String), let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL, UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) else { return }
        
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }
}

extension RecordViewControllerKNL: UINavigationControllerDelegate {
    
}
