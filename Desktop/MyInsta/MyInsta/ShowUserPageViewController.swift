//
//  ShowUserPageViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2021/01/08.
//

import UIKit
import NCMB
import SVProgressHUD

class ShowUserPageViewController: UIViewController, UICollectionViewDataSource {
    
    var posts = [Post]()
    
    var selectedUser: User!
    
    @IBOutlet var userImageView: UIImageView!
    
    @IBOutlet var userDisplayNameLabel: UILabel!
    
    @IBOutlet var userIntroductionTextView: UITextView!
    
    @IBOutlet var photoCollectionView: UICollectionView!
    
    @IBOutlet var photoCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollectionView.dataSource = self
        
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.layer.masksToBounds = true
        
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
        
        if let user = selectedUser {
            userDisplayNameLabel.text = user.displayName
            userIntroductionTextView.text = user.introduction
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
    
    func  loadPosts() {
        let user = NCMBUser(className: "user", objectId: selectedUser.objectId)
        let query = NCMBQuery(className: "Post")
        query?.order(byDescending: "createDate")
        query?.includeKey("user")
        query?.whereKey("user", equalTo: user)
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
    

}
