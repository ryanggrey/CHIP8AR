//
//  RomPlatformInput.swift
//  CHIP8WatchOS WatchKit Extension
//
//  Created by Ryan Grey on 19/02/2021.
//

import Foundation
import Chip8Emulator

typealias PlatformMapping = [TouchInputCode : SemanticInputCode]

struct TouchInputMappingService {
    private let mapping: [RomName : PlatformMapping] = [
        .chip8 : [:],
        .airplane : [
            .tap : .primaryAction
        ],
        .astroDodge: [
            .tap : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .blinky : [
            .left : .left,
            .right : .right,
            .down : .down,
            .up : .up
        ],
        .breakout: [
            .left : .left,
            .right : .right
        ],
        .cave : [
            .tap : .primaryAction,
            .up : .up,
            .down : .down,
            .left : .left,
            .right : .right
        ],
        .filter : [
            .left : .left,
            .right : .right
        ],
        .kaleidoscope : [
            .tap : .primaryAction,
            .up : .up,
            .down : .down,
            .left : .left,
            .right : .right
        ],
        .landing : [
            .tap : .primaryAction
        ],
        .lunarLander : [
            .tap : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .maze : [:],
        .missile : [
            .tap : .primaryAction
        ],
        .pong : [
            .down : .down,
            .up : .up
        ],
        .rocket : [
            .tap : .primaryAction
        ],
        .spaceFlight : [
            .tap : .primaryAction,
            .longPress : .secondaryAction,
            .down : .down,
            .up : .up
        ],
        .spaceIntercept : [
            .tap : .primaryAction,
            .longPress : .secondaryAction,
            .left : .left,
            .up : .up,
            .right : .right
        ],
        .spaceInvaders : [
            .tap : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .squash : [
            .up : .up,
            .down : .down
        ],
        .tank : [
            .tap : .primaryAction,
            .left : .left,
            .right : .right,
            .down : .down,
            .up : .up
        ],
        .tapeWorm : [
            .tap : .primaryAction,
            .left : .left,
            .right : .right,
            .up : .up,
            .down : .down
        ],
        .tetris : [
            .down : .secondaryAction,
            .tap : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .wipeOff : [
            .left : .left,
            .right : .right
        ],
        .worm : [
            .tap : .primaryAction,
            .left : .left,
            .right : .right,
            .up : .up,
            .down : .down
        ],
        .xMirror : [
            .tap : .primaryAction,
            .up : .up,
            .down : .down,
            .left : .left,
            .right : .right
        ]
    ]
    
    func platformMapping(for romName: RomName) -> PlatformMapping? {
        return mapping[romName]
    }
}

extension TouchInputMappingService: PlatformInputMappingService {
    typealias PlatformInputCode = TouchInputCode

    func semanticInputCode(from romName: RomName, from platformInputCode: TouchInputCode) -> SemanticInputCode? {
        return platformMapping(for: romName)?[platformInputCode]
    }
}
