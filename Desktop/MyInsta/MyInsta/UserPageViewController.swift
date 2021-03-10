//
//  UserPageViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/01.
//

import UIKit
import NCMB
import Kingfisher
import SVProgressHUD

protocol UserPageViewControllerDelegate {
    func didTapPostButton()
}

class UserPageViewController: UIViewController, UICollectionViewDataSource {
    
    var delegate: UserPageViewControllerDelegate?
    
    var posts = [Post]()
    
    var selectedUser: User!
    
    @IBOutlet var userImageView: UIImageView!
    
    @IBOutlet var userDisplayNameLabel: UILabel!
    
    @IBOutlet var userIntroductionTextView: UITextView!
    
    @IBOutlet var photoCollectionView: UICollectionView!
    
    @IBOutlet var photoCountLabel: UILabel!
    
    @IBOutlet var followerCountLabel: UILabel!
    
    @IBOutlet var followingCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollectionView.dataSource = self
        
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.layer.masksToBounds = true
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = 0.0
            layout.minimumLineSpacing = 0.0
            layout.itemSize = CGSize(width: photoCollectionView.frame.width/3,
                         height: photoCollectionView.frame.width/3)
        photoCollectionView.collectionViewLayout = layout
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        loadPosts()
        
       // loadFollowingInfo()
        
        if let user = NCMBUser.current() {
            userDisplayNameLabel.text = user.object(forKey: "displayName") as? String
            userIntroductionTextView.text = user.object(forKey: "introduction") as? String
            self.navigationItem.title = user.userName
            
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
            //NCMBUser.currentがnilだったとき
            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.setValue(false, forKey: "isLogin")
            ud.synchronize()
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let photoImageView = cell.viewWithTag(1) as! UIImageView
        let photoImagePath = posts[indexPath.row].imageUrl
        photoImageView.kf.setImage(with: URL(string: photoImagePath))
        return cell
    }
    
    @IBAction func showMenu() {
        let alertController = UIAlertController(title: "メニュー", message: nil, preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "ログアウト", style: .default) { (action) in
            NCMBUser.logOutInBackground { (error) in
                if error != nil {
                    print(error)
                } else {
                    //ログアウト成功
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
        
        let deleteAction = UIAlertAction(title: "退会", style: .default) { (action) in
            
            let alert = UIAlertController(title: "会員登録の解除", message: "本当に退会しますか？退会した場合、再度このアカウントをご利用いただくことができません", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                if let user = NCMBUser.current() {
                    user.setObject(false, forKey: "active")
                    user.saveInBackground({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error!.localizedDescription)
                        } else {
                            //ログアウト成功
                            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
                            UIApplication.shared.keyWindow?.rootViewController = rootViewController
                            //ログイン状態の保持
                            let ud = UserDefaults.standard
                            ud.setValue(false, forKey: "isLogin")
                            ud.synchronize()
                        }
                    })
                } else {
                    // userがnilだった場合ログイン画面に移動
                    let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                    let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController
                    // ログイン状態の保持
                    let ud = UserDefaults.standard
                    ud.setValue(false, forKey: "isLogin")
                    ud.synchronize()
                    
                }
            })
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
                
            }
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
                alertController.dismiss(animated: true, completion: nil)
            }
            
            alertController.addAction(signOutAction)
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
    func  loadPosts() {
        let query = NCMBQuery(className: "Post")
        query?.order(byDescending: "createDate")
        query?.includeKey("user")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                self.posts = [Post]()
                
                for postObject in result as! [NCMBObject] {
                    // ユーザー情報をUserクラスにセット
                    let user = postObject.object(forKey: "user") as! NCMBUser
                    let userModel = User(objectId: user.objectId, userName: user.userName)
                    userModel.displayName = user.object(forKey: "displayName") as? String
                    
                    // 投稿の情報を取得
                    let imageUrl = postObject.object(forKey: "imageUrl") as! String
                    let text = postObject.object(forKey: "text") as! String
                    let label = postObject.object(forKey: "label") as! String
                    
                    // 2つのデータ(投稿情報と誰が投稿したか？)を合わせてPostクラスにセット
                    let post = Post(objectId: postObject.objectId, user: userModel, imageUrl: imageUrl, text: text, createDate: postObject.createDate, label: label)
                    
                    // likeの状況(自分が過去にLikeしているか？)によってデータを挿入
                  /*  let lileUser = postObject.object(forKey: "likeUser") as? [String]
                    if lileUser?.contains((NCMBUser.current()?.objectId)!) == true {
                        post.isLiked = true
                    } else {
                        post.isLiked = false
                    } */
                    
                    // 配列に加える
                    self.posts.append(post)
                }
                self.photoCollectionView.reloadData()
                
                // post数を表示
                self.photoCountLabel.text = String(self.posts.count)
                
                print(String(self.posts.count))
            }
        })
    }
    
   /* func loadFollowingInfo() {
        // フォロー中
        let followingQuery = NCMBQuery(className: "Follow")
        followingQuery?.includeKey("user")
        followingQuery?.whereKey("user", equalTo: NCMBUser.current())
        followingQuery?.countObjectsInBackground({ (count, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                // 非同期通信後のUIの更新はメインスレッドで
                DispatchQueue.main.async {
                    self.followingCountLabel.text = String(count)
                }
            }
        })
        
        // フォロワー
        let followerQuery = NCMBQuery(className: "Follow")
        followerQuery?.includeKey("following")
        followerQuery?.whereKey("following", equalTo: NCMBUser.current())
        followerQuery?.countObjectsInBackground({ (count, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    // 非同期通信後のUIの更新はメインスレッドで
                    self.followerCountLabel.text = String(count)
                }
            }
        })
    } */
        
        
        
    }
