import Foundation
import AppKit

class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    private let githubOwner = "nguyenxuanhoa493"
    private let githubRepo = "Windown-plus-V-for-Mac"
    
    @Published var latestVersion: String?
    @Published var isChecking = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var updateAvailable = false
    @Published var updateError: String?
    
    var currentVersion: String {
        // Ưu tiên đọc từ Info.plist của app bundle (được cập nhật khi update)
        if let bundlePath = Bundle.main.bundlePath as String?,
           let plistPath = URL(fileURLWithPath: bundlePath)
            .appendingPathComponent("Contents/Info.plist").path as String?,
           FileManager.default.fileExists(atPath: plistPath),
           let plistData = FileManager.default.contents(atPath: plistPath),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
           let version = plist["CFBundleShortVersionString"] as? String {
            return version
        }
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }
    
    private var releaseDownloadURL: URL?
    private var releaseNotes: String?
    
    // MARK: - Check for updates
    
    func checkForUpdates(silent: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        updateError = nil
        
        let urlString = "https://api.github.com/repos/\(githubOwner)/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                if let error = error {
                    if !silent {
                        self?.updateError = error.localizedDescription
                    }
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    if !silent {
                        self?.updateError = "Cannot parse release info"
                    }
                    return
                }
                
                // Remove 'v' prefix if present
                let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                self?.latestVersion = version
                self?.releaseNotes = json["body"] as? String
                
                // Find binary asset (look for Clipboard-binary.zip or Clipboard.zip)
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String,
                           let downloadURL = asset["browser_download_url"] as? String {
                            if name == "Clipboard-binary.zip" || name == "Clipboard.zip" {
                                self?.releaseDownloadURL = URL(string: downloadURL)
                                break
                            }
                        }
                    }
                    // Fallback: use first zip asset
                    if self?.releaseDownloadURL == nil {
                        for asset in assets {
                            if let name = asset["name"] as? String,
                               let downloadURL = asset["browser_download_url"] as? String,
                               name.hasSuffix(".zip") {
                                self?.releaseDownloadURL = URL(string: downloadURL)
                                break
                            }
                        }
                    }
                }
                
                if self?.isNewerVersion(version) == true {
                    self?.updateAvailable = true
                    self?.showUpdateAlert(version: version)
                } else if !silent {
                    self?.showNoUpdateAlert()
                }
            }
        }.resume()
    }
    
    // MARK: - Version comparison
    
    private func isNewerVersion(_ remote: String) -> Bool {
        let current = currentVersion.split(separator: ".").compactMap { Int($0) }
        let remote = remote.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(current.count, remote.count)
        for i in 0..<maxCount {
            let c = i < current.count ? current[i] : 0
            let r = i < remote.count ? remote[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }
    
    // MARK: - Download & Install (binary-only replacement)
    
    func downloadAndInstall() {
        guard let downloadURL = releaseDownloadURL else {
            updateError = "No download URL available"
            return
        }
        
        isDownloading = true
        downloadProgress = 0
        updateError = nil
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                
                if let error = error {
                    self?.updateError = error.localizedDescription
                    return
                }
                
                guard let tempURL = tempURL else {
                    self?.updateError = "Download failed"
                    return
                }
                
                self?.installUpdate(from: tempURL)
            }
        }
        
        // Observe progress
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
            }
        }
        // Keep observation alive
        objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
        
        task.resume()
    }
    
    private func installUpdate(from zipURL: URL) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("ClipboardUpdate-\(UUID().uuidString)")
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            let zipPath = tempDir.appendingPathComponent("update.zip")
            try fileManager.copyItem(at: zipURL, to: zipPath)
            
            // Unzip
            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            unzipProcess.arguments = ["-o", zipPath.path, "-d", tempDir.path]
            try unzipProcess.run()
            unzipProcess.waitUntilExit()
            
            // Tìm Clipboard.app trong package giải nén
            var newAppBundlePath: URL?
            let directApp = tempDir.appendingPathComponent("Clipboard.app")
            if fileManager.fileExists(atPath: directApp.path) {
                newAppBundlePath = directApp
            }
            
            // Tìm đệ quy nếu không thấy trực tiếp
            if newAppBundlePath == nil {
                if let enumerator = fileManager.enumerator(at: tempDir, includingPropertiesForKeys: [.isDirectoryKey]) {
                    while let fileURL = enumerator.nextObject() as? URL {
                        if fileURL.lastPathComponent == "Clipboard.app" {
                            newAppBundlePath = fileURL
                            break
                        }
                    }
                }
            }
            
            guard let appBundlePath = newAppBundlePath else {
                updateError = "Clipboard.app not found in update package"
                try? fileManager.removeItem(at: tempDir)
                return
            }
            
            let currentAppPath = Bundle.main.bundlePath
            
            // Script thay thế nội dung app bundle, KHÔNG codesign
            // macOS TCC dùng path để nhận dạng unsigned app → quyền Accessibility giữ nguyên
            let currentContents = currentAppPath + "/Contents"
            let newContents = appBundlePath.path + "/Contents"
            
            let script = """
            #!/bin/bash
            sleep 1
            
            # Xóa code signature cũ (nếu có) để app thành unsigned
            # macOS TCC dùng path cho unsigned app → giữ quyền Accessibility
            rm -rf "\(currentContents)/_CodeSignature"
            
            # Thay binary
            cp -f "\(newContents)/MacOS/Clipboard" "\(currentContents)/MacOS/Clipboard"
            chmod +x "\(currentContents)/MacOS/Clipboard"
            
            # Thay Info.plist (cập nhật version)
            cp -f "\(newContents)/Info.plist" "\(currentContents)/Info.plist"
            
            # Thay Resources
            rm -rf "\(currentContents)/Resources"
            cp -R "\(newContents)/Resources" "\(currentContents)/Resources"
            
            # Xóa extended attributes để tránh Gatekeeper block
            xattr -cr "\(currentAppPath)" 2>/dev/null
            
            # Dọn dẹp
            rm -rf "\(tempDir.path)"
            
            # Mở lại app
            open "\(currentAppPath)"
            """
            
            let scriptPath = tempDir.appendingPathComponent("update.sh")
            try script.write(to: scriptPath, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
            
            // Hiển thị xác nhận
            let alert = NSAlert()
            alert.messageText = Localization.shared.localizedString("update_ready")
            alert.informativeText = Localization.shared.localizedString("update_restart_message")
            alert.alertStyle = .informational
            alert.addButton(withTitle: Localization.shared.localizedString("update_restart_now"))
            alert.addButton(withTitle: Localization.shared.localizedString("update_later"))
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let updateProcess = Process()
                updateProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
                updateProcess.arguments = [scriptPath.path]
                try updateProcess.run()
                
                NSApp.terminate(nil)
            } else {
                try? fileManager.removeItem(at: tempDir)
            }
            
        } catch {
            updateError = error.localizedDescription
            try? fileManager.removeItem(at: tempDir)
        }
    }
    
    // MARK: - Alerts
    
    private func showUpdateAlert(version: String) {
        let alert = NSAlert()
        alert.messageText = Localization.shared.localizedString("update_available")
        alert.informativeText = String(format: Localization.shared.localizedString("update_new_version"), version, currentVersion)
        if let notes = releaseNotes, !notes.isEmpty {
            alert.informativeText += "\n\n" + notes
        }
        alert.alertStyle = .informational
        alert.addButton(withTitle: Localization.shared.localizedString("update_download"))
        alert.addButton(withTitle: Localization.shared.localizedString("update_later"))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            downloadAndInstall()
        }
    }
    
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = Localization.shared.localizedString("update_no_update")
        alert.informativeText = String(format: Localization.shared.localizedString("update_current_version"), currentVersion)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
