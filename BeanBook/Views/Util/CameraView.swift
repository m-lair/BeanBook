//
//  CameraView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/28/25.
//
import Foundation
import SwiftUI
import AVFoundation

// Simplified Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var showPermissionAlert = false
    
    func makeUIViewController(context: Context) -> UIViewController {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .authorized {
            return makeCameraController(context: context)
        }
        
        return UIHostingController(rootView: CameraPermissionDeniedView())
    }
    
    private func makeCameraController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    private struct CameraPermissionDeniedView: View {
        var body: some View {
            VStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .padding(.bottom, 20)
                
                Text("Camera Access Required")
                    .font(.title)
                    .padding(.bottom, 10)
                
                Text("Please enable camera access in Settings to take photos of your coffee creations.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
