import Vision
import CoreGraphics
import Foundation

/// Runs parallel Vision requests on a single VNImageRequestHandler (inspired by Viz).
enum VisionPipeline {
    /// Analyze a CGImage with text recognition and barcode detection in one pass.
    static func analyzeImage(_ cgImage: CGImage) async -> VisionResult {
        await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            let textRequest = VNRecognizeTextRequest()
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true

            let barcodeRequest = VNDetectBarcodesRequest()

            // Run both requests in parallel on the same handler
            do {
                try handler.perform([textRequest, barcodeRequest])
            } catch {
                continuation.resume(returning: .empty)
                return
            }

            let texts: [String] = (textRequest.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            let barcodes: [String] = (barcodeRequest.results ?? []).compactMap { observation in
                observation.payloadStringValue
            }

            continuation.resume(returning: VisionResult(text: texts, barcodes: barcodes))
        }
    }
}
