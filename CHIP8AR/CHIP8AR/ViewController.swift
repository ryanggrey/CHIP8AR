//
//  ViewController.swift
//  CHIP8AR
//
//  Created by Ryan Grey on 17/04/2021.
//

import UIKit
import SceneKit
import ARKit
import Chip8Emulator

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    private var chip8View: Chip8View!
    private var isGameScreenInitiated = false
    private let chip8Engine = Chip8Engine()
    private let beepPlayer = BeepPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupEmulator()
        
        setupAR()
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
    
    private func setupEmulator() {
        chip8Engine.delegate = self
        let chip8Frame = CGRect(x: 0, y: 0, width: 600, height: 300)
        chip8View = Chip8View(frame: chip8Frame)
        chip8View.backgroundColor = .gray
        chip8View.pixelColor = .purple
    }
    
    private func setupAR() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.scene = SCNScene()
    }
    
    fileprivate func start(romName: RomName) {
        let rom = RomLoader.loadRam(from: romName)
        chip8Engine.start(with: rom)
    }
    
    private func setupGameScreen(node: SCNNode, anchor: ARPlaneAnchor) {
        let width = CGFloat(anchor.extent.x)
        let height = width / 2
        let gameScreenContainer = SCNNode(geometry: SCNPlane(width: width, height: height))
        gameScreenContainer.eulerAngles.x = -.pi/2
        gameScreenContainer.geometry?.firstMaterial?.diffuse.contents = chip8View
        node.addChildNode(gameScreenContainer)
        isGameScreenInitiated = true
        
        start(romName: .pong)
    }
}

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard
            let planeAnchor = anchor as? ARPlaneAnchor,
            isGameScreenInitiated == false
        else { return }
        
        setupGameScreen(node: node, anchor: planeAnchor)
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

extension ViewController: Chip8EngineDelegate {
    func beep() {
        beepPlayer.play()
    }

    func render(screen: Chip8Screen) {
        chip8View.screen = screen
        chip8View.setNeedsDisplay()
    }
}
