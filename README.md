# IAImagePicker

A very Simple Image Picker that handles All the permissions of user like denied , allowed , restricted

# HOW TO USE?
Download the project and add the IAImagePickerViewController file to your Project

let imagePicker = IAImagePickerViewController.sharedInstance

imagePicker.delegate = self

imagePicker.presentIAImagePickerController(fromViewController: self)

# CameraView

![alt text](http://i.imgur.com/akHbNiV.png)

# Picked Image

![alt text](http://i.imgur.com/tydDw9B.png)


![alt text](http://i.imgur.com/46H9Xv0.png)

# Gallary

![alt text](http://i.imgur.com/wFxO5zb.png)

# when user dont allow access to camera or Photo Library

![alt text](http://i.imgur.com/kq20SQp.png)


# IAImagePickerdelegate

when user select the image this function will be called mediaInfo contain image url ,  edited image and other information


func didfinishPickingMediaInfo(mediaInfo: [String : Any], pickedImage: UIImage?) {
}
