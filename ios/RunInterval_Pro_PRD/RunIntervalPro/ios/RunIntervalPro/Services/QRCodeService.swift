import Foundation
import CoreImage
import UIKit

// MARK: - QRCodeService
final class QRCodeService {
    static let shared = QRCodeService()

    private init() {}

    /// Encodes a workout to a compact JSON string for QR code embedding
    func encodeWorkout(_ workout: Workout) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        do {
            let data = try encoder.encode(workout)
            return data.base64EncodedString()
        } catch {
            print("QR encode error: \(error)")
            return nil
        }
    }

    /// Decodes a workout from a base64 string
    func decodeWorkout(from string: String) -> Workout? {
        guard let data = Data(base64Encoded: string) else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Workout.self, from: data)
        } catch {
            print("QR decode error: \(error)")
            return nil
        }
    }

    /// Generates a QR code image from a workout
    func generateQRImage(from workout: Workout, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let encoded = encodeWorkout(workout) else { return nil }
        return generateQRImage(from: encoded, size: size)
    }

    func generateQRImage(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        guard let ciImage = filter?.outputImage else { return nil }

        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
