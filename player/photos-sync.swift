// Copies new videos (up to 60 s) from the Photos album "Brilliant Moves" into ~/Movies/Brilliant Moves.
// Save edits to that album on your iPhone; iCloud Photos brings them to the Mac, this brings them to the mod.
// The album is only read, never changed. No album or no Photos access: exits quietly.
// Usage: photos-sync [album] [folder]
// Build: see build.sh
import Foundation
import Photos

let args = CommandLine.arguments
let ALBUM = args.count > 1 ? args[1] : "Brilliant Moves"
let FOLDER = args.count > 2 ? args[2] : NSHomeDirectory() + "/Movies/Brilliant Moves"
let MAX_SEC = 60.0
let fm = FileManager.default

let sem = DispatchSemaphore(value: 0)
var status = PHAuthorizationStatus.notDetermined
PHPhotoLibrary.requestAuthorization(for: .readWrite) { status = $0; sem.signal() }
sem.wait()
guard status == .authorized else { print("no Photos access"); exit(0) }

let o = PHFetchOptions()
o.predicate = NSPredicate(format: "title == %@", ALBUM)
guard let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: o).firstObject else {
  print("no album \(ALBUM)")
  exit(0)
}
try? fm.createDirectory(atPath: FOLDER, withIntermediateDirectories: true)

var copied = 0, known = 0, long = 0, failed = 0
PHAsset.fetchAssets(in: album, options: nil).enumerateObjects { asset, _, _ in
  guard asset.mediaType == .video else { return }
  if asset.duration > MAX_SEC { long += 1; return }
  guard let res = PHAssetResource.assetResources(for: asset).first(where: { $0.type == .video || $0.type == .fullSizeVideo }) else { return }
  // One file per asset: the id keeps two "Download.mp4" apart, the name keeps it readable.
  let id = asset.localIdentifier.prefix(8)
  let dst = URL(fileURLWithPath: FOLDER).appendingPathComponent("\(id)-\(res.originalFilename)")
  if fm.fileExists(atPath: dst.path) { known += 1; return }

  let tmp = dst.appendingPathExtension("part")
  try? fm.removeItem(at: tmp)
  let r = PHAssetResourceRequestOptions()
  r.isNetworkAccessAllowed = true // iCloud-only videos get downloaded
  var ok = false
  let s = DispatchSemaphore(value: 0)
  PHAssetResourceManager.default().writeData(for: res, toFile: tmp, options: r) { ok = $0 == nil; s.signal() }
  s.wait()
  if ok, (try? fm.moveItem(at: tmp, to: dst)) != nil { copied += 1 } else { try? fm.removeItem(at: tmp); failed += 1 }
}
print("copied \(copied), already there \(known), over 60 s \(long), failed \(failed)")
