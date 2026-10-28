import AppKit
import QuartzCore

/// The snow lying on window ledges, drawn in a full-screen overlay window sitting at status bar level (in front of windows).
/// When "Behind Windows" is active, falling flakes and ground snow render behind open windows on the desktop level,
/// while this overlay renders snow accumulating on active window headers and ledges in front of windows.
final class WindowOverlay {
    let window: OverlayWindow
    private let layer = CAMetalLayer()
    private var screenFrame: CGRect
    private var scaleFactor: CGFloat

    init(screen: NSScreen, device: MTLDevice) {
        screenFrame = screen.frame
        scaleFactor = screen.backingScaleFactor
        window = OverlayWindow(screen: screen, level: .statusBar)
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.isOpaque = false
        layer.framebufferOnly = true
        layer.contentsGravity = .bottomLeft
        layer.needsDisplayOnBoundsChange = false
        let view = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.layer = layer
        view.wantsLayer = true
        view.autoresizingMask = [.width, .height]
        window.contentView = view
        place()
        window.orderFrontRegardless()
    }

    func fit(to screen: NSScreen) {
        screenFrame = screen.frame
        scaleFactor = screen.backingScaleFactor
        place()
    }

    /// The next frame to draw into, cleared to transparency.
    func nextFrame() -> (drawable: CAMetalDrawable, pass: MTLRenderPassDescriptor)? {
        guard let drawable = layer.nextDrawable() else { return nil }
        let pass = MTLRenderPassDescriptor()
        let attachment = pass.colorAttachments[0]!
        attachment.texture = drawable.texture
        attachment.loadAction = .clear
        attachment.storeAction = .store
        attachment.clearColor = MTLClearColorMake(0, 0, 0, 0)
        return (drawable, pass)
    }

    func close() {
        window.orderOut(nil)
    }

    private func place() {
        window.setFrame(screenFrame, display: false)
        layer.contentsScale = scaleFactor
        layer.drawableSize = CGSize(width: screenFrame.width * scaleFactor, height: screenFrame.height * scaleFactor)
    }
}
