//
//  ViewController.swift
//  FaceDetection
//
//  Created by Leonardo Parro on 27/7/17.
//  Copyright © 2017 Leonardo Parro. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imageChooser = ImageChooser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageChooser.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onChooseImageButtonHandler(_ sender: UIButton) {
        imageChooser.choose(viewController: self)
    }
    
    // MARK: - Private Methods
    private func startFaceDetection() {
        guard let anImage = self.imageView.image else { return }
        
        guard let faceCIImage = CIImage(image: anImage) else { return }
        
        let faceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)
        let faceRequestHandler = VNImageRequestHandler(ciImage: faceCIImage, options: [:])
        
        do {
            try faceRequestHandler.perform([faceRequest])
        } catch {
            print(error)
        }
    }
    
    private func handleFaces(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("Error - unexpected result type from VNDetectFaceRectanglesRequest")
        }
        
        self.addShapesToFace(forObservations: observations)
    }
    
    private func addShapesToFace(forObservations observations: [VNFaceObservation]) {
        if let sublayers = imageView.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
        
        let imageRect = AVMakeRect(aspectRatio: (imageView.image?.size)!, insideRect: imageView.bounds)
        
        let layers: [CAShapeLayer] = observations.map { observation in
            
            let w = observation.boundingBox.size.width * imageRect.width
            let h = observation.boundingBox.size.height * imageRect.height
            let x = observation.boundingBox.origin.x * imageRect.width
            let y = imageRect.maxY - (observation.boundingBox.origin.y * imageRect.height) - h
            
            print("----")
            print("W: ", w)
            print("H: ", h)
            print("X: ", x)
            print("Y: ", y)
            
            let layer = CAShapeLayer()
            layer.frame = CGRect(x: x , y: y, width: w, height: h)
            layer.borderColor = UIColor.red.cgColor
            layer.borderWidth = 2
            layer.cornerRadius = 3
            return layer
        }
        
        for layer in layers {
            imageView.layer.addSublayer(layer)
        }
    }
}

// MARK: - ImageChooserDelegate
extension ViewController: ImageChooserDelegate {
    func didSelect(image: UIImage) {
        self.imageView.image = image
        startFaceDetection()
    }
}
