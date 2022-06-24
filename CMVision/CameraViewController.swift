//
//  CameraViewController.swift
//  VisionSample
//
//  Created by npc on 2022/06/23.
//

import UIKit

final class CameraViewController: UIViewController {

    // 画面を読み込む時の処理(viewDidLoadより前）
    override func loadView() {
        // viewをCameraPreviewにする
        // view→ViewControllerが必ず持っているView
        view = CameraPreview()
    }
    
    // viewにアクセスするためのコンピューテッドプロパティ
    private var cameraView: CameraPreview {
        view as! CameraPreview
    }
}
