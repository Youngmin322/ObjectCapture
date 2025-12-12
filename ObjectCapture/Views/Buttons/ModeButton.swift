//
//  ModeButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/12/25.
//

import SwiftUI
import ComposableArchitecture

struct ModeButton: View {
    @Environment(Store<AppFeature.State, AppFeature.Action>.self) var store
    
    var body: some View {
        Button(action: {
            store.send(.toggleCaptureMode)
        }, label: {
            ZStack {
                VStack {
                    switch store.captureMode {
                    case .area:
                        Image(systemName: "circle.dashed")
                            .resizable()
                    case .object:
                        Image(systemName: "cube")
                            .resizable()
                    }
                }
                .aspectRatio(contentMode: .fit)
                .frame(width: 22)
                .foregroundColor(.white)
            }
            .padding(10)
            .contentShape(.rect)
        })
    }
}

#Preview {
    ModeButton()
        .environment(
            Store(initialState: AppFeature.State()) {
                AppFeature()
            }
        )
}
