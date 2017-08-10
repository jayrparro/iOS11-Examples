//
//  ViewController.swift
//  WhatPic
//
//  Created by Leonardo Parro on 10/8/17.
//  Copyright © 2017 Leonardo Parro. All rights reserved.
//
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    
    let imageChooser = ImageChooser()
    var model: Inceptionv3!
    
    // MARK: - View Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        descLabel.text = "?? 🤔 ??"
        imageChooser.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model = Inceptionv3()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IB Actions
    @IBAction func onChooseImageButtonHandler(_ sender: UIButton) {
        imageChooser.choose(viewController: self)
    }
    
    // MARK: - Private Methods
    private func startImageAnalysis() {
        descLabel.text = "Analyzing Image..."
        //let image = self.imageView.image
        guard let image = self.imageView.image else { return }
        
        DispatchQueue.global().async {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
            image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
                return
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
            
            context?.translateBy(x: 0, y: newImage.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            
            UIGraphicsPushContext(context!)
            newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            //self.imageView.image = newImage
            
            guard let prediction = try? self.model.prediction(image: pixelBuffer!) else {
                return
            }
            
            DispatchQueue.main.async {
                self.descLabel.text = "\(prediction.classLabel)"
            }
        }
    }
}

// MARK: - ImageChooserDelegate
extension ViewController: ImageChooserDelegate {
    func didSelect(image: UIImage) {
        self.imageView.image = image
        startImageAnalysis()
    }
}

