//
//  ModeButton.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/12/25.
//

import SwiftUI

struct ModeButton: View {
    @Environment(AppDataModel.self) var appModel

    var body: some View {
        Button(action: {
            switch appModel.captureMode {
            case .object:
                appModel.captureMode = .area
            case .area:
                appModel.captureMode = .object
            }
        }, label: {
            ZStack {
                VStack {
                    switch appModel.captureMode {
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
                .foregroundStyle(.white)
            }
            .padding(10)
            .contentShape(.rect)
        })
    }
}

#Preview {
    ModeButton()
        .environment(AppDataModel())
}
