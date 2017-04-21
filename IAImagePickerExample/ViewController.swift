//
//  ViewController.swift
//  IAImagePickerExample
//
//  Created by preeti rani on 21/04/17.
//  Copyright © 2017 Innotical. All rights reserved.
//

import UIKit

class ViewController: UIViewController , IAImagePickerDelegate{

    @IBOutlet weak var profileImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.profileImage.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handleTap(tap:))))
    }

    func handleTap(tap:UITapGestureRecognizer)  {
        let imagePicker = IAImagePicker.sharedInstance
        imagePicker.allowEditing = false
        imagePicker.delegate = self
        imagePicker.presentIAImagePickerController(fromViewController: self)
    }
    func didfinishPickingMediaInfo(mediaInfo: [String : Any], pickedImage: UIImage?) {
        profileImage.image = pickedImage
    }
    
}

