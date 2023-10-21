//
//  watch_alarm_detectionApp.swift
//  watch-alarm-detection Watch App
//
//  Created by Kyosuke Yurugi on 2023/10/21.
//

import SwiftUI
import UserNotifications

@main
struct watch_alarm_detection_Watch_AppApp: App {
    init() {
        // 通知の許可を要求
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("通知の許可が得られました")
            } else {
                print("通知の許可が拒否されました")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
