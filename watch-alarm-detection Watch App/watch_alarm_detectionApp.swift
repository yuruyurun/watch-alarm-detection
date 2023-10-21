//
//  watch_alarm_detectionApp.swift
//  watch-alarm-detection Watch App
//
//  Created by Kyosuke Yurugi on 2023/10/21.
//

// watch-alarm-detection.swift

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
        
        // デリゲートの設定
        UNUserNotificationCenter.current().delegate = NotificationDelegate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// デリゲートの実装
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでの通知表示を許可
        completionHandler([.alert, .sound])
    }
}

