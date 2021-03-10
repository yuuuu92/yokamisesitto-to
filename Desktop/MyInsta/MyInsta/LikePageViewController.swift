//
//  LikePageViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/15.
//

import UIKit
import NCMB
import Kingfisher
import SVProgressHUD

class LikePageViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet var photoCollectionView: UICollectionView!
    
    var posts = [Post]()
    
    var blockUserIdArray = [String]()
    
    var reportPostId = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getBlockUser()
        
        photoCollectionView.dataSource = self
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        loadPosts()
        
        if let user = NCMBUser.current() {
            
            let file = NCMBFile.file(withName: user.objectId, data: nil) as! NCMBFile
            file.getDataInBackground { (data, error) in
                if error != nil {
                    print(error)
                } else {
                    if data != nil {
                        let image = UIImage(data: data!)
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
    
    func getBlockUser() {
        
        let query = NCMBQuery(className: "Block")
        query?.includeKey("user")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: "エラーです")
            } else {
                //ブロックされた人のIDが入ってる removeall()は初期化→はデータの重複を防ぐ
                //NCMBのデータを持ってきて、配列に入れて、表示
                self.blockUserIdArray.removeAll()
                for blockObject in result as! [NCMBObject] {
                    self.blockUserIdArray.append(blockObject.object(forKey: "blockUserID") as! String)
                    
                }
                self.getReportId()
            }
        })
    }
    
    func getReportId() {
        
        let query = NCMBQuery(className: "Report")
        query?.includeKey("user")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: "エラーです")
            } else {
                //ブロックされた人のIDが入ってる removeall()は初期化→はデータの重複を防ぐ
                //NCMBのデータを持ってきて、配列に入れて、表示
                self.reportPostId.removeAll()
                for reportObject in result as! [NCMBObject] {
                    self.reportPostId.append(reportObject.object(forKey: "reportId") as! String)
                    
                }
                self.loadPosts()
            }
        })
    }
    
    func  loadPosts() {
        let query = NCMBQuery(className: "Post")
        query?.includeKey("user")
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
                    let likeUser = postObject.object(forKey: "likeUser") as? [String]
                    if likeUser?.contains((NCMBUser.current()?.objectId)!) == true {
                        post.isLiked = true
                        self.posts.append(post)
                    } else {
                        post.isLiked = false
                        
                    }
                }
                self.photoCollectionView.reloadData()
                
            }
        })
        
    }
    
}
