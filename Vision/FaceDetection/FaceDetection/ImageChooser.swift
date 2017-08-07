//
//  ImageChooser.swift
//  FaceDetection
//
//  Created by Leonardo Parro on 27/7/17.
//  Copyright © 2017 Leonardo Parro. All rights reserved.
//

import Foundation
import UIKit

protocol ImageChooserDelegate {
    func didSelect(image: UIImage)
}

class ImageChooser: NSObject, UINavigationControllerDelegate {
    
    var vc: UIViewController?
    var delegate: ImageChooserDelegate?
    
    func choose(viewController vc: UIViewController) {
        let dialog = UIAlertController(title: "", message: "Choose image", preferredStyle: .actionSheet)
        //dialog.addAction(UIAlertAction(title: "Take picture", style: .default, handler: self.showCamera))
        dialog.addAction(UIAlertAction(title: "Choose from photo library", style: .default, handler: self.chooseFromPhotoLibrary))
        dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.vc = vc
        vc.present(dialog, animated: true)
    }
    
    private func showCamera(action: UIAlertAction){
        debugPrint("show camera")
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            self.vc?.present(imagePicker, animated: true)
        }
    }
    
    private func chooseFromPhotoLibrary(action: UIAlertAction){
        debugPrint("choose from photo library")
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.vc?.present(imagePicker, animated: true)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ImageChooser: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let anImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            delegate?.didSelect(image: anImage)
        }
        
        vc?.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // do nothing...
        vc?.dismiss(animated: true, completion: nil)
    }
}
