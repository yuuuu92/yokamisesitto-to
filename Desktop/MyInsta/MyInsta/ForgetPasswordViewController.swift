//
//  ForgetPasswordViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2021/01/06.
//

import UIKit
import NCMB

class ForgetPasswordViewController: UIViewController {
    
    @IBOutlet var mailTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func Send() {
        NCMBUser.requestPasswordResetForEmail(inBackground: mailTextField.text) { (error) in
            if error != nil {
                //会員登録用メールの要求に成功した場合の処理
                print("会員登録用のメールの要求に成功しました")
            } else {
                //会員登録用メールの要求に失敗した場合の処理
                print("会員登録用メールの要求に失敗しました: \(error)")
            }
        }
    }
    

}
