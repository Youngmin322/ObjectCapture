//
//  ARQuickLookView.swift
//  ObjectCapture
//
//  Created by Youngmin Cho on 12/4/25.
//

import SwiftUI
import QuickLook

struct ARQuickLookView: UIViewControllerRepresentable {
    var modelFile: URL
    var endCaptureCallback: () -> Void
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: ARQuickLookView
        
        init(parent: ARQuickLookView) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.modelFile as QLPreviewItem
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            parent.endCaptureCallback()
        }
    }
}
