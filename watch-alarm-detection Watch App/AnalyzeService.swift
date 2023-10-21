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
import UserNotifications // この行を追加

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
    
    // 警報を検知したときの通知をトリガーする関数
    func triggerNotification() {
        let content = UNMutableNotificationContent()
        content.title = "警報検知"  // この行でタイトルを設定
        content.body = "警報が検知されました。"  // この行で本文を設定
        content.sound = UNNotificationSound.default  // この行でサウンドを設定
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
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
            switch classification.identifier {
            case "防災警報":
                self.detectedView = .warning2
                triggerNotification() // この行を追加
            case "火災報知器1(上下)":
                self.detectedView = .warning1
                triggerNotification() // この行を追加
            case "火災報知器2(上上)":
                self.detectedView = .warning1
                triggerNotification() // この行を追加
            default:
                break
            }
        }
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("ResultUpdated"), object: nil)
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}


