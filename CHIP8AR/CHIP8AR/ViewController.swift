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

private enum InputMode: Int {
    case chip8 = 0
    case ar = 1
}

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var inputControl: UISegmentedControl!
    private var chip8View: Chip8View!
    private let coachingView = ARCoachingOverlayView()
    private var chip8Node: SCNNode?
    private var inputMode = InputMode.ar
    private var lastTouchPosition: simd_float3?
    private let chip8Engine = Chip8Engine()
    private let beepPlayer = BeepPlayer()
    private let selectedRom = RomName.spaceInvaders
    
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
        
        setupGestures()
        setupInputControl()
        setupCoaching()
        setupEmulator()
        setupAR()
        reset()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func setupInputControl() {
        self.inputControl.addTarget(self, action: #selector(updateInputControls), for: .valueChanged)
        self.inputControl.selectedSegmentIndex = 0
        updateInputControls(sender: self.inputControl)
    }
    
    @objc private func updateInputControls(sender: UISegmentedControl) {
        guard let inputMode = InputMode.init(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        switch inputMode {
        case .ar:
            self.chip8Engine.stop()
            break;
        case .chip8:
            self.chip8Engine.resume()
            break;
        }
        
        self.inputMode = inputMode
    }
    
    private func setupCoaching() {
        self.coachingView.session = sceneView.session
        self.coachingView.frame = self.view.frame
        self.view.addSubview(coachingView)
        
        coachingView.goal = .verticalPlane
        coachingView.activatesAutomatically = false
        setCoachingView(isHidden: false)
    }
    
    private func setCoachingView(isHidden: Bool) {
        coachingView.setActive(!isHidden, animated: true)
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
        let chip8Node = SCNNode(geometry: SCNPlane(width: width, height: height))
        chip8Node.eulerAngles.x = -.pi/2
        chip8Node.geometry?.firstMaterial?.diffuse.contents = chip8View
        node.addChildNode(chip8Node)
        
        self.chip8Node = chip8Node
        
        start(romName: selectedRom)
    }
    
    func reset() {
        chip8Node = nil
        chip8Engine.stop()
        
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.session.run(
            configuration,
            options: [.removeExistingAnchors, .resetTracking, .resetSceneReconstruction]
        )
        
        coachingView.session = sceneView.session
        setCoachingView(isHidden: false)
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard
            let planeAnchor = anchor as? ARPlaneAnchor,
            chip8Node == nil
        else { return }
        
        setCoachingView(isHidden: true)
        setupGameScreen(node: node, anchor: planeAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard chip8Node == node else { return }
        
        reset()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        reset()
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        reset()
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
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        
        tap.require(toFail: pan)
        pan.require(toFail: longPress)

        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(longPress)
    }
    
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
    
    private func repositionChip8Node(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .ended, .cancelled, .failed:
            self.lastTouchPosition = nil
            return;
        default:
            break;
        }
        
        let location = gesture.location(in: self.view)
        guard
            let chip8Node = chip8Node,
            let raycastQuery = sceneView.raycastQuery(
                from: location,
                allowing: .existingPlaneInfinite,
                alignment: .vertical
            ),
            let raycastResult = sceneView.session.raycast(raycastQuery).first
        else { return }
        
        let translation = raycastResult.worldTransform.columns.3
        let newTouchPosition = simd_make_float3(translation)
        
        chip8Node.simdWorldPosition = newTouchPosition

        lastTouchPosition = newTouchPosition
    }
    
    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        if inputMode == .ar {
            repositionChip8Node(gesture)
            return
        }
        
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
        guard
            inputMode == .chip8,
            let chip8KeyCode = chip8KeyCode(for: .tap)
        else { return }
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
        if inputMode == .ar {
            repositionChip8Node(gesture)
            return
        }
        
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
