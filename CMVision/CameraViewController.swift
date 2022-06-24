//
//  CameraViewController.swift
//  VisionSample
//
//  Created by npc on 2022/06/23.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    
    private var cameraFeedSession: AVCaptureSession?
    private let videoDataOutputQueue = DispatchQueue(label: "camera", qos: .userInteractive)
    
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
    
    // viewが表示された後の処理
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // セッションを初期化する
        if cameraFeedSession == nil {
            setupAVSession()
            
            // 前回と同じ
            cameraView.previewLayer.session = cameraFeedSession
            cameraView.previewLayer.videoGravity = .resizeAspectFill
            
            DispatchQueue(label: "background", qos: .userInitiated).async {
                self.cameraFeedSession?.startRunning()
            }
            
        }
    }
    
    func setupAVSession() {
        
        var mainCamera: AVCaptureDevice? = nil
        var innerCamera: AVCaptureDevice? = nil
        var device: AVCaptureDevice? = nil
        
        // 今回はフロントカメラを優先する
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        // 条件を満たしたデバイスを取得する（複数あるかもしれない）
        let devices = deviceDiscoverySession.devices
        // 取得したデバイスを振り分ける。もしかしたら両方ないかもしれない。
        for device in devices {
            if device.position == .back {
                mainCamera = device
            } else if device.position == .front {
                innerCamera = device
            }
        }
        
        // 今回はインナーカメラがメイン
        device = innerCamera == nil ? mainCamera : innerCamera
        
        guard let device = device,
              let captureDeviceInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 使い捨てsession
        // この書き方ならguardの時にいちいちcommitしなくてもこのメソッドから抜けた時に破棄される
        let session = AVCaptureSession()
        session.beginConfiguration()
        // 今回は写真を撮らないので、写真用の最高画質である必要はない
        session.sessionPreset = .high
        
        guard session.canAddInput(captureDeviceInput) else { return }
        
        session.addInput(captureDeviceInput)
        
        // 今回アウトプットはレイヤーにのみ使う
        let captureDeviceOutput = AVCaptureVideoDataOutput()
        guard session.canAddOutput(captureDeviceOutput) else { return }
        session.addOutput(captureDeviceOutput)
        // フレーム処理を適切に行うためのデリゲートの設定
        captureDeviceOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        session.commitConfiguration()
        cameraFeedSession = session
        
    }
}

// 動画情報からサンプルデータを取得して監視するデリゲート
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}
