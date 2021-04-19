import UIKit
import Chip8Emulator

class Chip8View: UIView {
    var screen: Chip8Screen?
    var pixelColor: UIColor?

    override func draw(_ layer: CALayer, in ctx: CGContext) {
        super.draw(layer, in: ctx)
        drawPixels(in: ctx)
    }

    override func draw(_ rect: CGRect) {
    }
    
    private func drawPixels(in context: CGContext) {
        guard let screen = screen, let pixelColor = pixelColor else { return }

        let path = PathFactory.from(
            screen: screen,
            containerSize: self.frame.size,
            isYReversed: false
            )
        context.setFillColor(pixelColor.cgColor)
        context.addPath(path)
        context.fillPath()
    }
}
