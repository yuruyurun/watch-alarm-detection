//
//  WarningView1.swift
//  watchtest Watch App
//
//  Created by Kyosuke Yurugi on 2023/09/18.
//

import SwiftUI

struct WarningView1: View {
    @State var isShownSetteingsView = false
    
    var body: some View {
        
        Text("⚠️")
            .font(.largeTitle)
        
        Text("火災")
            .font(.largeTitle)
            .fontWeight(.black)
            .foregroundColor(Color.red)
        Button("停止する"){
            isShownSetteingsView=true
            //exit(0)//appを強制終了させる
        }
        .sheet(isPresented: $isShownSetteingsView){
            ContentView()
            //最終的にアプリを閉じる処理にする
        }
        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
        
    }
}
#Preview {
    WarningView1()
}
