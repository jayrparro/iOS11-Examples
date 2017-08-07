//
//  ViewController.swift
//  BarcodeDetection
//
//  Created by Leonardo Parro on 28/7/17.
//  Copyright © 2017 Leonardo Parro. All rights reserved.
//

import UIKit
import Vision


class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
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
    private func startBarcodeDetection() {
        guard let anImage = self.imageView.image else { return }
        
        guard let ciImage = CIImage(image: anImage) else { return }
        
        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: self.handleBarcodeDetection)
        let barcodeRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        guard let _ = try? barcodeRequestHandler.perform([barcodeRequest]) else {
            return print("Error")
        }
    }
    
    private func handleBarcodeDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNBarcodeObservation] else {
            fatalError("Error - unexpected result type from VNDetectBarcodesRequest")
        }
        
        DispatchQueue.global().async {
            self.extractBarcodeInfo(forObservations: observations, complete: { result in
                DispatchQueue.main.async {
                    self.resultLabel.text = result
                }
            })
        }
    }
    
    private func extractBarcodeInfo(forObservations obervations: [VNBarcodeObservation], complete: (String) -> Void ) {
        
        var resultStr = ""
        
        for barcodeObservation in obervations {
            if let desc = barcodeObservation.barcodeDescriptor as? CIQRCodeDescriptor {
                print(desc.symbolVersion)
                let content = String(data: desc.errorCorrectedPayload, encoding: .utf8)
                resultStr = """
                            Symbology: \(barcodeObservation.symbology)\n
                            Payload: \(String(describing: content))\n
                            Error-Correction-Level:\(desc.errorCorrectionLevel)\n
                            Symbol-Version: \(desc.symbolVersion)\n
                            """
                
            }
        }
        
        complete(resultStr)
    }
}


extension ViewController: ImageChooserDelegate {
    func didSelect(image: UIImage) {
        self.imageView.image = image
        startBarcodeDetection()
    }
}
