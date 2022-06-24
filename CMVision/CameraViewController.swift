//
//  CameraViewController.swift
//  VisionSample
//
//  Created by npc on 2022/06/23.
//

import UIKit
import AVFoundation
import Vision

final class CameraViewController: UIViewController {
    
    private var cameraFeedSession: AVCaptureSession?
    private let videoDataOutputQueue = DispatchQueue(label: "camera", qos: .userInteractive)
    
    // 手の検出
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        // 検出する手の数（2つ)
        request.maximumHandCount = 2
        return request
    }()
    
    // ポイント処理
    var pointsProcessorHandler: (([CGPoint]) -> Void)?
    
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
    
    func processPoints(_ fingerTips: [CGPoint]) {
        let convertedPoints = fingerTips.map {
            
            // キャプチャの座標からlayerの座標に変換する
            // キャプチャの座標とlayerの座標は異なる
            cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
        }
        
        pointsProcessorHandler?(convertedPoints)
    }
}

// 動画情報からサンプルデータを取得して監視するデリゲート
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // captureOutputが出力し終わった時
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // 指先の座標
        var fingerTips: [CGPoint] = []
        // このメソッドを抜けるときに実行する処理を書くときに使うキーワードがdefer
        // deferの中にあるものは、処理を抜ける時に実行する
        defer {
            DispatchQueue.main.sync {
                
                self.processPoints(fingerTips)
            }
        }
        
        // リクエストを処理する
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        
        do {
            // この解析が正常終了されなかったらerrorに行く
            try handler.perform([handPoseRequest])
            
            // 手の検出結果（配列）から最初の2つをとる。（手が2つ以上ないから）
            guard let results = handPoseRequest.results?.prefix(2),
                  !results.isEmpty else { return }
            
            // 認識された座標
            var recognizedPoints: [VNRecognizedPoint] = []
            
            // 手の検出結果から手の座標をとる
            try results.forEach{ observation in
                // 手から全ての指をとる（指は配列）
                let fingers = try observation.recognizedPoints(.all)
                
                // 親指(thumbTip)のポイント
                if let thumbTipPoint = fingers[.thumbTip] {
                    recognizedPoints.append(thumbTipPoint)
                }
                // 人差し指(indexTip)のポイント
                if let indexTipPoint = fingers[.indexTip] {
                    recognizedPoints.append(indexTipPoint)
                }
                // 中指（middleTip)のポイント
                if let middleTipPoint = fingers[.middleTip] {
                    recognizedPoints.append(middleTipPoint)
                }
                // 薬指(ringTip）のポイント
                if let ringTipPoint = fingers[.ringTip] {
                    recognizedPoints.append(ringTipPoint)
                }
                // 小指(littleTip)のポイント
                if let littleTipPoint = fingers[.littleTip] {
                    recognizedPoints.append(littleTipPoint)
                }
            }
            
            
            fingerTips = recognizedPoints.filter{ point in
                // 精度の高い値のみ取得する
                point.confidence > 0.88
            }
            .map { point in
                // 座標の型変換
                // Visionの座標は左下が原点。キャプチャは左上が原点。
                // y座標のみ、逆位置にする
                CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
            
        } catch {
            // エラーが起きたらカメラを止める
            cameraFeedSession?.stopRunning()
        }
    }
}
