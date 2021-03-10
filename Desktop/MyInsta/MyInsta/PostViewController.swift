//
//  PostViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/05.
//

import UIKit
import NYXImagesKit
import NCMB
import UITextView_Placeholder
import SVProgressHUD
import CropViewController

class PostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, CropViewControllerDelegate {
    
    let placeholderImage = UIImage(named: "photo-placeholder")
    
    var resizedImage: UIImage!
    
    @IBOutlet var postImageView: UIImageView!
    @IBOutlet var postTextView: UITextView!
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var selectCookingNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postImageView.image = placeholderImage
        
        postButton.isEnabled = false
        postTextView.placeholder = "キャプションを書く"
        postTextView.delegate = self
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        postImageView.image = image
        resizedImage = image.scale(byFactor: 0.3)
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickerImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        
       // resizedImage = selectedImage.scale(byFactor: 0.3)
        
       // postImageView.image = resizedImage
        
        let cropController = CropViewController(croppingStyle: .default, image: pickerImage)
        cropController.delegate = self
        cropController.customAspectRatio = postImageView.frame.size
        
        //今回は使わないボタン等を非表示にする。
        cropController.aspectRatioPickerButtonHidden = true
        cropController.resetAspectRatioEnabled = false
        cropController.rotateButtonsHidden = true
        
        //cropBoxのサイズを固定する。
        cropController.cropView.cropBoxResizeEnabled = false
        //pickerを閉じたら、cropControllerを表示する。
        picker.dismiss(animated: true) {
            self.present(cropController, animated: true, completion: nil)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        confirmContent()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
    
    @IBAction func selectImage() {
        let alertController = UIAlertController(title: "画像選択", message: "シェアする画像を選択して下さい。", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        let cameraAction = UIAlertAction(title: "カメラで撮影", style: .default) { (action) in
            // カメラ起動
            if UIImagePickerController.isSourceTypeAvailable(.camera) == true {
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            } else {
                print("この機種ではカメラが使用出来ません。")
            }
        }
        
        let photoLibraryAction = UIAlertAction(title: "フォトライブラリから選択", style: .default) { (action) in
            // アルバム起動
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == true {
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            } else {
                print("この機種ではフォトライブラリが使用出来ません。")
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(cameraAction)
        alertController.addAction(photoLibraryAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func selectCookingName() {
        let alertController = UIAlertController(title: "ジャンル選択", message: nil, preferredStyle: .actionSheet)
        let cafeAction = UIAlertAction(title: "カフェ・スイーツ", style: .default) { (action) in
            self.selectCookingNameLabel.text = "カフェ・スイーツ"
        }
        let wasyokuAction = UIAlertAction(title: "和食", style: .default) { (action) in
            self.selectCookingNameLabel.text = "和食"
        }
        let yousyokuAction = UIAlertAction(title: "洋食", style: .default) { (action) in
            self.selectCookingNameLabel.text = "洋食"
        }
        let menAction = UIAlertAction(title: "麺", style: .default) { (action) in
            self.selectCookingNameLabel.text = "麺"
        }
        let panAction = UIAlertAction(title: "パン", style: .default) { (action) in
            self.selectCookingNameLabel.text = "パン"
        }
        let nikuAction = UIAlertAction(title: "肉料理", style: .default) { (action) in
            self.selectCookingNameLabel.text = "肉料理"
        }
        let italianAction = UIAlertAction(title: "イタリアン", style: .default) { (action) in
            self.selectCookingNameLabel.text = "イタリアン"
        }
        let izakayaAction = UIAlertAction(title: "居酒屋", style: .default) { (action) in
            self.selectCookingNameLabel.text = "居酒屋"
        }
        let sonotaAction = UIAlertAction(title: "その他", style: .default) { (action) in
            self.selectCookingNameLabel.text = "その他"
        }
        
        alertController.addAction(cafeAction)
        alertController.addAction(wasyokuAction)
        alertController.addAction(yousyokuAction)
        alertController.addAction(menAction)
        alertController.addAction(panAction)
        alertController.addAction(nikuAction)
        alertController.addAction(italianAction)
        alertController.addAction(izakayaAction)
        alertController.addAction(sonotaAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sharePhoto() {
        SVProgressHUD.show()
        
        // 撮影した画像をデータ化したときに右に90度回転してしまう問題の解消
        UIGraphicsBeginImageContext(resizedImage.size)
        let rect = CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height)
        resizedImage.draw(in: rect)
        resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let data = UIImage.pngData(resizedImage)
        // ここを変更（ファイル名無いので）
        let file = NCMBFile.file(with: data()) as! NCMBFile
        file.saveInBackground({ (error) in
            if error != nil {
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "画像アップロードエラー", message: error!.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    
                })
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                // 画像アップロードが成功
                let postObject = NCMBObject(className: "Post")
                
                if (self.postTextView.text?.count)! == 0 {
                    print("入力されていません")
                    return
                }
                postObject?.setObject(self.postTextView.text!, forKey: "text")
                postObject?.setObject(NCMBUser.current(), forKey: "user")
                postObject?.setObject(self.selectCookingNameLabel.text!, forKey: "label")
                let url = "https://mbaas.api.nifcloud.com/2013-09-01/applications/XhJJg2bp2ITi07FK/publicFiles/" + file.name
                postObject?.setObject(url, forKey: "imageUrl")
                postObject?.saveInBackground({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error!.localizedDescription)
                    } else {
                        SVProgressHUD.dismiss()
                        self.postImageView.image = nil
                        self.postImageView.image = UIImage(named: "photo-placeholder")
                        self.postTextView.text = nil
                        self.selectCookingNameLabel.text = nil
                        self.tabBarController?.selectedIndex = 0
                    }
                })
            }
        }) { (progress) in
            print(progress)
        }
    }
    
    func confirmContent() {
        if (postTextView.text?.count)! > 0 && postImageView.image != placeholderImage && (selectCookingNameLabel.text?.count)! > 0 {
            postButton.isEnabled = true
        } else {
            postButton.isEnabled = false
        }
    }
    
    @IBAction func cancel() {
        if postTextView.isFirstResponder == true {
            postTextView.resignFirstResponder()
        }
        
        let alert = UIAlertController(title: "投稿内容の破棄", message: "入力中の投稿内容を破棄しますか？", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.selectCookingNameLabel.text = nil
            self.postTextView.text = nil
            self.postImageView.image = UIImage(named: "photo-placeholder")
            self.confirmContent()
        })
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}



