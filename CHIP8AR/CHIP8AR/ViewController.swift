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
    private let selectedRom = RomName.pong
    
    private lazy var platformInputMappingService: TouchInputMappingService = {
        return TouchInputMappingService()
    }()
    
    private lazy var inputMapper: InputMapper<TouchInputMappingService> = {
        return InputMapper(platformInputMappingService: platformInputMappingService)
    }()
    
    private lazy var supportedRomService: PlatformSupportedRomService = {
        return PlatformSupportedRomService(inputMappingService: platformInputMappingService)
    }()
    
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
        sceneView.scene = SCNScene()
    }
    
    private func start(romName: RomName) {
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
        
        start(romName: selectedRom)
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
        
        DispatchQueue.main.async { [weak self] in
            self?.chip8View.setNeedsDisplay()
        }
    }
}

// Touch Inputs
extension ViewController {
    private func liftAllChip8Keys() {
        TouchInputCode.allCases.forEach { touchInputCode in
            self.updateChip8Key(isPressed: false, touchInputCode: touchInputCode)
        }
    }
    
    private func chip8KeyCode(for tvInputCode: TouchInputCode) -> Chip8InputCode? {
        return inputMapper.map(platformInput: tvInputCode, romName: selectedRom)
    }
    
    private func updateChip8Key(isPressed: Bool, touchInputCode: TouchInputCode) {
        guard let key = self.chip8KeyCode(for: touchInputCode) else { return }
        
        if isPressed {
            self.chip8Engine.handleKeyDown(key: key)
        } else {
            self.chip8Engine.handleKeyUp(key: key)
        }
    }
    
    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        if(gesture.state == .ended
            || gesture.state == .cancelled
            || gesture.state == .failed
        ) {
            self.liftAllChip8Keys()
            return
        }
        
        let translation = gesture.translation(in: view)
        let xValue = translation.x
        let yValue = translation.y
        let isXDominant = max(abs(xValue), abs(yValue)) == abs(xValue)
        
        self.liftAllChip8Keys()
        
        if isXDominant {
            if xValue < 0 {
                self.updateChip8Key(isPressed: true, touchInputCode: .left)
            } else if xValue > 0 {
                self.updateChip8Key(isPressed: true, touchInputCode: .right)
            }
        } else {
            if yValue < 0 {
                self.updateChip8Key(isPressed: true, touchInputCode: .up)
            } else {
                self.updateChip8Key(isPressed: true, touchInputCode: .down)
            }
        }
    }
    
    @IBAction func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let chip8KeyCode = chip8KeyCode(for: .tap) else { return }
        chip8Engine.handleKeyDown(key: chip8KeyCode)
        
        /*
         tap gestures are discrete/atomic and there appears to
         be no way be notified of imtermediary gesture state such
         as touchDown, touchUp etc. This means we need to simulate
         the touchUp event so that Chip8 doesn't end up thinking a
         key has been pressed and never released
         */
        Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(self.didEndTap),
            userInfo: nil,
            repeats: false
        )
    }
    
    @objc private func didEndTap() {
        guard let chip8KeyCode = chip8KeyCode(for: .tap) else { return }
        
        chip8Engine.handleKeyUp(key: chip8KeyCode)
    }
    
    @IBAction func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            didBeginLongPress()
            return
        case .ended:
            didEndLongPress()
            return
        case .failed:
            didEndLongPress()
            return
        default:
            return
        }
    }
    
    private func didBeginLongPress() {
        guard let chip8KeyCode = chip8KeyCode(for: .longPress) else { return }
        
        chip8Engine.handleKeyDown(key: chip8KeyCode)
    }
    
    private func didEndLongPress() {
        guard let chip8KeyCode = chip8KeyCode(for: .longPress) else { return }
        
        chip8Engine.handleKeyUp(key: chip8KeyCode)
    }
}
