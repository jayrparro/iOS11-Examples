//
//  Utils.swift
//  MyARApp1
//
//

import Foundation
import UIKit
import ARKit


func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
    let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
    
    let planeMaterial = SCNMaterial()
    planeMaterial.diffuse.contents = UIColor.blue.withAlphaComponent(0.4)
    plane.materials = [planeMaterial]
    let planeNode = SCNNode(geometry: plane)
    planeNode.position = SCNVector3Make(center.x, 0, center.z)
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
    
    return planeNode
}

func nodeWithModelName(_ modelName: String) -> SCNNode {
    return SCNScene(named: modelName)!.rootNode.clone()
}

func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3) {
    let geometry = node.geometry as! SCNPlane
    
    geometry.width = CGFloat(extent.x)
    geometry.height = CGFloat(extent.z)
    node.position = SCNVector3Make(center.x, 0, center.z)
}

func removeChildren(inNode node: SCNNode) {
    for node in node.childNodes {
        node.removeFromParentNode()
    }
}

extension UIViewController {
    var viewCenter: CGPoint {
        let screenSize = view.bounds
        return CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.5)
    }
    
    func showMessage(_ message: String, onLabel label: UILabel, delay: Double) {
        label.text = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if label.text == message {
                label.text = ""
            }
        }
    }
}
