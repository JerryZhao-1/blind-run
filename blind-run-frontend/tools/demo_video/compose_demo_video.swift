import AVFoundation
import CoreGraphics
import Darwin
import Foundation
import QuartzCore

struct Manifest: Decodable {
  struct SourceCrop: Decodable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var rect: CGRect {
      CGRect(x: x, y: y, width: width, height: height)
    }
  }

  struct Canvas: Decodable {
    let width: Int
    let height: Int
    let backgroundHex: String
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let paneGap: CGFloat
  }

  struct Labels: Decodable {
    let left: String
    let right: String
  }

  struct Segment: Decodable {
    let id: String
    let leftClip: String
    let rightClip: String
  }

  let canvas: Canvas
  let labels: Labels
  let sourceCrop: SourceCrop?
  let segments: [Segment]
}

struct Arguments {
  let manifestURL: URL
  let clipsDirectory: URL
  let outputURL: URL
  let outputFileType: AVFileType
}

enum ComposeError: Error, CustomStringConvertible {
  case missingArgument(String)
  case missingClip(URL)
  case unreadableManifest(URL)
  case noVideoTrack(URL)
  case invalidDuration(String)
  case invalidCrop(String)
  case cannotCreateExportSession
  case exportFailed(String)

  var description: String {
    switch self {
      case .missingArgument(let name):
        return "Missing required argument: \(name)"
      case .missingClip(let url):
        return "Missing required clip: \(url.path)"
      case .unreadableManifest(let url):
        return "Could not read manifest: \(url.path)"
      case .noVideoTrack(let url):
        return "No video track found in clip: \(url.path)"
      case .invalidDuration(let segmentID):
        return "Segment has no usable duration: \(segmentID)"
      case .invalidCrop(let detail):
        return "Invalid source crop: \(detail)"
      case .cannotCreateExportSession:
        return "Could not create AVAssetExportSession"
      case .exportFailed(let message):
        return "Export failed: \(message)"
    }
  }
}

do {
  try run()
} catch {
  fputs("\(error)\n", stderr)
  exit(1)
}

func run() throws {
  let arguments = try parseArguments()
  let manifest = try loadManifest(at: arguments.manifestURL)
  let outputDirectory = arguments.outputURL.deletingLastPathComponent()
  try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
  )
  if FileManager.default.fileExists(atPath: arguments.outputURL.path) {
    try FileManager.default.removeItem(at: arguments.outputURL)
  }

  guard let settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080) else {
    throw ComposeError.exportFailed("Could not create an output settings assistant")
  }
  var videoSettings = settingsAssistant.videoSettings ?? [:]
  videoSettings[AVVideoWidthKey] = manifest.canvas.width
  videoSettings[AVVideoHeightKey] = manifest.canvas.height
  let pixelBufferAttributes: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
    kCVPixelBufferWidthKey as String: manifest.canvas.width,
    kCVPixelBufferHeightKey as String: manifest.canvas.height,
    kCVPixelBufferCGImageCompatibilityKey as String: true,
    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
  ]

  let writer = try AVAssetWriter(
    outputURL: arguments.outputURL,
    fileType: arguments.outputFileType
  )
  let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
  writerInput.expectsMediaDataInRealTime = false
  let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: writerInput,
    sourcePixelBufferAttributes: pixelBufferAttributes
  )

  guard writer.canAdd(writerInput) else {
    throw ComposeError.exportFailed("Could not attach a video writer input")
  }
  writer.add(writerInput)

  guard writer.startWriting() else {
    throw ComposeError.exportFailed(String(describing: writer.error))
  }
  writer.startSession(atSourceTime: .zero)

  let frameRate: Double = 30
  let frameTimescale: Int32 = 600
  let frameStep = CMTime(value: 1, timescale: Int32(frameRate))
  var cursor = CMTime.zero

  for segment in manifest.segments {
    let leftURL = arguments.clipsDirectory.appendingPathComponent(segment.leftClip)
    let rightURL = arguments.clipsDirectory.appendingPathComponent(segment.rightClip)
    guard FileManager.default.fileExists(atPath: leftURL.path) else {
      throw ComposeError.missingClip(leftURL)
    }
    guard FileManager.default.fileExists(atPath: rightURL.path) else {
      throw ComposeError.missingClip(rightURL)
    }

    let leftAsset = AVURLAsset(url: leftURL)
    let rightAsset = AVURLAsset(url: rightURL)

    guard let leftSourceTrack = leftAsset.tracks(withMediaType: .video).first else {
      throw ComposeError.noVideoTrack(leftURL)
    }
    guard let rightSourceTrack = rightAsset.tracks(withMediaType: .video).first else {
      throw ComposeError.noVideoTrack(rightURL)
    }

    let segmentDuration = minimumDuration(leftAsset.duration, rightAsset.duration)
    guard segmentDuration.seconds > 0 else {
      throw ComposeError.invalidDuration(segment.id)
    }

    let leftCrop = try resolvedCropRect(
      sourceCrop: manifest.sourceCrop,
      for: leftSourceTrack,
      clipURL: leftURL
    )
    let rightCrop = try resolvedCropRect(
      sourceCrop: manifest.sourceCrop,
      for: rightSourceTrack,
      clipURL: rightURL
    )

    let leftGenerator = AVAssetImageGenerator(asset: leftAsset)
    leftGenerator.appliesPreferredTrackTransform = true
    let rightGenerator = AVAssetImageGenerator(asset: rightAsset)
    rightGenerator.appliesPreferredTrackTransform = true

    let frameCount = max(1, Int(floor(segmentDuration.seconds * frameRate)))
    for frameIndex in 0..<frameCount {
      let localTime = CMTime(
        value: Int64(frameIndex) * Int64(frameTimescale),
        timescale: Int32(frameRate) * frameTimescale
      )
      let leftImage = try frameImage(
        from: leftGenerator,
        at: localTime,
        clipName: leftURL.lastPathComponent
      )
      let rightImage = try frameImage(
        from: rightGenerator,
        at: localTime,
        clipName: rightURL.lastPathComponent
      )

      while !writerInput.isReadyForMoreMediaData {
        Thread.sleep(forTimeInterval: 0.01)
      }

      guard let pixelBufferPool = adaptor.pixelBufferPool else {
        throw ComposeError.exportFailed("Could not create a pixel buffer pool")
      }
      let pixelBuffer = try makeFrameBuffer(
        from: pixelBufferPool,
        canvas: manifest.canvas,
        labels: manifest.labels,
        leftImage: leftImage,
        rightImage: rightImage,
        leftCrop: leftCrop,
        rightCrop: rightCrop
      )
      let presentationTime = cursor + CMTimeMultiply(frameStep, multiplier: Int32(frameIndex))
      if !adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
        throw ComposeError.exportFailed(String(describing: writer.error))
      }
    }

    cursor = cursor + CMTimeMultiply(frameStep, multiplier: Int32(frameCount))
  }

  writerInput.markAsFinished()
  let semaphore = DispatchSemaphore(value: 0)
  writer.finishWriting {
    semaphore.signal()
  }
  semaphore.wait()

  switch writer.status {
    case .completed:
      print("Composed demo video exported to \(arguments.outputURL.path)")
    case .failed:
      throw ComposeError.exportFailed(String(describing: writer.error))
    case .cancelled:
      throw ComposeError.exportFailed("Export cancelled")
    default:
      throw ComposeError.exportFailed("Unexpected writer status: \(writer.status.rawValue)")
  }
}

func parseArguments() throws -> Arguments {
  let values = Array(CommandLine.arguments.dropFirst())
  guard !values.isEmpty else {
    throw ComposeError.missingArgument("--manifest <path> --clips <dir> --output <path>")
  }

  func value(for flag: String) -> String? {
    guard let index = values.firstIndex(of: flag), index + 1 < values.count else {
      return nil
    }
    return values[index + 1]
  }

  guard let manifestPath = value(for: "--manifest") else {
    throw ComposeError.missingArgument("--manifest")
  }
  guard let clipsPath = value(for: "--clips") else {
    throw ComposeError.missingArgument("--clips")
  }
  guard let outputPath = value(for: "--output") else {
    throw ComposeError.missingArgument("--output")
  }

  return Arguments(
    manifestURL: URL(fileURLWithPath: manifestPath).standardizedFileURL,
    clipsDirectory: URL(fileURLWithPath: clipsPath).standardizedFileURL,
    outputURL: URL(fileURLWithPath: outputPath).standardizedFileURL,
    outputFileType: fileType(for: outputPath)
  )
}

func fileType(for path: String) -> AVFileType {
  if path.lowercased().hasSuffix(".mov") {
    return .mov
  }
  return .mp4
}

func loadManifest(at url: URL) throws -> Manifest {
  guard let data = FileManager.default.contents(atPath: url.path) else {
    throw ComposeError.unreadableManifest(url)
  }
  return try JSONDecoder().decode(Manifest.self, from: data)
}

func frameImage(
  from generator: AVAssetImageGenerator,
  at time: CMTime,
  clipName: String
) throws -> CGImage {
  do {
    return try generator.copyCGImage(at: time, actualTime: nil)
  } catch {
    throw ComposeError.exportFailed("Could not read frame from \(clipName) at \(time.seconds)s: \(error)")
  }
}

func makeFrameBuffer(
  from pool: CVPixelBufferPool,
  canvas: Manifest.Canvas,
  labels: Manifest.Labels,
  leftImage: CGImage,
  rightImage: CGImage,
  leftCrop: CGRect?,
  rightCrop: CGRect?
) throws -> CVPixelBuffer {
  _ = labels

  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
  guard status == kCVReturnSuccess, let pixelBuffer else {
    throw ComposeError.exportFailed("Could not allocate a frame buffer")
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, [])
  defer {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
  }

  guard
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
  else {
    throw ComposeError.exportFailed("Could not access frame buffer memory")
  }

  let width = CVPixelBufferGetWidth(pixelBuffer)
  let height = CVPixelBufferGetHeight(pixelBuffer)
  let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

  guard let context = CGContext(
    data: baseAddress,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
  ) else {
    throw ComposeError.exportFailed("Could not create a drawing context")
  }

  context.translateBy(x: 0, y: CGFloat(height))
  context.scaleBy(x: 1, y: -1)
  let canvasRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
  context.setFillColor(color(from: canvas.backgroundHex))
  context.fill(canvasRect)

  drawImage(
    crop(leftImage, to: leftCrop),
    in: leftPaneRect(for: canvas),
    context: context
  )
  drawImage(
    crop(rightImage, to: rightCrop),
    in: rightPaneRect(for: canvas),
    context: context
  )

  return pixelBuffer
}

func crop(_ image: CGImage, to rect: CGRect?) -> CGImage {
  guard let rect else {
    return image
  }

  let croppedRect = rect.integral.intersection(
    CGRect(x: 0, y: 0, width: image.width, height: image.height)
  )
  guard
    croppedRect.width > 0,
    croppedRect.height > 0,
    let cropped = image.cropping(to: croppedRect)
  else {
    return image
  }
  return cropped
}

func drawImage(_ image: CGImage, in targetRect: CGRect, context: CGContext) {
  let sourceSize = CGSize(width: image.width, height: image.height)
  let fittedRect = aspectFitRect(for: sourceSize, inside: targetRect)
  context.draw(image, in: fittedRect)
}

func aspectFitRect(for sourceSize: CGSize, inside targetRect: CGRect) -> CGRect {
  let scale = min(targetRect.width / sourceSize.width, targetRect.height / sourceSize.height)
  let fittedWidth = sourceSize.width * scale
  let fittedHeight = sourceSize.height * scale
  return CGRect(
    x: targetRect.minX + ((targetRect.width - fittedWidth) / 2),
    y: targetRect.minY + ((targetRect.height - fittedHeight) / 2),
    width: fittedWidth,
    height: fittedHeight
  )
}

func minimumDuration(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
  CMTimeCompare(lhs, rhs) <= 0 ? lhs : rhs
}

func leftPaneRect(for canvas: Manifest.Canvas) -> CGRect {
  let paneWidth = (
    CGFloat(canvas.width) -
    (canvas.horizontalPadding * 2) -
    canvas.paneGap
  ) / 2
  let paneHeight = CGFloat(canvas.height) - canvas.topPadding - canvas.bottomPadding
  return CGRect(
    x: canvas.horizontalPadding,
    y: canvas.topPadding,
    width: paneWidth,
    height: paneHeight
  )
}

func rightPaneRect(for canvas: Manifest.Canvas) -> CGRect {
  let leftRect = leftPaneRect(for: canvas)
  return CGRect(
    x: leftRect.maxX + canvas.paneGap,
    y: leftRect.minY,
    width: leftRect.width,
    height: leftRect.height
  )
}

func resolvedCropRect(
  sourceCrop: Manifest.SourceCrop?,
  for track: AVAssetTrack,
  clipURL: URL
) throws -> CGRect? {
  guard let sourceCrop else {
    return nil
  }

  let orientedBounds = CGRect(origin: .zero, size: track.naturalSize).applying(track.preferredTransform)
  let orientedSize = CGSize(
    width: abs(orientedBounds.width),
    height: abs(orientedBounds.height)
  )
  let fullRect = CGRect(origin: .zero, size: orientedSize)
  let cropRect = sourceCrop.rect

  guard cropRect.width > 0, cropRect.height > 0 else {
    throw ComposeError.invalidCrop("\(clipURL.lastPathComponent) has a non-positive crop rect \(cropRect)")
  }
  guard fullRect.contains(cropRect) else {
    throw ComposeError.invalidCrop(
      "\(clipURL.lastPathComponent) crop \(cropRect) exceeds oriented bounds \(fullRect)"
    )
  }

  return cropRect
}

func makeTransform(
  for track: AVAssetTrack,
  targetRect: CGRect,
  sourceCrop: CGRect?
) -> CGAffineTransform {
  let orientedBounds = CGRect(origin: .zero, size: track.naturalSize).applying(track.preferredTransform)
  let orientedSize = CGSize(
    width: abs(orientedBounds.width),
    height: abs(orientedBounds.height)
  )
  let cropRect = sourceCrop ?? CGRect(origin: .zero, size: orientedSize)
  let scale = min(
    targetRect.width / cropRect.width,
    targetRect.height / cropRect.height
  )
  let scaledWidth = cropRect.width * scale
  let scaledHeight = cropRect.height * scale

  var transform = track.preferredTransform
  transform = transform.concatenating(
    CGAffineTransform(
      translationX: -orientedBounds.origin.x,
      y: -orientedBounds.origin.y
    )
  )
  transform = transform.concatenating(
    CGAffineTransform(
      translationX: -cropRect.minX,
      y: -cropRect.minY
    )
  )
  transform = transform.concatenating(
    CGAffineTransform(scaleX: scale, y: scale)
  )
  transform = transform.concatenating(
    CGAffineTransform(
      translationX: targetRect.minX + ((targetRect.width - scaledWidth) / 2),
      y: targetRect.minY + ((targetRect.height - scaledHeight) / 2)
    )
  )
  return transform
}

func makeAnimationTool(
  renderSize: CGSize,
  manifest: Manifest
) -> AVVideoCompositionCoreAnimationTool {
  let parentLayer = CALayer()
  parentLayer.frame = CGRect(origin: .zero, size: renderSize)
  parentLayer.backgroundColor = color(from: manifest.canvas.backgroundHex)

  let videoLayer = CALayer()
  videoLayer.frame = CGRect(origin: .zero, size: renderSize)
  parentLayer.addSublayer(videoLayer)

  parentLayer.addSublayer(
    labelLayer(
      text: manifest.labels.left,
      frame: CGRect(
        x: leftPaneRect(for: manifest.canvas).minX,
        y: 28,
        width: leftPaneRect(for: manifest.canvas).width,
        height: 42
      )
    )
  )
  parentLayer.addSublayer(
    labelLayer(
      text: manifest.labels.right,
      frame: CGRect(
        x: rightPaneRect(for: manifest.canvas).minX,
        y: 28,
        width: rightPaneRect(for: manifest.canvas).width,
        height: 42
      )
    )
  )

  return AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer,
    in: parentLayer
  )
}

func labelLayer(text: String, frame: CGRect) -> CATextLayer {
  let layer = CATextLayer()
  layer.frame = frame
  layer.string = text
  layer.alignmentMode = .center
  layer.foregroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.94)
  layer.fontSize = 28
  layer.contentsScale = 2
  return layer
}

func color(from hex: String) -> CGColor {
  let normalized = hex.replacingOccurrences(of: "#", with: "")
  guard normalized.count == 6, let value = Int(normalized, radix: 16) else {
    return CGColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1)
  }
  let red = CGFloat((value >> 16) & 0xFF) / 255
  let green = CGFloat((value >> 8) & 0xFF) / 255
  let blue = CGFloat(value & 0xFF) / 255
  return CGColor(red: red, green: green, blue: blue, alpha: 1)
}
