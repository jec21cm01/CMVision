//
//  CameraView.swift
//  VisionSample
//
//  Created by npc on 2022/06/23.
//

import SwiftUI

// 今回はUIViewではなく、UIViewControllerRepresentable
struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController
    
    var pointsProcessorHandler: (([CGPoint]) -> Void)?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.pointsProcessorHandler = pointsProcessorHandler
        
        return cameraViewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        
    }
}
