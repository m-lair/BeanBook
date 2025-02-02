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
        picker.allowsEditing = true // Allow editing for better user experience
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
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CameraViewWrapper: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isCameraPresented: Bool = false

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    .padding()
                    .shadow(radius: 10)
            } else {
                Text("No image captured")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
            }

            Button(action: {
                isCameraPresented.toggle()
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Capture Image")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView(image: $capturedImage)
        }
        .navigationTitle("Camera")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
}

struct CameraViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        CameraViewWrapper()
    }
}
