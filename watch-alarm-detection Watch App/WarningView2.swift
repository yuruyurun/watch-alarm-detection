//
//  WarningView2.swift
//  watchtest Watch App
//
//  Created by Kyosuke Yurugi on 2023/09/18.
//

import SwiftUI

struct WarningView2: View {
    @State var isShownSetteingsView = false
    
    var body: some View {
        VStack{
            Color.white
                .ignoresSafeArea()
            Text("⚠️")
                .font(.largeTitle)
            
            Text("防災警報")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(Color.red)
            Button("停止する"){
                isShownSetteingsView=true
            }
            
            .sheet(isPresented: $isShownSetteingsView){
                ContentView()
                //最終的にアプリを閉じる処理にする
            }
        }
        .background(Color.white)
        .ignoresSafeArea()
        
    }
}
#Preview {
    WarningView2()
}
