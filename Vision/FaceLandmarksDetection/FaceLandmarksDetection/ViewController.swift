//
//  ViewController.swift
//  FaceLandmarksDetection
//
//  Created by Leonardo Parro on 28/7/17.
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
        
        let faceRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaces)
        let faceRequestHandler = VNImageRequestHandler(ciImage: faceCIImage, options: [:])
        
        do {
            try faceRequestHandler.perform([faceRequest])
        } catch {
            print(error)
        }
    }
    
    private func handleFaces(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("Error - unexpected result type from VNDetectFaceLandmarksRequest")
        }
        
        if error != nil {
            debugPrint("Error - \(String(describing: error?.localizedDescription))")
            return
        }
        
        DispatchQueue.global().async {
            self.highlightFaceLandmarks(for: self.imageView.image!,
                                        forObservations: observations,
                                        complete: { (resultImage) in
                                            DispatchQueue.main.async {
                                                self.imageView.image = resultImage
                                            }
            })
        }
    }
    
    private func highlightFaceLandmarks(for sourceImage: UIImage,
                                        forObservations observations: [VNFaceObservation],
                                        complete: (UIImage) -> Void) {
        var resultImage = sourceImage
        
        for faceObservation in observations {
            guard let landmarks = faceObservation.landmarks else {
                continue
            }
            let boundingRect = faceObservation.boundingBox
            var landmarkRegions: [VNFaceLandmarkRegion2D] = []
            if let faceContour = landmarks.faceContour {
                landmarkRegions.append(faceContour)
            }
            if let leftEye = landmarks.leftEye {
                landmarkRegions.append(leftEye)
            }
            if let rightEye = landmarks.rightEye {
                landmarkRegions.append(rightEye)
            }
            if let nose = landmarks.nose {
                landmarkRegions.append(nose)
            }
            if let noseCrest = landmarks.noseCrest {
                landmarkRegions.append(noseCrest)
            }
            if let medianLine = landmarks.medianLine {
                landmarkRegions.append(medianLine)
            }
            if let outerLips = landmarks.outerLips {
                landmarkRegions.append(outerLips)
            }
            
            if let leftEyebrow = landmarks.leftEyebrow {
                landmarkRegions.append(leftEyebrow)
            }
            if let rightEyebrow = landmarks.rightEyebrow {
                landmarkRegions.append(rightEyebrow)
            }
            
            if let innerLips = landmarks.innerLips {
                landmarkRegions.append(innerLips)
            }
            if let leftPupil = landmarks.leftPupil {
                landmarkRegions.append(leftPupil)
            }
            if let rightPupil = landmarks.rightPupil {
                landmarkRegions.append(rightPupil)
            }
            
            resultImage = self.drawOnImage(source: resultImage,
                                           boundingRect: boundingRect,
                                           faceLandmarkRegions: landmarkRegions)
        }
        
        complete(resultImage)
    }
    
    fileprivate func drawOnImage(source: UIImage,
                                 boundingRect: CGRect,
                                 faceLandmarkRegions: [VNFaceLandmarkRegion2D]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height
        
        //draw image
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        
        //draw bound rect
        var fillColor = UIColor.green
        fillColor.setFill()
        context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        //draw overlay
        fillColor = UIColor.red
        fillColor.setStroke()
        context.setLineWidth(2.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.point(at: i)
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            let mappedPoints = points.map { CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: boundingRect.origin.y * source.size.height + $0.y * rectHeight) }
            context.addLines(between: mappedPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }
        
        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }
}

// MARK: - ImageChooserDelegate
extension ViewController: ImageChooserDelegate {
    func didSelect(image: UIImage) {
        self.imageView.image = image
        startFaceDetection()
    }
}

