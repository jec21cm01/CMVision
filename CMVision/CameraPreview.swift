//
//  CameraPreview.swift
//  VisionSample
//
//  Created by npc on 2022/06/23.
//

import UIKit
// ↓保存を使わないならばAVFoudationでも良い
import Photos


final class CameraPreview: UIView {
    // UIViewが持っている静的プロパティのオーバーライド
    // staticのようなものだけれども、staticはオーバーライドできない
    // classはオーバーライドできる
    // layerClassはこのViewを作る時に必ず１つは持っているlayerを
    // どの型にするか決めることができる
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        // 1枚目のlayer（ルートレイヤー）を返す
        layer as! AVCaptureVideoPreviewLayer
    }
}
