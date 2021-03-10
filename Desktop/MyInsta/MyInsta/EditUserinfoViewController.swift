//
//  EditUserinfoViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/03.
//

import UIKit
import NCMB
import NYXImagesKit
import CropViewController

class EditUserinfoViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    var resizedImage: UIImage!
    
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var introductionTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.layer.masksToBounds = true
        
        userNameTextField.delegate = self
        userIdTextField.delegate = self
        introductionTextView.delegate = self
        
        if let user = NCMBUser.current() {
            userNameTextField.text = user.object(forKey: "displayName") as? String
            userIdTextField.text = user.userName
            introductionTextView.text = user.object(forKey: "introduction") as? String
            
            let file = NCMBFile.file(withName: user.objectId, data: nil) as! NCMBFile
            file.getDataInBackground { (data, error) in
                if error != nil {
                    print(error)
                } else {
                    if data != nil {
                        let image = UIImage(data: data!)
                        self.userImageView.image = image
                    }
                }
            }
        } else {
            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.setValue(false, forKey: "isLogin")
            ud.synchronize()
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickerImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        
        // let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        // let resizedImage = selectedImage.scale(byFactor: 0.4)
        
        let cropController = CropViewController(croppingStyle: .default, image: pickerImage)
        cropController.delegate = self
        cropController.customAspectRatio = userImageView.frame.size
        
        //今回は使わないボタン等を非表示にする。
        cropController.aspectRatioPickerButtonHidden = true
        cropController.resetAspectRatioEnabled = false
        cropController.rotateButtonsHidden = true
        
        //cropBoxのサイズを固定する。
        cropController.cropView.cropBoxResizeEnabled = false
        
        picker.dismiss(animated: true) {
            self.present(cropController, animated: true, completion: nil)
        }
        
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        userImageView.image = image
        resizedImage = image.scale(byFactor: 0.3)
        cropViewController.dismiss(animated: true, completion: nil)
        
        let data = UIImage.pngData(resizedImage!)
        let file = NCMBFile.file(withName: NCMBUser.current().objectId, data: data()) as! NCMBFile
        file.saveInBackground { (error) in
            if error != nil {
                print(error)
            } else {
                self.userImageView.image = self.resizedImage          }
        } progressBlock: { (progerss) in
            print(progerss)
        }
    }
    
    @IBAction func selectImage() {
        let actionController = UIAlertController(title: "画像の選択", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラで撮影", style: .default) { (action) in
            //カメラ起動
            if UIImagePickerController.isSourceTypeAvailable(.camera) == true {
                let picer = UIImagePickerController()
                picer.sourceType = .camera
                picer.delegate = self
                self.present(picer, animated: true, completion: nil)
            } else {
                print("この機種ではカメラが使用できません")
            }
        }
        let albamAction = UIAlertAction(title: "フォトライブラリから選択", style: .default) { (action) in
            //アルバム起動
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == true {
                let picer = UIImagePickerController()
                picer.sourceType = .photoLibrary
                picer.delegate = self
                self.present(picer, animated: true, completion: nil)
            } else {
                print("この機種ではフォトライブラリが使用できません")
            }
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            actionController.dismiss(animated: true, completion: nil)
        }
        actionController.addAction(cameraAction)
        actionController.addAction(albamAction)
        actionController.addAction(cancelAction)
        self.present(actionController, animated: true, completion: nil)
    }
    
    @IBAction func closeEditViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveUserInfo() {
        if let user = NCMBUser.current() {
            user.setObject(userNameTextField.text, forKey: "displayName")
            user.setObject(userIdTextField.text, forKey: "userName")
            user.setObject(introductionTextView.text, forKey: "introduction")
            user.saveInBackground({ (error) in
                if error != nil {
                    print(error)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        } else {
            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.setValue(false, forKey: "isLogin")
            ud.synchronize()
        }
        
    }
    
    
    
}
