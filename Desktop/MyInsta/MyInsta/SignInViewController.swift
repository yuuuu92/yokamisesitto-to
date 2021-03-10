//
//  SignInViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/11/30.
//

import UIKit
import NCMB

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var mailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var inquiryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailTextField.delegate = self
        passwordTextField.delegate = self
        
        errorLabel.text = ""
        
        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func signIn() {
        
        if (mailTextField.text?.count)! > 0 && (passwordTextField.text?.count)! > 0 {
            NCMBUser.logInWithMailAddress(inBackground: mailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if error != nil {
                    self.errorLabel.text = "メールアドレスまたはパスワードが間違っています"
                } else {
                    //ログイン成功
                    let storyboad = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootTabBarController")
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController
                    //ログイン状態の保持
                    let ud = UserDefaults.standard
                    ud.setValue(true, forKey: "isLogin")
                    ud.synchronize()
                    
                }
                
            }
        }
    }
    
    @IBAction func inquire() {
        let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfUwvSdAkmop8u8RVxVerTODWeIffUeivzfk5k3llWLLzG67Q/viewform?usp=sf_link")
        UIApplication.shared.open(url!)
    }
    
    
}
/*
 @IBAction func forgetPassword()
 {
 
 }
 */
