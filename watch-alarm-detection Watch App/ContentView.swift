//
//  ContentView.swift
//  watch-alarm-detection Watch App
//
//  Created by Kyosuke Yurugi on 2023/10/21.
//

import SwiftUI

enum WarningViewType {
    case warning1, warning2, none
}

struct ContentView: View {
    @State private var started: Bool = false
    @State private var currentDetectedSoundSource: String = "認識した音"
    @StateObject var resultsObserver = AnalyzeService.shared.resultsObserver
    
    var buttonText: String {
        if started {
            return "Stop"
        }
        return "Start"
    }
    
    var statusText: String {
        if started {
            return "Running"
        }
        return "Idle"
    }
    
    var body: some View {
        VStack {
            Text("警報認識")
                .font(.title)
                .padding()
            
            Button(buttonText) {
                started.toggle()
                if started {
                    AnalyzeService.shared.startAudioEngine()
                } else {
                    AnalyzeService.shared.stopAudioEngine()
                    currentDetectedSoundSource = ""
                }
            }
            .font(.body)
            
            Spacer()
            
            Text(self.currentDetectedSoundSource.capitalized.replacingOccurrences(of: "_", with: " ")).font(.body)
            
            Spacer()
        }
        .onAppear {
            resultsObserver.detectedView = .none
        }
        .background(NavigationLink("", destination: WarningView1(), isActive: .init(get: { resultsObserver.detectedView == .warning1 }, set: { _ in })).opacity(0)) // この行を追加
        .background(NavigationLink("", destination: WarningView2(), isActive: .init(get: { resultsObserver.detectedView == .warning2 }, set: { _ in })).opacity(0)) // この行を追加
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResultUpdated")))
        { _ in
            self.currentDetectedSoundSource = AnalyzeService.shared.currentItem
            print("Update received in SwiftUI View")
        }
    }
}

extension NSNotification {
    static let ImageClick = Notification.Name.init("ImageClick")
}


//3.5と7秒や3と6秒などでやるロードのノイズなどを追加学習
#Preview {
    ContentView()
}
//
