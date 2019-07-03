//
//  ViewController.swift
//  CropViewControllerExample
//
//  Created by Tim Oliver on 18/11/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CropViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let imageView = UIImageView()
    
    private var image: UIImage?
    private var croppingStyle = CropViewCroppingStyle.default
    private var customCropPath: UIBezierPath?
    
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        
        let cropController: CropViewController
        
        if let customCropPath = customCropPath {
            cropController = CropViewController(customCroppingPath: customCropPath, image: image)
        } else {
            cropController = CropViewController(croppingStyle: croppingStyle, image: image)
        }
        
        cropController.delegate = self
        
        // Uncomment this if you wish to provide extra instructions via a title label
        //cropController.title = "Crop Image"
    
        // -- Uncomment these if you want to test out restoring to a previous crop setting --
        //cropController.angle = 90 // The initial angle in which the image will be rotated
        //cropController.imageCropFrame = CGRect(x: 0, y: 0, width: 2848, height: 4288) //The initial frame that the crop controller will have visible.
    
        // -- Uncomment the following lines of code to test out the aspect ratio features --
        //cropController.aspectRatioPreset = .presetSquare; //Set the initial aspect ratio as a square
        //cropController.aspectRatioLockEnabled = true // The crop box is locked to the aspect ratio and can't be resized away from it
        //cropController.resetAspectRatioEnabled = false // When tapping 'reset', the aspect ratio will NOT be reset back to default
        //cropController.aspectRatioPickerButtonHidden = true
    
        // -- Uncomment this line of code to place the toolbar at the top of the view controller --
        //cropController.toolbarPosition = .top
    
        //cropController.rotateButtonsHidden = true
        //cropController.rotateClockwiseButtonHidden = true
    
        //cropController.doneButtonTitle = "Title"
        //cropController.cancelButtonTitle = "Title"
        
        self.image = image
        
        //If profile picture, push onto the same navigation stack
        if croppingStyle == .circular {
            if picker.sourceType == .camera {
                picker.dismiss(animated: true, completion: {
                    self.present(cropController, animated: true, completion: nil)
                })
            } else {
                picker.pushViewController(cropController, animated: true)
            }
        }
        else { //otherwise dismiss, and then present from the main controller
            picker.dismiss(animated: true, completion: {
                self.present(cropController, animated: true, completion: nil)
                //self.navigationController!.pushViewController(cropController, animated: true)
            })
        }
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        self.croppedAngle = angle
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        self.croppedAngle = angle
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        imageView.image = image
        layoutImageView()
        
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        
        if cropViewController.croppingStyle != .circular {
            imageView.isHidden = true
            
            cropViewController.dismissAnimatedFrom(self, withCroppedImage: image,
                                                   toView: imageView,
                                                   toFrame: CGRect.zero,
                                                   setup: { self.layoutImageView() },
                                                   completion: { self.imageView.isHidden = false })
        }
        else {
            self.imageView.isHidden = false
            cropViewController.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("CropViewController", comment: "")
        navigationController!.navigationBar.isTranslucent = false
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePhoto))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        view.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc public func addButtonTapped(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: "Crop Image", style: .default) { (action) in
            self.croppingStyle = .default
            self.customCropPath = nil
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        let profileAction = UIAlertAction(title: "Crop to California Path", style: .default) { (action) in
            self.croppingStyle = .circular
            
            
            // use a custom California-shaped crop path
            let californiaPath = try! NSKeyedUnarchiver(
                forReadingWith: Data(base64Encoded: "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVIkMIABpQsMHyMrVSRudWxs2g0ODxAREhMUFRYXGBgZGhsYHB0eViRjbGFzc18QHFVJQmV6aWVyUGF0aExpbmVKb2luU3R5bGVLZXlfECNVSUJlemllclBhdGhMaW5lRGFzaFBhdHRlcm5Db3VudEtleV8QGVVJQmV6aWVyUGF0aE1pdGVyTGltaXRLZXlfEBlVSUJlemllclBhdGhDR1BhdGhEYXRhS2V5XxAcVUlCZXppZXJQYXRoTGluZURhc2hQaGFzZUtleV8QG1VJQmV6aWVyUGF0aExpbmVDYXBTdHlsZUtleV8QGFVJQmV6aWVyUGF0aExpbmVXaWR0aEtleV8QF1VJQmV6aWVyUGF0aEZsYXRuZXNzS2V5XxAiVUlCZXppZXJQYXRoVXNlc0V2ZW5PZGRGaWxsUnVsZUtleYAEEAAiQSAAAIACIgAAAAAiP4AAACI/GZmaCNIgDSEiV05TLmRhdGFPEQioAAAAAAEAAAC8PydDBQS3QwEAAAABAAAAH/AIQ0jwtEMBAAAAAQAAAHca80LfyLNDAQAAAAEAAACTkPFCYWayQwEAAAABAAAAk5DxQiQrq0MBAAAAAQAAAD6k8ELvtKhDAQAAAAEAAAAFpOhCyXmlQwEAAAABAAAAzC3mQtO0o0MBAAAAAQAAAHYt2kKteaBDAQAAAAEAAADoQNFCD9ycQwEAAAABAAAA6PHIQqy0nEMBAAAAAQAAAAQZv0IeF5xDAQAAAAEAAACuLL5CLlKbQwEAAAABAAAAWcrCQgTcmkMBAAAAAQAAAK/xwELPZZhDAQAAAAEAAAAEVLxCPMiWQwEAAAABAAAAro6tQq4qlkMBAAAAAQAAAFmOoUIcjZRDAQAAAAEAAADKK55CJciSQwEAAAABAAAAkSuWQtUWj0MBAAAAAQAAAAM/jUJStIxDAQAAAAEAAAB0UoRCUrSMQwEAAAABAAAAPqRwQr8Wi0MBAAAAAQAAAD3yVEJBtIlDAQAAAAEAAADnGDtCyVGJQwEAAAABAAAAklMsQgw+h0MBAAAAAQAAAFlnL0Lcx4VDAQAAAAEAAABZezpCllGAQwEAAAABAAAAy2c/Qs22fUMBAAAAAQAAAMtnP0J9BXpDAQAAAAEAAADnjjVCnHt4QwEAAAABAAAAIHsyQlsFdEMBAAAAAQAAAMs/KUJFBXBDAQAAAAEAAADnUhRCxBhnQwEAAAABAAAArlIMQr1TYkMBAAAAAQAAAFgXA0KBGFtDAQAAAAEAAADofPJB8PBSQwEAAAABAAAAWRnLQd4rTEMBAAAAAQAAAMvxxEGdtUdDAQAAAAEAAACvys5BfLVBQwEAAAABAAAA6FTcQXy1QUMBAAAAAQAAAD4u9kFHPz9DAQAAAAEAAAA83AFCT7U5QwEAAAABAAAAWmn3QdWNNUMBAAAAAQAAAFot1kHkyDRDAQAAAAEAAAA9yr5BzsgwQwEAAAABAAAA5/CkQXMXK0MBAAAAAQAAAK56okGieR5DAQAAAAEAAABZ3alBQ40bQwEAAAABAAAABECxQVYDGEMBAAAAAQAAAJJnt0EHUhRDAQAAAAEAAAB2fGJBlaAKQwEAAAABAAAAdnxiQW9lB0MBAAAAAQAAACHfaUF+oAZDAQAAAAEAAADMQXFBFLQBQwEAAAABAAAA6EBRQR4Z90IBAAAAAQAAAMqhGEHfU+hCAQAAAAEAAACSU6xA83raQgEAAAABAAAAIGcnQLB6zkIBAAAAAQAAAAPwhED6F8NCAQAAAAEAAACueqJA+D6xQgEAAAABAAAAsBr7QOq0p0IBAAAAAQAAAAPwBEF5tJNCAQAAAAEAAAAht9NAiqCIQgEAAAABAAAAA/CEQOVnd0IBAAAAAQAAAAAAAAC2jl1CAQAAAAEAAAA8jp0/DN1JQgEAAAABAAAAdnxiQN0DMEIBAAAAAQAAAD3eyUBzFytCAQAAAAEAAACTo9hAYFIkQgEAAAABAAAArqI4QQdSFEIBAAAAAQAAACBTnEHJZZdBAQAAAAEAAABZyZ5BYkDxQAEAAAABAAAAupazQQAAAAABAAAAAQAAAND0o0JEPpFBAQAAAAEAAADuu/JCIXviQQEAAAABAAAAtR3aQqrvmEIBAAAAAQAAAKxvv0KEyv5CAQAAAAEAAABPTeZCwe8cQwEAAAABAAAABAU0Q3nKfEMBAAAAAQAAAIRUTkNfeZJDAQAAAAEAAAD2tk1D4tuUQwEAAAABAAAA2gVSQ/nbmEMBAAAAAQAAACG3U0NyA51DAQAAAAEAAAAEQVVD2yqeQwEAAAABAAAAvVRWQwWhnkMBAAAAAQAAAPYFVkO9tJ9DAQAAAAEAAACE3lNDrXmgQwEAAAABAAAAS6NOQ8i0oUMBAAAAAQAAAOi2S0NbUqNDAQAAAAEAAABLGUlDbFKmQwEAAAABAAAAWVRIQwrwqUMBAAAAAQAAAD1URENj3KtDAQAAAAEAAABLykBDBrWsQwEAAAABAAAA56JAQw16sUMBAAAAAQAAAJK2P0M88LJDAQAAAAEAAAB2QEFDCT+0QwEAAAABAAAAIN5FQx56tEMBAAAAAQAAAJJARUM4tbVDAQAAAAEAAAAgGUNDGj+3QwEAAAABAAAA9hg9Q0S1t0MBAAAAAQAAALw/J0MFBLdDBAAAAAAAAAAAAAAAAQAAAFotVkKnZZFDAQAAAAEAAACTLV5CEI2SQwEAAAABAAAAdvJcQhaNk0MBAAAAAQAAAK9ASUJkeZNDAQAAAAEAAABZj0VCEI2SQwEAAAABAAAABN5BQqdlkUMBAAAAAQAAAFotVkKnZZFDBAAAAAAAAAAAAAAAAQAAAOjeYUKnZZFDAQAAAAEAAACTQWlCfe+QQwEAAAABAAAAk2l/QhCNkkMBAAAAAQAAAOY+iUJkeZNDAQAAAAEAAADmeYZCju+TQwEAAAABAAAAzEFxQivIk0MBAAAAAQAAAOhoZ0IQjZJDAQAAAAEAAADo3mFCp2WRQwQAAAAAAAAAAAAAAAEAAAB1orBCEaGgQwEAAAABAAAAdSy2QgdmokMBAAAAAQAAAK6iuEL3KqNDAQAAAAEAAABZQL1CIaGjQwEAAAABAAAABBm/Qrl5okMBAAAAAQAAAD0FvEI7F6FDAQAAAAEAAAA9trNCWY2fQwEAAAABAAAArlOwQr20n0MBAAAAAQAAAK5TsEIRoaBDAQAAAAEAAAB1orBCEaGgQwQAAAAAAAAAAAAAAAEAAACSU6xCcVKnQwEAAAABAAAAkt2xQqfIqUMBAAAAAQAAAOeOtULWPqtDAQAAAAEAAAA88bBCOWarQwEAAAABAAAAIPGsQuV5qkMDAAAAAwAAACDxrELleapDrsmqQn1SqUOuyapCtgOpQwEAAAABAAAArsmqQnFSp0MBAAAAAQAAAJJTrEJxUqdDBAAAAAAAAACAA9IkJSYnWiRjbGFzc25hbWVYJGNsYXNzZXNdTlNNdXRhYmxlRGF0YaMoKSpdTlNNdXRhYmxlRGF0YVZOU0RhdGFYTlNPYmplY3TSJCUsLVxVSUJlemllclBhdGiiLipcVUlCZXppZXJQYXRoAAgAEQAaACQAKQAyADcASQBMAE8AUQBXAF0AcgB5AJgAvgDaAPYBFQEzAU4BaAGNAY8BkQGWAZgBnQGiAacBqAGtAbUKYQpjCmgKcwp8CooKjgqcCqMKrAqxCr4KwQAAAAAAAAIBAAAAAAAAAC8AAAAAAAAAAAAAAAAAAArO")!)
                .decodeTopLevelObject() as! UIBezierPath
            
            self.customCropPath = californiaPath
            
            let imagePicker = UIImagePickerController()
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
            imagePicker.preferredContentSize = CGSize(width: 320, height: 568)
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        alertController.addAction(defaultAction)
        alertController.addAction(profileAction)
        alertController.modalPresentationStyle = .popover
        
        let presentationController = alertController.popoverPresentationController
        presentationController?.barButtonItem = (sender as! UIBarButtonItem)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc public func didTapImageView() {
        // When tapping the image view, restore the image to the previous cropping state
        let cropViewController = CropViewController(croppingStyle: self.croppingStyle, image: self.image!)
        cropViewController.delegate = self
        let viewFrame = view.convert(imageView.frame, to: navigationController!.view)
        
        cropViewController.presentAnimatedFrom(self,
                                               fromImage: self.imageView.image,
                                               fromView: nil,
                                               fromFrame: viewFrame,
                                               angle: self.croppedAngle,
                                               toImageFrame: self.croppedRect,
                                               setup: { self.imageView.isHidden = true },
                                               completion: nil)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
    }
    
    public func layoutImageView() {
        guard imageView.image != nil else { return }
        
        let padding: CGFloat = 20.0
        
        var viewFrame = self.view.bounds
        viewFrame.size.width -= (padding * 2.0)
        viewFrame.size.height -= ((padding * 2.0))
        
        var imageFrame = CGRect.zero
        imageFrame.size = imageView.image!.size;
        
        if imageView.image!.size.width > viewFrame.size.width || imageView.image!.size.height > viewFrame.size.height {
            let scale = min(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height)
            imageFrame.size.width *= scale
            imageFrame.size.height *= scale
            imageFrame.origin.x = (self.view.bounds.size.width - imageFrame.size.width) * 0.5
            imageFrame.origin.y = (self.view.bounds.size.height - imageFrame.size.height) * 0.5
            imageView.frame = imageFrame
        }
        else {
            self.imageView.frame = imageFrame;
            self.imageView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        }
    }
    
    @objc public func sharePhoto() {
        guard let image = imageView.image else {
            return
        }
        
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem!
        present(activityController, animated: true, completion: nil)
    }
}

