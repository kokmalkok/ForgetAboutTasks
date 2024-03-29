//
//  MediaAccess.swift
//  ForgetAboutTasks
//
//  Created by Константин Малков on 14.07.2023.
//

import UIKit
import Photos

extension UIViewController {
    
    /// Func for get access to Users Media library
    /// - Parameter handler: rreturn boolean value of access to media
    func requestForUserLibrary(handler: @escaping (Bool?) -> ()){
        DispatchQueue.main.async {
            PHPhotoLibrary.requestAuthorization { success in
                switch success {
                case .notDetermined:
                    handler(false)
                case .restricted:
                    handler(false)
                case .denied:
                    handler(false)
                case .authorized:
                    handler(true)
                case .limited:
                    handler(true)
                @unknown default:
                    handler(false)
                }
            }
        }
    }
    
    
    /// Function for checking access to users media
    /// - Parameter handler: return boolean value of access to media
    func checkAccessForMedia(handler: @escaping (Bool) -> Void ) {
        let status = PHPhotoLibrary.authorizationStatus()
        DispatchQueue.main.async { [weak self] in
            switch status {
                
            case .notDetermined:
                self?.requestForUserLibrary(handler: { boolean in
                    handler(boolean ?? false)
                })
                
            case .restricted:
                self?.requestForUserLibrary(handler: { boolean in
                    handler(boolean ?? false)
                })
            case .denied:
                self?.requestForUserLibrary(handler: { boolean in
                    handler(boolean ?? false)
                })
            case .authorized:
                self?.requestForUserLibrary(handler: { boolean in
                    handler(boolean ?? true)
                })
            case .limited:
                self?.requestForUserLibrary(handler: { boolean in
                    handler(boolean ?? true)
                })
            @unknown default:
                handler(false)
            }
        }
    }

    
    /// function asked access to using camera
    func requestUserForCamera(){
        AVCaptureDevice.requestAccess(for: .video) { success in
            if !success {
                self.alertDismissed(view: self.view, title: "Successfully".localized())
            }
        }
    }
}
