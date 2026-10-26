//
//  NFCFrameDetector.swift
//  POC
//

import CoreNFC

final class NFCFrameDetector: NSObject, NFCTagReaderSessionDelegate {
    private var session: NFCTagReaderSession?
    private var onTagDetected: (() -> Void)?

    func startScanning(onTagDetected: @escaping () -> Void) {
        self.onTagDetected = onTagDetected

        guard NFCTagReaderSession.readingAvailable else {
            return
        }

        guard let readerSession = NFCTagReaderSession(
            pollingOption: .iso14443,
            delegate: self,
            queue: .main
        ) else {
            return
        }

        readerSession.alertMessage = "Hold your iPhone near the attached frame."
        session = readerSession
        readerSession.begin()
    }

    func stopScanning() {
        session?.invalidate()
        session = nil
        onTagDetected = nil
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // The system NFC sheet is now actively scanning.
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            return
        }

        session.connect(to: tag) { [weak self, weak session] error in
            guard let self, let session, error == nil else {
                session?.restartPolling()
                return
            }

            guard case .miFare(let miFareTag) = tag else {
                session.alertMessage = "Please attach the NTAG213 frame."
                session.restartPolling()
                return
            }

            // NTAG213 is an NFC-A/MiFare-compatible NDEF tag.
            miFareTag.queryNDEFStatus { [weak self, weak session] status, _, error in
                guard let self, let session else {
                    return
                }

                guard error == nil, status != .notSupported else {
                    session.alertMessage = "Please attach the NTAG213 frame."
                    session.restartPolling()
                    return
                }

                self.onTagDetected?()
                session.alertMessage = "Frame detected."
                session.invalidate()
                self.session = nil
                self.onTagDetected = nil
            }
        }
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        // The session closes after a successful one-time detection or when cancelled.
    }
}
