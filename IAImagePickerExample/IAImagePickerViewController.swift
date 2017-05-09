//
//  IAImagePickerViewController.swift
//  IAImagePickerExample
//
//  Created by preeti rani on 26/04/17.
//  Copyright © 2017 Innotical. All rights reserved.
//

import UIKit
import Photos
import AVFoundation


let keyWindow = UIApplication.shared.keyWindow
let screen_width = UIScreen.main.bounds.width
let screen_height = UIScreen.main.bounds.height

@objc protocol IAImagePickerDelegate1{
    @objc optional func didFinishPickingMediaInfo(mediaInfo:[String:Any]? , pickedImage:UIImage?)
    @objc optional func didCancelIAPicker()
}
enum MediaType{
    case camera
    case library
}
class PhotoCell: UICollectionViewCell {
    
    let photoImageView:UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.isUserInteractionEnabled =  true
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(photoImageView)
        self.backgroundColor = .clear
        self.photoImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0).isActive = true
        self.photoImageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        self.photoImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        self.photoImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class IAImagePickerViewController: UIViewController , UICollectionViewDelegate , UICollectionViewDataSource , UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    let name = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    var captureSession: AVCaptureSession?;
    var previewLayer : AVCaptureVideoPreviewLayer?;
    var captureDevice : AVCaptureDevice?
    var stillImageOutput:AVCaptureStillImageOutput?
    
    var photosArray = [PhotoModel]()
    var orignalframe:CGRect?
    var delegate:IAImagePickerDelegate1?
    var capturedImageView:UIImageView?
    var restrictionView:UIView!
    var activity:UIActivityIndicatorView = UIActivityIndicatorView()
    lazy var cameraView:UIView = {
        let view = UIView.init(frame:CGRect.init(x: 0, y: 0, width: screen_width, height: screen_height))
        view.backgroundColor = .white
        return view
    }()
    
    lazy var photoCollectionView:UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.minimumLineSpacing = 5
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.scrollDirection = .horizontal
        let frame = CGRect.init(x: 0, y: screen_height - 200, width: screen_width, height: 100)
        let photoCollectionView = UICollectionView.init(frame: frame, collectionViewLayout: flowLayout)
        photoCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        photoCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "cellId")
        photoCollectionView.backgroundColor = .clear
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        return photoCollectionView
    }()
    
    lazy var crossButton:UIButton = {
        let crossButton = UIButton.init(frame:CGRect.init(x: 20, y: 20, width: 30, height: 30))
        crossButton.tintColor = .clear
        crossButton.addTarget(self, action: #selector(self.handleCancel(_:)), for: .touchUpInside)
        crossButton.setImage(#imageLiteral(resourceName: "multiply"), for: .normal)
        return crossButton
    }()
    
    lazy var flashButton:UIButton = {
        let flashButton = UIButton.init(frame:CGRect.init(x: screen_width - 50, y: 20, width: 30, height: 30))
        flashButton.setImage(#imageLiteral(resourceName: "flashON"), for: .normal)
        flashButton.setImage(#imageLiteral(resourceName: "flashOFF"), for: .selected)
        flashButton.tintColor = .clear
        flashButton.addTarget(self, action: #selector(self.handleFlash(_:)), for: .touchUpInside)
        return flashButton
    }()
    
    lazy var captureButton:UIButton = {
        let button = UIButton.init(frame: CGRect.init(x: 2, y: 2, width: 46, height: 46))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 23
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.handleCapture(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var useImageButton:UIButton = {
        let button = UIButton.init(frame: CGRect.init(x: screen_width - 120, y: screen_height - 50, width: 100, height: 30))
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.init(name: "Helvetica Neue", size: 15)
        button.setTitle("USE PHOTO", for: .normal)
        button.layer.cornerRadius  =  3
        button.layer.borderWidth = 1.0
        button.backgroundColor = .black
        button.layer.borderColor = UIColor.white.cgColor
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.handleUseImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var retakeButton:UIButton = {
        let button = UIButton.init(frame: CGRect.init(x: 20, y: screen_height - 50, width: 80, height: 30))
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.titleLabel?.font = UIFont.init(name: "Helvetica Neue", size: 15)
        button.setTitle("RETAKE", for: .normal)
        button.layer.cornerRadius  =  3
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.cgColor
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.handleRetakePhoto(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var captureView:UIView = {
        let captureView = UIView.init(frame: CGRect.init(x: screen_width/2 - 25, y: screen_height - 70, width: 60, height: 60))
        captureView.backgroundColor = .black
        captureView.layer.cornerRadius = 30
        captureView.clipsToBounds = true
        captureView.layer.borderWidth = 5
        captureView.layer.borderColor = UIColor.white.cgColor
        let button = UIButton.init(frame: CGRect.init(x: 7.5, y: 7.5, width: 45, height: 45))
        button.backgroundColor = .white
        button.layer.cornerRadius = 22.5
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.handleCapture(_:)), for: .touchUpInside)
        captureView.addSubview(button)
        return captureView
    }()
    
    lazy var albumButton:UIButton={
        let albumButton = UIButton.init(frame:CGRect.init(x: 15, y: screen_height - 55, width: 45, height: 30))
        albumButton.setImage(#imageLiteral(resourceName: "picture"), for: .normal)
        albumButton.addTarget(self, action: #selector(self.hanldleOpenAlbum(_:)), for: .touchUpInside)
        return albumButton
    }()
    
    func openSetting(_ sender:UIButton) {
        print("Open Setting...")
        let name = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        print(name)
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.flushSessionData()
        self.view.backgroundColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
        self.captureSession = AVCaptureSession();
        self.previewLayer = AVCaptureVideoPreviewLayer();
        self.captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput?.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        self.photoCollectionView.reloadData()
        _ = self.checkAutherizationStatusForCameraAndPhotoLibrary()
    }
    
    func addAfterPermission() {
        accessPhotosFromLibrary()
        let devices = AVCaptureDevice.devices()
        // Loop through all the capture devices on this phone
        for device in devices! {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if((device as AnyObject).position == AVCaptureDevicePosition.back) {
                    self.captureDevice = device as? AVCaptureDevice
                    if self.captureDevice != nil {
                        self.beginSession()
                    }
                }
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setUpViews(){
        DispatchQueue.main.async {
            self.cameraView.addSubview(self.crossButton)
            self.cameraView.addSubview(self.flashButton)
            self.cameraView.addSubview(self.albumButton)
            self.cameraView.addSubview(self.captureView)
            self.cameraView.addSubview(self.photoCollectionView)
        }
    }
    
    func checkAutherizationStatusForCameraAndPhotoLibrary()->Bool{
        var permissionStatus:Bool! = false
        let libraryPermission = PHPhotoLibrary.authorizationStatus()
        let cameraPermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if libraryPermission == .notDetermined || cameraPermission == .notDetermined{
            PHPhotoLibrary.requestAuthorization({ (handlerStatus) in
                if handlerStatus == .authorized{
                    if cameraPermission == .notDetermined{
                       self.checkPermissionForCamera()
                    }
                    permissionStatus = true
                }else{
                    self.checkPermissionForCamera()
                    permissionStatus = false
                }
            })
        }else{
            if libraryPermission == .authorized && cameraPermission == .authorized{
                DispatchQueue.main.async {
                    self.photoCollectionView.reloadData()
                    self.view.addSubview(self.cameraView)
                    self.addAfterPermission()
                }
            }else{
              self.showRestrictionView(mediaType: .library)
            }
        }
        return permissionStatus
    }
    
    func showRestrictionView(mediaType:MediaType){
        if restrictionView != nil{
            restrictionView.removeFromSuperview()
            restrictionView = nil
        }
        DispatchQueue.main.async {
            self.restrictionView = UIView.init(frame: UIScreen.main.bounds)
            self.restrictionView.backgroundColor = .white
            let imageView = UIImageView.init(frame: CGRect(x: screen_width/2 - 75, y: screen_height/2 - 145, width: 150, height: 150))
            if mediaType == .camera{
                imageView.image = #imageLiteral(resourceName: "camera3")
            }else{
                imageView.image = #imageLiteral(resourceName: "album")
            }
            self.restrictionView.addSubview(imageView)
            let permissionDescriptionLable = UILabel.init(frame: CGRect.init(x: 10, y: screen_height/2 + 25, width: screen_width - 20, height: 60))
            permissionDescriptionLable.numberOfLines = 0
            permissionDescriptionLable.textColor = #colorLiteral(red: 0.1019607843, green: 0.3098039216, blue: 0.5098039216, alpha: 1)
            permissionDescriptionLable.textAlignment = .center
            permissionDescriptionLable.font = UIFont.init(name: "Helvetica Neue", size: 13)
            permissionDescriptionLable.text = "Allow \(self.name) access to your camera to take photos within app.Go to Setting and turn on Photo and Camera"
            self.restrictionView.addSubview(permissionDescriptionLable)
            let openSettingButton = UIButton.init(frame: CGRect.init(x: screen_width/2 - 60, y: screen_height/2 + 105, width: 120, height: 30))
            openSettingButton.setTitle("Open Setting", for: .normal)
            openSettingButton.setTitleColor(#colorLiteral(red: 0.1019607843, green: 0.3098039216, blue: 0.5098039216, alpha: 1), for: .normal)
            openSettingButton.addTarget(self, action: #selector(self.openSetting(_:)), for: .touchUpInside)
            self.restrictionView.addSubview(openSettingButton)
            self.view.addSubview(self.restrictionView)
            self.view.bringSubview(toFront: self.restrictionView)
        }
    }
    
    func checkPermissionForCamera(){
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (success) in
            if success{
                if let window = keyWindow{
                    DispatchQueue.main.async {
                        self.photoCollectionView.reloadData()
                        window.addSubview(self.cameraView)
                        self.addAfterPermission()
                    }
                }
            }else{
                DispatchQueue.main.async {
                     self.showRestrictionView(mediaType: .library)
                }
            }
        })
    }
    
    
    func configureDevice(flashMode:AVCaptureFlashMode) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported{
                    device.focusMode = .continuousAutoFocus
                    device.flashMode = flashMode
                }
                device.unlockForConfiguration()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func beginSession() {
        if (captureSession?.canAddOutput(stillImageOutput))! {
            captureSession?.addOutput(stillImageOutput)
        }
        configureDevice(flashMode: .auto)
        do {
            captureSession?.startRunning()
            captureSession?.addInput(try AVCaptureDeviceInput(device: captureDevice))
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = cameraView.layer.frame
            
            self.cameraView.layer.addSublayer(self.previewLayer!)
            self.setUpViews()
        } catch{
            print(error.localizedDescription)
        }
    }
    
    func handleFlash(_ sender:UIButton){
        if sender.isSelected{
            self.configureDevice(flashMode: .auto)
        }else{
            self.configureDevice(flashMode: .off)
        }
        sender.isSelected = !sender.isSelected
    }
    
    func handleCancel(_ sender:UIButton){
        print("Handling dismiss.....")
        UIView.animate(withDuration: 0.5, animations: { 
           self.cameraView.frame = CGRect(x: 0, y: screen_height, width: screen_width, height: screen_height)
           self.dismiss(animated: true, completion: nil)
        }) { (completed) in
            self.cameraView.removeFromSuperview()
        }
    }
    
    func handleUseImage(_ sender:UIButton){
        print("Handling UseImage.....")
        if let capturedImage = self.zoomedImageView{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.cameraView.removeFromSuperview()
                capturedImage.frame = CGRect(x: 0, y: screen_height, width: screen_width, height: screen_height)
                self.delegate?.didFinishPickingMediaInfo!(mediaInfo: nil, pickedImage: self.zoomedImageView?.image)
                self.dismiss(animated: true, completion: nil)
                self.retakeButton.removeFromSuperview()
                self.useImageButton.removeFromSuperview()
            }, completion: { (completed) in
                self.zoomedImageView?.removeFromSuperview()
                self.zoomedImageView = nil
            })
        }
        
        if let capturedPhoto = self.capturedImageView{
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: { 
                self.cameraView.removeFromSuperview()
                capturedPhoto.frame = CGRect(x: 0, y: screen_height, width: screen_width, height: screen_height)
                self.delegate?.didFinishPickingMediaInfo!(mediaInfo: nil, pickedImage: capturedPhoto.image)
                self.dismiss(animated: true, completion: nil)
                self.retakeButton.removeFromSuperview()
                self.useImageButton.removeFromSuperview()
            }, completion: { (completed) in
                self.zoomedImageView?.removeFromSuperview()
                self.zoomedImageView = nil
            })
        }
    }
    
    func handleRetakePhoto(_ sender:UIButton){
        print("Handling Retake.....")
        if let capturedImage = self.capturedImageView{
            UIView.animate(withDuration: 0.33, animations: {
                capturedImage.frame = CGRect(x: 0, y: screen_height, width: screen_width, height: screen_height)
                self.retakeButton.removeFromSuperview()
                self.useImageButton.removeFromSuperview()
            }, completion: { (completed) in
                self.capturedImageView?.removeFromSuperview()
                self.capturedImageView = nil
            })
        }
        if let capturedPhoto = self.zoomedImageView{
            UIView.animate(withDuration: 0.33, animations: {
                capturedPhoto.frame = self.orignalframe!
                self.retakeButton.removeFromSuperview()
                self.useImageButton.removeFromSuperview()
            }, completion: { (completed) in
                self.orignalImageView?.isHidden = false
                self.zoomedImageView?.removeFromSuperview()
                self.zoomedImageView = nil
            })
        }
    }
    
    func flushSessionData(){
        captureSession = nil
        captureDevice = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        stillImageOutput = nil
    }
    
    
    func handleCapture(_ sender:UIButton){
        print("Handling capture.....")
        UIView.animate(withDuration: 0.33, animations: { 
           self.captureView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (completed) in
           self.captureView.transform = .identity
            if let videoConnection = self.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) {
                self.stillImageOutput?.captureStillImageAsynchronously(from: videoConnection) {
                    (imageDataSampleBuffer, error) -> Void in
                    if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer){
                        let image = UIImage.init(data: imageData)
                        self.capturedImageView = UIImageView.init(frame: UIScreen.main.bounds)
                        self.capturedImageView?.image = image
                        keyWindow?.addSubview(self.capturedImageView!)
                        keyWindow?.addSubview(self.useImageButton)
                        keyWindow?.addSubview(self.retakeButton)
                        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, nil, nil, nil)
                    }
                }
            }
        }
    }
    
    func hanldleOpenAlbum(_ sender:UIButton){
        print("Handling OpenAlbum.....")
        let imagePickerController = UIImagePickerController.init()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        UIView.animate(withDuration: 0.50, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: .curveEaseOut, animations: {
          self.cameraView.frame = CGRect(x: 0, y: screen_height, width: screen_width, height: screen_height)
          self.present(imagePickerController, animated: false, completion: nil)
        }, completion: { (completed) in
            self.cameraView.removeFromSuperview()
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image:UIImage?
        if info["UIImagePickerControllerEditedImage"] != nil{
            image = info["UIImagePickerControllerEditedImage"] as? UIImage
        }else if info["UIImagePickerControllerOriginalImage"] != nil{
            image = info["UIImagePickerControllerOriginalImage"] as? UIImage
        }
        self.delegate?.didFinishPickingMediaInfo!(mediaInfo: info, pickedImage: image)
        picker.dismiss(animated: false, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func accessPhotosFromLibrary(){
        let fetchOption = PHFetchOptions.init()
        fetchOption.fetchLimit = 100
        fetchOption.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOption)
        assets.enumerateObjects(options: .concurrent) { (assest, id, bool) in
            self.photosArray.append(PhotoModel.getAssestsModel(assest: assest))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! PhotoCell
        cell.photoImageView.image = self.photosArray[indexPath.item].photoImage
        cell.photoImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handleTap(tap:))))
        return cell
    }
    
    var orignalImageView:UIImageView?
    var selectedAssest:PhotoModel?
    var zoomedImageView:UIImageView?
    func handleTap(tap:UITapGestureRecognizer){
        if let indexPath = getIndexFromCollectionViewCell(tap.view!, collView: photoCollectionView){
            print(indexPath.item)
            selectedAssest = photosArray[indexPath.item]
            orignalImageView = tap.view as? UIImageView
            orignalImageView?.isHidden = true
            orignalframe = orignalImageView?.convert((orignalImageView?.frame)!, to: nil)
            if zoomedImageView != nil{
                zoomedImageView?.removeFromSuperview()
                zoomedImageView = nil
            }
            zoomedImageView = UIImageView.init(frame: orignalframe!)
            zoomedImageView?.contentMode = .scaleAspectFill
            zoomedImageView?.clipsToBounds = true
            zoomedImageView?.isUserInteractionEnabled = true
            zoomedImageView?.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(pan:))))
            zoomedImageView?.image = getAssetThumbnail(asset: (selectedAssest?.assest!)!, size: PHImageManagerMaximumSize)
            keyWindow?.addSubview(zoomedImageView!)
            UIView.animate(withDuration: 0.5, animations: {
              self.zoomedImageView?.frame = self.view.frame
            }, completion: { (completed) in
                keyWindow?.addSubview(self.useImageButton)
                keyWindow?.addSubview(self.retakeButton)
            })
        }
        
    }
    
    func handlePan(pan:UIPanGestureRecognizer){
        if pan.state == .began || pan.state == .changed {
            let translation = pan.translation(in: self.view)
            let piont = CGPoint(x: pan.view!.center.x + translation.x, y: pan.view!.center.y + translation.y)
            print("POINT",piont)
            pan.view!.center = piont
            pan.setTranslation(CGPoint.zero, in: self.view)
            self.retakeButton.alpha = 0
            self.useImageButton.alpha = 0
        }else if pan.state == .ended{
            if let yPosition = pan.view?.center.y{
                print("Y Position ",yPosition)
                let maxDownpoint = self.view.frame.height -  self.view.frame.height/4
                print("MAX DOWN POINT",maxDownpoint)
                if yPosition >= maxDownpoint{
                    dismissZoomedImageView()
                }else{
                    UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.3, options: .curveLinear, animations: {
                        self.zoomedImageView?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
                        self.retakeButton.alpha = 1
                        self.useImageButton.alpha = 1
                    }, completion: { (success) in
                        
                    })
                }
            }
        }
    }
    
    func dismissZoomedImageView(){
        UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveLinear, animations: {
            self.zoomedImageView?.frame = self.orignalframe!
            self.useImageButton.removeFromSuperview()
            self.retakeButton.removeFromSuperview()
        }, completion: { (success) in
            self.zoomedImageView?.removeFromSuperview()
            self.zoomedImageView = nil
            self.orignalImageView?.isHidden = false
            self.useImageButton.alpha = 1
            self.retakeButton.alpha = 1
        })
    }
}

func getAssetThumbnail(asset: PHAsset , size:CGSize) -> UIImage {
    let manager = PHImageManager.default()
    let option = PHImageRequestOptions()
    var thumbnail = UIImage()
    option.isSynchronous = true
    option.resizeMode = .exact
    option.deliveryMode = .fastFormat
    manager.requestImage(for: asset, targetSize: size, contentMode: .default, options: option, resultHandler: {(result, info)->Void in
        thumbnail = result!
    })
    return thumbnail
}

func getIndexFromCollectionViewCell(_ cellItem: UIView, collView: UICollectionView) -> IndexPath? {
    let pointInTable: CGPoint = cellItem.convert(cellItem.bounds.origin, to: collView)
    if let cellIndexPath = collView.indexPathForItem(at: pointInTable){
        return cellIndexPath
    }
    return nil
}

class PhotoModel: NSObject {
    var photoImage:UIImage?
    var assest:PHAsset?
    
    static func getAssestsModel(assest:PHAsset)->PhotoModel{
        let photoModel  = PhotoModel.init()
        photoModel.assest = assest
        photoModel.photoImage = getAssetThumbnail(asset: assest, size: CGSize(width: 250, height: 250))
        return photoModel
    }
}

