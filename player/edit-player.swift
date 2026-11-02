// Plays one clip once in a borderless, click-through window, fades in, fades out at the end, exits.
// Usage: edit-player <file> <left> <top> <size>   (top-left screen coordinates, like AppleScript bounds)
// Build: swiftc -O edit-player.swift -o edit-player
import AppKit
import AVFoundation

let args = CommandLine.arguments
guard args.count == 5, let left = Double(args[2]), let top = Double(args[3]), let size = Double(args[4]) else {
  FileHandle.standardError.write("usage: edit-player <file> <left> <top> <size>\n".data(using: .utf8)!)
  exit(2)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited) // no Dock icon, never becomes the active app (keyboard stays in the terminal)

let screenHeight = NSScreen.screens.first?.frame.height ?? 982
let frame = NSRect(x: left, y: screenHeight - top - size, width: size, height: size)
let window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
window.level = .floating
window.isOpaque = false
window.backgroundColor = .clear
window.ignoresMouseEvents = true
window.hasShadow = true
window.alphaValue = 0
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

let item = AVPlayerItem(url: URL(fileURLWithPath: args[1]))
let player = AVPlayer(playerItem: item)
let view = NSView(frame: NSRect(origin: .zero, size: frame.size))
view.wantsLayer = true
view.layer?.cornerRadius = 16
view.layer?.masksToBounds = true
let layer = AVPlayerLayer(player: player)
layer.frame = view.bounds
layer.videoGravity = .resizeAspectFill
view.layer?.addSublayer(layer)
window.contentView = view

func fade(to alpha: CGFloat, over seconds: Double, then done: (() -> Void)? = nil) {
  NSAnimationContext.runAnimationGroup({ ctx in
    ctx.duration = seconds
    window.animator().alphaValue = alpha
  }, completionHandler: done)
}

var isEnding = false
func end() {
  if isEnding { return }
  isEnding = true
  fade(to: 0, over: 1.2) { exit(0) }
}

// Start fading out 1.2 s before the clip ends, so the last frame melts away.
player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: .main) { t in
  let total = item.duration.seconds
  if total.isFinite, total > 0, t.seconds >= total - 1.2 { end() }
}
NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in end() }
NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { _ in end() }
DispatchQueue.main.asyncAfter(deadline: .now() + 120) { end() } // safety net: never stays up

window.orderFrontRegardless()
player.play()
fade(to: 1, over: 0.4)
app.run()
