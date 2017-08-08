//
//  ViewController.swift
//  MyARApp1
//
//

import UIKit
import SceneKit
import ARKit

enum FunctionMode {
    case none
    case placeObject(String)
}

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var plantButton: UIButton!
    @IBOutlet weak var vaseButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    var currentMode: FunctionMode = .none
    var allObjects: [SCNNode] = []
    
    
    // MARK: - View Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        runSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - UITouchesDelegate
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let hitResults = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent])
        
        if let hit = hitResults.first {
            // add anchor
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }
    
    // MARK: - IB Actions
    @IBAction func didTapPlantButton(_ sender: UIButton) {
        currentMode = .placeObject("art.scnassets/tree/Lowpoly_tree_sample.dae")
        selectButton(plantButton)
    }
    
    @IBAction func didTapVaseButton(_ sender: UIButton) {
        currentMode = .placeObject("art.scnassets/vase/vase.scn")
        selectButton(vaseButton)
    }
    
    @IBAction func didTapResetButton(_ sender: UIButton) {
        currentMode = .none
        selectButton(resetButton)
        removeAllObjects()
    }
}

// MARK: - Private Methods
private extension ViewController {
    func runSession() {
        sceneView.delegate = self
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        
        #if DEBUG
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
            sceneView.showsStatistics = true
        #endif
    }
    
    func selectButton(_ button: UIButton) {
        deSelectAllButtons()
        button.layer.borderColor = UIColor.blue.cgColor
        button.layer.borderWidth = 2
    }
    
    func deSelectAllButtons() {
        [plantButton, vaseButton, resetButton].forEach {
            $0?.layer.borderColor = UIColor.clear.cgColor
            $0?.layer.borderWidth = 2
        }
    }
    
    func removeAllObjects() {
        allObjects.forEach { $0.removeFromParentNode() }
        allObjects = []
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                #if DEBUG
                    let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                #endif
            } else {
                switch self.currentMode {
                case .none:
                    break
                case .placeObject(let name):
                    let aModel = nodeWithModelName(name)
                    self.allObjects.append(aModel)
                    node.addChildNode(aModel)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        removeChildren(inNode: node)
    }
    
    // ARSession Interruption
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
