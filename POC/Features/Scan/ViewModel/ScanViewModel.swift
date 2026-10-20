//
//  ScanViewModel.swift
//  POC
//
//  Created by Alessandro Moreno Lawadinata on 20/10/26.
//

import SwiftUI
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {
    let patientID: UUID
    
    @Published var selectedEye: EyeSide = .right
    
    @Published var rightImage: UIImage?
    @Published var leftImage: UIImage?
    @Published var rightResult: SegmentationResult?
    @Published var leftResult: SegmentationResult?
    
    @Published var selectedImage: UIImage?
    @Published var isReviewing = false
    @Published var isAnalyzing = false
    @Published var showResult = false
    @Published var errorMessage: String?
    
    private let inferenceService: ImageInferenceService?
    
    init(patientID: UUID) {
        self.patientID = patientID
        self.inferenceService = try? ImageInferenceService()
    }
    
    var isLastEye: Bool {
        if selectedEye == .right {
            return leftImage != nil
        }
        else {
            return rightImage != nil
        }
    }
    func onPhotoCaptured(_ image: UIImage){
        selectedImage = image
        isReviewing = true
    }
    func onRetake() {
        if selectedEye == .right {
            rightImage = nil
        }
        else {
            leftImage = nil
        }
        selectedImage = nil
        isReviewing = false
    }
    
    func handleConfirmOrAnalyze(image: UIImage, onNeedCameraResume: () -> Void) {
        if selectedEye == .right {
            rightImage = image
        }
        else {
            leftImage = image
        }
        if !isLastEye {
            selectedEye = (selectedEye == .right) ? .left : .right
            selectedImage = nil
            isReviewing = false
            onNeedCameraResume()
        }
        else {
            analyzeBothEyes()
        }
    }
    
    func analyzeBothEyes(){
        guard !isAnalyzing else {return}
        guard let service = inferenceService else{
            errorMessage = "Model AI Core ML tidak ditemukan."
            return
        }
        isAnalyzing = true
        
        Task {
            do{
                var rRes: SegmentationResult?
                var lRes: SegmentationResult?
                
                if let rImg = self.rightImage{
                    rRes = try service.predict(image: rImg)
                }
                if let lImg = self.leftImage {
                    lRes = try service.predict(image: lImg)
                }
                self.rightResult = rRes
                self.leftResult = lRes
                self.isAnalyzing = false
                self.showResult = true
            }
            catch{
                self.isAnalyzing = false
                self.errorMessage = "Analisis AI gagal: \(error.localizedDescription)"
            }
        }
    }
    
    func buildScreeingSession() -> ScreeningSession {
        let sessionID = UUID()
        
        let leftRecord = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .right,
            image: rightImage,
            segmentationResult: rightResult,
            isDummy: rightImage == nil
        )
        
        let rightRecord = EyeExaminationRecord(
            sessionID: sessionID,
            eyeSide: .right,
            image: rightImage,
            segmentationResult: rightResult,
            isDummy: rightImage == nil
        )
        
        return ScreeningSession(
            id: sessionID,
            patientID: patientID,
            examDate: .now,
            status: .completed,
            leftEye: leftRecord,
            rightEye: rightRecord
        )
    }
    
}
