//
//  ViewController.swift
//  CHIP8AR
//
//  Created by Ryan Grey on 17/04/2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    private var ch8View: UIView!
    private var isGameScreenInitiated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ch8View = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 300))
        ch8View.backgroundColor = .blue
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func initiateGameScreen(node: SCNNode, anchor: ARPlaneAnchor) {
        let width = CGFloat(anchor.extent.x)
        let height = width / 2
        let gameScreenContainer = SCNNode(geometry: SCNPlane(width: width, height: height))
        gameScreenContainer.eulerAngles.x = -.pi/2
        gameScreenContainer.geometry?.firstMaterial?.diffuse.contents = ch8View
        node.addChildNode(gameScreenContainer)
        
        isGameScreenInitiated = true
    }
}

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard
            let planeAnchor = anchor as? ARPlaneAnchor,
            isGameScreenInitiated == false
        else { return }
        
        initiateGameScreen(node: node, anchor: planeAnchor)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // TODO
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // TODO
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // TODO
    }
}
