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
        .breakout: [
            .left : .left,
            .right : .right
        ],
        .filter : [
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
        .spaceInvaders : [
            .tap : .primaryAction,
            .left : .left,
            .right : .right
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
