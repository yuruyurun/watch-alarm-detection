//
//  AnalyzeService.swift
//  watchtest Watch App
//
//  Created by Kyosuke Yurugi on 2023/09/28.
//

// AnalyzeService.swift

import Foundation
import AVFAudio
import SoundAnalysis
import SwiftUI
import CoreML
import UserNotifications

class AnalyzeService: NSObject, ObservableObject {
    @Published var currentItem: String = "None" {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    static let shared = AnalyzeService()
    
    let analysisQueue = DispatchQueue(label: "com.bgesoftware.AnalysisQueue")
    
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var inputBus: AVAudioNodeBus!
    var inputFormat: AVAudioFormat!
    
    var streamAnalyzer: SNAudioStreamAnalyzer!
    
    @ObservedObject var resultsObserver: ResultsObserver = ResultsObserver()
    
    func stopAudioEngine() {
        audioEngine.stop()
    }
    
    func startAudioEngine() {
        audioEngine = AVAudioEngine()
        inputBus = AVAudioNodeBus(0)
        inputFormat = audioEngine.inputNode.inputFormat(forBus: inputBus)
        
        do {
            try audioEngine.start()
            
            streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
            
            let classifySoundRequest = try makeRequest(keiho(configuration: .init()).model)
            print(classifySoundRequest.knownClassifications)
            try streamAnalyzer.add(classifySoundRequest, withObserver: resultsObserver)
            
            installAudioTap()
            
            let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(updatedResult), name: Notification.Name("ResultUpdated"), object: nil)
            
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    func makeRequest(_ customModel: MLModel? = nil) throws -> SNClassifySoundRequest {
        if let model = customModel {
            let customRequest = try SNClassifySoundRequest(mlModel: model)
            return customRequest
        }
        
        let version1 = SNClassifierIdentifier.version1
        let request = try SNClassifySoundRequest(classifierIdentifier: version1)
        return request
    }
    
    @objc func updatedResult() {
        self.currentItem = resultsObserver.currentItem
    }
    
    func installAudioTap() {
        audioEngine.inputNode.installTap(onBus: inputBus,
                                         bufferSize: 8192,
                                         format: inputFormat,
                                         block: analyzeAudio(buffer:at:))
    }
    
    func analyzeAudio(buffer: AVAudioBuffer, at time: AVAudioTime) {
        analysisQueue.async {
            self.streamAnalyzer.analyze(buffer,
                                        atAudioFramePosition: time.sampleTime)
        }
    }
}

class ResultsObserver: NSObject, SNResultsObserving, ObservableObject {
    var currentItem: String = "None" {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var detectedView: WarningViewType = .none
    // 警報の認識回数をカウントする変数
    var warningCount: Int = 0
    // 最初の警報を検知した時刻を保持する変数
    var firstWarningDate: Date?
    
    // 最後に通知をトリガーした時刻を保持する変数
    var lastNotificationDate: Date?
    
    func triggerRepeatedHapticFeedback(times: Int, interval: TimeInterval) {
        guard times > 0 else { return }
        
        // ハプティックフィードバックを生成
        WKInterfaceDevice.current().play(.notification)
        
        // 指定された間隔後に再帰的に関数を呼び出す
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.triggerRepeatedHapticFeedback(times: times - 1, interval: interval)
        }
    }
    
    func triggerNotification(for warningType: WarningViewType) {
        let content = UNMutableNotificationContent()
        
        switch warningType {
        case .warning1:
            content.title = "火災警報"
            content.body = "火災報知器が検知されました。"
        case .warning2:
            content.title = "防災警報"
            content.body = "防災警報が検知されました。"
        default:
            return
        }
        
        content.sound = nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        if let lastDate = lastNotificationDate, Date().timeIntervalSince(lastDate) < 120 {
            return
        }
        
        // ハプティックフィードバックを回、1秒の間隔で繰り返す
        triggerRepeatedHapticFeedback(times: 5, interval: 1.0)
        
        UNUserNotificationCenter.current().add(request)
        lastNotificationDate = Date()
    }


    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else  { return }
        guard let classification = result.classifications.first else { return }
        
        let timeInSeconds = result.timeRange.start.seconds
        let formattedTime = String(format: "%.2f", timeInSeconds)
        print("Analysis result for audio at time: \(formattedTime)")
        
        let percent = classification.confidence * 100.0
        let percentString = String(format: "%.2f%%", percent)
        print("\(classification.identifier): \(percentString) confidence.\n")
        
        self.currentItem = "\(classification.identifier): \(percentString)"
        
        if classification.confidence >= 0.9 {
            // 最初の警報を検知した時刻を設定
            if firstWarningDate == nil {
                firstWarningDate = Date()
            }
            
            // カウンターをインクリメント
            warningCount += 1
            
            // 30秒が経過したか、カウンターが5に達した場合
            if let startDate = firstWarningDate, Date().timeIntervalSince(startDate) > 30 || warningCount >= 5 {
                if warningCount >= 5 {
                    switch classification.identifier {
                    case "防災警報":
                        self.detectedView = .warning2
                        triggerNotification(for: .warning2)
                    case "火災報知器1(上下)":
                        self.detectedView = .warning1
                        triggerNotification(for: .warning1)
                    case "火災報知器2(上上)":
                        self.detectedView = .warning1
                        triggerNotification(for: .warning1)
                    default:
                        break
                    }
                }
                // カウンターと時刻をリセット
                warningCount = 0
                firstWarningDate = nil
            }
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}


