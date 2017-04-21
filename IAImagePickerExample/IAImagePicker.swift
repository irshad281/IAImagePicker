//
//  IAImagePicker.swift
//  IAImagePickerExample
//
//  Created by preeti rani on 21/04/17.
//  Copyright © 2017 Innotical. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
@objc protocol IAImagePickerDelegate {
    @objc optional func didfinishPickingMediaInfo(mediaInfo: [String : Any] , pickedImage:UIImage?)
}

class IAImagePicker: NSObject , UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var senderViewController:UIViewController?
    var imagePickerController:UIImagePickerController!
    var delegate:IAImagePickerDelegate?
    var allowEditing:Bool? = false
    static let sharedInstance = IAImagePicker.init()
    private override init() {
        super.init()
        imagePickerController = UIImagePickerController.init()
        imagePickerController.delegate = self
    }
    
    func presentIAImagePickerController(fromViewController:UIViewController) {
        self.senderViewController = fromViewController
        let pickerOptionSheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let cameraAction = UIAlertAction.init(title: "Use Camera", style: .default) { (handler) in
                self.checkAvailablityOfCamera()
            }
            pickerOptionSheet.addAction(cameraAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let libraryAction = UIAlertAction.init(title: "Use Library", style: .default) { (handler) in
                self.checkAvalabilityOfPhotoLibrary()
            }
            pickerOptionSheet.addAction(libraryAction)
        }
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (handler) in
            
        }
        pickerOptionSheet.addAction(cancelAction)
        DispatchQueue.main.async {
            fromViewController.present(pickerOptionSheet, animated: true, completion: nil)
        }
    }
    
    // MARK:- ImagePicket Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        var image:UIImage?
        if info["UIImagePickerControllerEditedImage"] != nil{
           image = info["UIImagePickerControllerEditedImage"] as? UIImage
        }else if info["UIImagePickerControllerOriginalImage"] != nil{
           image = info["UIImagePickerControllerOriginalImage"] as? UIImage
        }
        self.delegate?.didfinishPickingMediaInfo!(mediaInfo: info, pickedImage: image)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerController.dismiss(animated: true, completion: nil)
    }
    
    func openImagePicker(sourceType:UIImagePickerControllerSourceType){
        imagePickerController.allowsEditing = allowEditing!
        imagePickerController.sourceType = sourceType
        senderViewController?.present(imagePickerController, animated: true, completion: nil)
    }
    
    func handleRestrictionofPermission(sourceType:UIImagePickerControllerSourceType){
        var titleText:String?
        var messageText:String?
        if sourceType == .camera{
            titleText = "Camera Access Denied"
            messageText = "This App don't allow to access camera at this time.To enable access , tap Setting and turn on camera"
        }else{
            titleText = "Media Access Denied"
            messageText = "This App don't allow to access media at this time.To enable access , tap Setting and turn on Photos"
        }
        let alertController = UIAlertController.init(title: titleText, message: messageText, preferredStyle: .alert)
        let settingAction = UIAlertAction.init(title: "Setting", style: .destructive) { (handler) in
            DispatchQueue.main.async {
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }
        }
        alertController.addAction(settingAction)
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.senderViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func checkAvailablityOfCamera(){
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if status == .authorized{
            self.openImagePicker(sourceType: .camera)
        }else if status == .notDetermined{
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (success) in
                if success{
                    self.openImagePicker(sourceType: .camera)
                }
            })
        }else{
            self.handleRestrictionofPermission(sourceType: .camera)
        }
    }
    
    func checkAvalabilityOfPhotoLibrary(){
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized{
            self.openImagePicker(sourceType: .photoLibrary)
        }else if status == .notDetermined{
            PHPhotoLibrary.requestAuthorization({ (handlerStatus) in
                if handlerStatus == .authorized{
                    self.openImagePicker(sourceType: .photoLibrary)
                }
            })
        }else{
            self.handleRestrictionofPermission(sourceType: .photoLibrary)
        }
    }
}
