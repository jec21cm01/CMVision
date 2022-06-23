//
//  ContentView.swift
//  CMVision
//
//  Created by npc on 2022/06/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
