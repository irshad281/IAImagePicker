# IAImagePicker

A very Simple Image Picker that handles All the permissions of user like denied , allowed , restricted

# HOW TO USE?
Download the project and add the IAImagePicker file to your Project.
let imagePicker = IAImagePicker.sharedInstance
imagePicker.allowEditing = false
imagePicker.delegate = self
imagePicker.presentIAImagePickerController(fromViewController: self)

# Delegate
IAImagePickerdelegate

when user select the image this function will be called mediaInfo contain image url ,  edited image and other information.
func didfinishPickingMediaInfo(mediaInfo: [String : Any], pickedImage: UIImage?) {
}
