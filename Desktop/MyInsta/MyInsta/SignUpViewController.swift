//
//  SignUpViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/11/30.
//

import UIKit
import NCMB

class SignUpViewController: UIViewController {
    
    @IBOutlet var mailTextField: UITextField!
    @IBOutlet var mailTextKakunin: UITextField!
    @IBOutlet var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.text = ""
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func signUp() {
        if mailTextField.text == mailTextKakunin.text {
            NCMBUser.requestAuthenticationMail(mailTextField.text, error: nil)
        } else {
            self.errorLabel.text = "メールアドレスが正しくありません"
            
        }
    }
    
    
    
}
