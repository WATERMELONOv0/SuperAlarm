import Foundation
import UniformTypeIdentifiers

class AudioStorageManager {
    static let shared = AudioStorageManager()
    
    private init() {}
    
    /// The Library/Sounds directory URL where UNNotificationSound expects custom sounds
    var soundsDirectoryURL: URL? {
        guard let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }
        let soundsPath = libraryPath.appendingPathComponent("Sounds")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: soundsPath.path) {
            do {
                try FileManager.default.createDirectory(at: soundsPath, withIntermediateDirectories: true)
            } catch {
                print("Failed to create Sounds directory: \(error)")
                return nil
            }
        }
        
        return soundsPath
    }
    
    /// Copies an imported audio file to the Library/Sounds directory
    /// - Parameter sourceURL: The URL of the imported file
    /// - Returns: The filename of the copied file, or nil if failed
    func copyAudioFileToSoundsDirectory(from sourceURL: URL) -> String? {
        guard sourceURL.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource")
            return nil
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }
        
        guard let soundsDir = soundsDirectoryURL else { return nil }
        
        let filename = sourceURL.lastPathComponent
        let destinationURL = soundsDir.appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return filename
        } catch {
            print("Failed to copy audio file: \(error)")
            return nil
        }
    }
    
    /// Lists all custom audio files in the Sounds directory
    func listSavedAudioFiles() -> [String] {
        guard let soundsDir = soundsDirectoryURL else { return [] }
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: soundsDir.path)
            // Filter out system hidden files if necessary
            return files.filter { !$0.hasPrefix(".") }.sorted()
        } catch {
            print("Failed to list audio files: \(error)")
            return []
        }
    }
    
    /// Deletes a custom audio file from the Sounds directory
    func deleteAudioFile(named filename: String) -> Bool {
        guard let soundsDir = soundsDirectoryURL else { return false }
        let fileURL = soundsDir.appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                return true
            }
            return false
        } catch {
            print("Failed to delete audio file: \(error)")
            return false
        }
    }
}
