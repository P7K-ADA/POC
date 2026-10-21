//
//  EyeExaminationRecord.swift
//  POC
//
//  Created by Carolyn Santana on 21/10/26.
//



import Foundation
import UIKit

struct EyeExaminationRecord: Identifiable {
    let id: UUID
    let sessionID: UUID
    let eyeSide: EyeSide
    let image: UIImage?
    let segmentationResult: SegmentationResult?
    let isDummy: Bool

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        eyeSide: EyeSide,
        image: UIImage?,
        segmentationResult: SegmentationResult?,
        isDummy: Bool = false
    ) {
        self.id = id
        self.sessionID = sessionID
        self.eyeSide = eyeSide
        self.image = image
        self.segmentationResult = segmentationResult
        self.isDummy = isDummy
    }

    var verticalCDR: Double? {
        segmentationResult?.verticalCDR
    }
}
