//
//  ViewController.swift
//  IAImagePickerExample
//
//  Created by preeti rani on 21/04/17.
//  Copyright © 2017 Innotical. All rights reserved.
//

import UIKit

class ViewControler:UIViewController , IAImagePickerDelegate1{
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        imageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handleTap(tap:))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func handleTap(tap:UITapGestureRecognizer) {
        let imagePicker = IAImagePickerViewController()
        imagePicker.delegate = self
        DispatchQueue.main.async {
          self.present(imagePicker, animated: false, completion: nil)
        }
    }
    
    func didFinishPickingMediaInfo(mediaInfo: [String : Any]?, pickedImage: UIImage?) {
        if let image = pickedImage{
            self.imageView.image = image
        }
    }
}



