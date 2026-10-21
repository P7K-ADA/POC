//
//  LocalFileStorage.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 21/10/26.
//

import UIKit

final class LocalFileStorage {
    static let shared = LocalFileStorage()
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL{
        fileManager.urls(for: .documentDirectory,  in: .userDomainMask) [0]
    }
    
    func saveImage(_ image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        
        let fullURL = documentsDirectory.appendingPathComponent("\(fileName).jpg")
        do {
            try data.write(to: fullURL, options: .atomic)
            return "\(fileName).jpg"
        }
        catch {
            print("Gagal menyimpan gambar: \(error)")
            return nil
        }
    }
    
    func saveMask(data: [UInt8], fileName: String) -> String? {
        let fullURL = documentsDirectory.appendingPathComponent("\(fileName).bin")
        do {
            try Data(data).write(to: fullURL, options: .atomic)
            return "\(fileName).bin"
        }
        catch{
            print("Gagal menyimpan mask: \(error)")
            return nil
        }
    }
    
    func loadImage(from relativePath: String) -> UIImage? {
        let fullURL = documentsDirectory.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fullURL) else { return nil }
        return UIImage(data: data)
    }

    func loadMask(from relativePath: String) -> [UInt8]? {
        let fullURL = documentsDirectory.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fullURL) else { return nil }
        return Array(data)
    }
    
    func deleteFile(at relativePath: String) {
        let fullURL = documentsDirectory.appendingPathComponent(relativePath)
        try? fileManager.removeItem(at: fullURL)
    }

}
