//
//  CameraView.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/28/25.
//
import Foundation
import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    @State private var showPermissionAlert = false
    
    func makeUIViewController(context: Context) -> UIViewController {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Log which authorization status we have
        print("[CameraView] makeUIViewController called — current authorization status: \(status)")
        
        if status == .authorized {
            print("[CameraView] Status is .authorized, returning UIImagePickerController")
            return makeCameraController(context: context)
        } else {
            print("[CameraView] Status is \(status), returning CameraPermissionDeniedView")
            return UIHostingController(rootView: CameraPermissionDeniedView())
        }
    }
    
    private func makeCameraController(context: Context) -> UIImagePickerController {
        print("[CameraView] Creating and configuring UIImagePickerController")
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.allowsEditing = true // Allow editing for better user experience
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        print("[CameraView] updateUIViewController called — no specific updates")
    }
    
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
        print("[CameraView] makeCoordinator called")
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            print("[CameraView.Coordinator] init")
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("[CameraView.Coordinator] didFinishPickingMediaWithInfo called")
            if let picked = info[.editedImage] as? UIImage {
                print("[CameraView.Coordinator] Got .editedImage")
                parent.image = picked
            } else if let picked = info[.originalImage] as? UIImage {
                print("[CameraView.Coordinator] Got .originalImage")
                parent.image = picked
            } else {
                print("[CameraView.Coordinator] No valid image found in info dictionary")
            }
            
            print("[CameraView.Coordinator] Setting parent.isPresented = false")
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("[CameraView.Coordinator] imagePickerControllerDidCancel called")
            print("[CameraView.Coordinator] Setting parent.isPresented = false")
            parent.isPresented = false
        }
    }
}
