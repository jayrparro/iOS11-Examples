//
//  ViewController.swift
//  ObjectTracker
//
//

import UIKit
import AVFoundation
import Vision


// this is from https://github.com/jeffreybergier/Blog-Getting-Started-with-Vision
class ViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var highlightView: UIView! {
        didSet {
            self.highlightView?.layer.borderColor = UIColor.red.cgColor
            self.highlightView?.layer.borderWidth = 4
            self.highlightView?.backgroundColor = .clear
        }
    }
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
        let input = try? AVCaptureDeviceInput(device: backCamera)
        else { return session }
        
        session.addInput(input)
        return session
    }()
    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    private let visionSequenceHandler = VNSequenceRequestHandler()
    private var lastObservation: VNDetectedObjectObservation?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide the red focus area on load
        self.highlightView?.frame = .zero
        
        // make the camera appear on the screen
        self.cameraView?.layer.addSublayer(self.cameraLayer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.userTapped(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        // register to receive buffers from the camera
        let videoOutput = AVCaptureVideoDataOutput()        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.captureSession.addOutput(videoOutput)
        
        // begin the session
        self.captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()        
    }
    
    // MARK: - UI Actions
    @objc private func userTapped(_ sender: UITapGestureRecognizer) {
        // get the center of the tap
        self.highlightView?.frame.size = CGSize(width: 120, height: 120)
        self.highlightView?.center = sender.location(in: self.view)
        
        // convert the rect for the initial observation
        let originalRect = self.highlightView?.frame ?? .zero
        var convertedRect = self.cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
        convertedRect.origin.y = 1 - convertedRect.origin.y
        
        // set the observation
        let newObservation = VNDetectedObjectObservation(boundingBox: convertedRect)
        self.lastObservation = newObservation
    }
    
    @IBAction private func resetTapped(_ sender: UIBarButtonItem) {
        self.lastObservation = nil
        self.highlightView?.frame = .zero
    }
    
    // MARK: - Private Methods
    private func handleVisionRequestUpdate(_ request: VNRequest, error: Error?) {
        // Dispatch to the main queue because we are touching non-atomic, non-thread safe properties of the view controller
        DispatchQueue.main.async {
            // make sure we have an actual result
            guard let newObservation = request.results?.first as? VNDetectedObjectObservation else { return }
            
            // prepare for next loop
            self.lastObservation = newObservation
            
            // check the confidence level before updating the UI
            guard newObservation.confidence >= 0.3 else {
                // hide the rectangle when we lose accuracy so the user knows something is wrong
                self.highlightView?.frame = .zero
                return
            }
            
            // calculate view rect
            var transformedRect = newObservation.boundingBox
            transformedRect.origin.y = 1 - transformedRect.origin.y
            let convertedRect = self.cameraLayer.layerRectConverted(fromMetadataOutputRect: transformedRect)
            
            // move the highlight view
            self.highlightView?.frame = convertedRect
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            // make sure the pixel buffer can be converted
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            // make sure that there is a previous observation we can feed into the request
            let lastObservation = self.lastObservation
            else { return }
        
        // create the request
        let request = VNTrackObjectRequest(detectedObjectObservation: lastObservation, completionHandler: self.handleVisionRequestUpdate)
        // set the accuracy to high
        // this is slower, but it works a lot better
        request.trackingLevel = .accurate
        
        // perform the request
        do {
            try self.visionSequenceHandler.perform([request], on: pixelBuffer)
        } catch {
            print("Throws: \(error)")
        }
    }
}
