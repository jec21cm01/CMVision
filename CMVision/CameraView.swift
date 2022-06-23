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
    
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        
    }
}
