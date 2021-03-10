//
//  ViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/11/24.
//

import UIKit
import NCMB
import Kingfisher
import SVProgressHUD
import SwiftDate

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimelineTableViewCellDelegate {
    
    
    var selectedPost: Post?
    
    var posts = [Post]()
    
    var blockUserIdArray = [String]()
    
    var reportPostId = [String]()
    
    var followings = [NCMBUser]()
    
    @IBOutlet var timelineTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timelineTableView.dataSource = self
        timelineTableView.delegate = self
        
        let nib = UINib(nibName: "TimelineTableViewCell", bundle: Bundle.main)
        timelineTableView.register(nib, forCellReuseIdentifier: "Cell")
        
        timelineTableView.tableFooterView = UIView()
        
        // 引っ張って更新
        setRefreshControl()
        
        // フォロー中のユーザーを取得する。その後にフォロー中のユーザーの投稿のみ読み込み
        loadFollowingUsers()
        
        getBlockUser()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toComments" {
            let commentViewController = segue.destination as! CommentViewController
            commentViewController.postId = selectedPost?.objectId
        } else if segue.identifier == "toUserPage" {
            let showUserPageVC = segue.destination as! ShowUserPageViewController
            showUserPageVC.selectedUser = selectedPost?.user
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TimelineTableViewCell
        
        cell.delegate = self
        cell.tag = indexPath.row
        
        let user = posts[indexPath.row].user
        cell.userNameLabel.text = user.displayName
        let file = NCMBFile.file(withName: user.objectId, data: nil) as! NCMBFile
        file.getDataInBackground { (data, error) in
            if error != nil {
                print(error)
            } else {
                if data != nil {
                    let image = UIImage(data: data!)
                    cell.userImageView.image = image
                }
            }
        }
        
        cell.commentTextView.text = posts[indexPath.row].text
        let imageUrl = posts[indexPath.row].imageUrl
        cell.photoImageView.kf.setImage(with: URL(string: imageUrl))
        
        // Likeによってハートの表示を変える
        if posts[indexPath.row].isLiked == true {
            cell.likeButton.setImage(UIImage(named: "icons8-ハート-ピンク.png"), for: .normal)
        } else {
            cell.likeButton.setImage(UIImage(named: "icons8-ハート-24.png"), for: .normal)
        }
        
        // Likeの数
        cell.likeCountLabel.text = "\(posts[indexPath.row].likeCount)件"
        
        cell.cookingNameLabel.text = posts[indexPath.row].label
        
        // タイムスタンプ(投稿日時)
        let createDate = posts[indexPath.row].createDate
        let timeStampText = makeTimeIntervalText(createDate: createDate)
        cell.timestampLabel.text = timeStampText
        
        return cell
    }
    
    func makeTimeIntervalText(createDate: Date) -> String{
        let now = Date()
        let timeInterval = now - createDate
        
        if(timeInterval.era! !=  0 || timeInterval.year != 0){
            return createDate.toFormat("yyyy年MM月dd日")
        }else if(timeInterval.month != 0){
            return createDate.toFormat("MMヶ月前")
        }else if(timeInterval.day != 0){
            return createDate.toFormat("dd日前")
        }else if(timeInterval.hour != 0){
            return createDate.toFormat("HH時間前")
        }else if(timeInterval.minute != 0){
            return createDate.toFormat("mm分前")
        }else{
            return "ついさっき"
        }
    }
    
    func didTapLikeButton(tableViewCell: UITableViewCell, button: UIButton) {
        
        guard let currentUser = NCMBUser.current() else {
            //ログインに戻る
            //ログアウト成功
            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.setValue(false, forKey: "isLogin")
            ud.synchronize()
            return
        }
        
        if posts[tableViewCell.tag].isLiked == false || posts[tableViewCell.tag].isLiked == nil {
            let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: posts[tableViewCell.tag].objectId, block: { (post, error) in
                post?.addUniqueObject(currentUser.objectId, forKey: "likeUser")
                post?.saveEventually({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error!.localizedDescription)
                    } else {
                        self.loadTimeline()
                    }
                })
            })
        } else {
            let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: posts[tableViewCell.tag].objectId, block: { (post, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    post?.removeObjects(in: [NCMBUser.current().objectId], forKey: "likeUser")
                    post?.saveEventually({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error!.localizedDescription)
                        } else {
                            self.loadTimeline()
                        }
                    })
                }
            })
        }
    }
    
    func didTapMenuButton(tableViewCell: UITableViewCell, button: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "削除する", style: .destructive) { (action) in
            SVProgressHUD.show()
            let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: self.posts[tableViewCell.tag].objectId, block: { (post, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    // 取得した投稿オブジェクトを削除
                    post?.deleteInBackground({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error!.localizedDescription)
                        } else {
                            // 再読込
                            self.loadTimeline()
                            SVProgressHUD.dismiss()
                        }
                    })
                }
            })
        }
        let reportAction = UIAlertAction(title: "報告する", style: .destructive) { (action) in
            SVProgressHUD.showSuccess(withStatus: "この投稿を報告しました。ご協力ありがとうございました。")
            let object = NCMBObject(className: "Report")
            object?.setObject(self.posts[tableViewCell.tag].objectId, forKey: "reportId")
            object?.setObject(NCMBUser.current(), forKey: "user")
            object?.saveInBackground({ (error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: "エラーです")
                } else {
                    SVProgressHUD.dismiss(withDelay: 2)
                    
                    self.getBlockUser()
                }
            })
        }
        let blockAction = UIAlertAction(title: "ブロックする", style: .destructive) { (action) in
            SVProgressHUD.showSuccess(withStatus: "このユーザーをブロックしました。")
            let object = NCMBObject(className: "Block")
            object?.setObject(self.posts[tableViewCell.tag].user.objectId, forKey: "blockUserID")
            object?.setObject(NCMBUser.current(), forKey: "user")
            object?.saveInBackground({ (error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: "エラーです")
                } else {
                    SVProgressHUD.dismiss(withDelay: 2)
                    
                    self.getBlockUser()
                }
            })
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        if posts[tableViewCell.tag].user.objectId == NCMBUser.current().objectId {
            // 自分の投稿なので、削除ボタンを出す
            alertController.addAction(deleteAction)
        } else {
            // 他人の投稿なので、報告ボタンを出す
            alertController.addAction(reportAction)
            alertController.addAction(blockAction)
        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func didTapCommentsButton(tableViewCell: UITableViewCell, button: UIButton) {
        // 選ばれた投稿を一時的に格納
        selectedPost = posts[tableViewCell.tag]
        
        // 遷移させる(このとき、prepareForSegue関数で値を渡す)
        self.performSegue(withIdentifier: "toComments", sender: nil)
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
                self.loadFollowingUsers()
            }
        })
    }
    
    func didTapUserPageButton(tableViewCell: UITableViewCell) {
        selectedPost = posts[tableViewCell.tag]
        self.performSegue(withIdentifier: "toUserPage", sender: nil)
    }
    
    
    
    func loadTimeline() {
        guard let currentUser = NCMBUser.current() else {
            //ログインに戻る
            //ログアウト成功
            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.setValue(false, forKey: "isLogin")
            ud.synchronize()
            return
        }
        
        let query = NCMBQuery(className: "Post")
        
        for Id in reportPostId {
            query?.whereKey("objectId", notEqualTo: Id)
        }
        
        // 降順
        query?.order(byDescending: "createDate")
        
        // 投稿したユーザーの情報も同時取得
        query?.includeKey("user")
        
        // オブジェクトの取得
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                //投稿を格納しておく配列を初期化(これをしないとreload時にappendで二重に追加されてしまう)
                self.posts = [Post]()
                
                for postObject in result as! [NCMBObject] {
                    if let post = Post.create(postObject, blockUserIdArray: self.blockUserIdArray) {
                        // 配列に加える
                        self.posts.append(post)
                    }
                    
                }
                
                // 投稿のデータが揃ったらTableViewをリロード
                self.timelineTableView.reloadData()
            }
        })
    }
    
    func setRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadTimeline(refreshControl:)), for: .valueChanged)
        timelineTableView.addSubview(refreshControl)
    }
    
    @objc func reloadTimeline(refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        self.getBlockUser()
       // self.loadFollowingUsers()
        // 更新が早すぎるので2秒遅延させる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshControl.endRefreshing()
        }
    }
    
    /* @objc func reloadTimeline(refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        self.loadFollowingUsers()
        // 更新が早すぎるので2秒遅延させる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshControl.endRefreshing()
        }
    } */
    
    func loadFollowingUsers() {
        // フォロー中の人だけ持ってくる
        let query = NCMBQuery(className: "Follow")
        query?.includeKey("user")
        query?.includeKey("following")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                self.followings = [NCMBUser]()
                for following in result as! [NCMBObject] {
                    self.followings.append(following.object(forKey: "following") as! NCMBUser)
                }
                self.followings.append(NCMBUser.current())
                
                self.loadTimeline()
            }
        })
    }
    @IBAction func showSelecctButton() {
        let alertController = UIAlertController(title: "ジャンル選択", message: nil, preferredStyle: .actionSheet)
        guard let currentUser = NCMBUser.current() else {
            //ログインに戻る
            //ログアウト成功
            let storyboad = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboad.instantiateViewController(withIdentifier: "RootNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = rootViewController
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.setValue(false, forKey: "isLogin")
            ud.synchronize()
            return
        }
        let query = NCMBQuery(className: "Post")
        let allAction = UIAlertAction(title: "全て", style: .default) { (action) in
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        // テーブルをリロード
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let cafeAction = UIAlertAction(title: "カフェ・スイーツ", style: .default) { (action) in
            query?.whereKey("label", equalTo: "カフェ・スイーツ")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
            
        }
        let wasyokuAction = UIAlertAction(title: "和食", style: .default) { (action) in
            query?.whereKey("label", equalTo: "和食")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let yousyokuAction = UIAlertAction(title: "洋食", style: .default) { (action) in
            query?.whereKey("label", equalTo: "洋食")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let menAction = UIAlertAction(title: "麺", style: .default) { (action) in
            query?.whereKey("label", equalTo: "麺")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let panAction = UIAlertAction(title: "パン", style: .default) { (action) in
            query?.whereKey("label", equalTo: "パン")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let nikuAction = UIAlertAction(title: "肉料理", style: .default) { (action) in
            query?.whereKey("label", equalTo: "肉料理")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let italianAction = UIAlertAction(title: "イタリアン", style: .default) { (action) in
            query?.whereKey("label", equalTo: "イタリアン")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let izakayaAction = UIAlertAction(title: "居酒屋", style: .default) { (action) in
            query?.whereKey("label", equalTo: "居酒屋")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let sonotaAction = UIAlertAction(title: "その他", style: .default) { (action) in
            query?.whereKey("label", equalTo: "その他")
            query?.order(byDescending: "createDate")
            query?.includeKey("user")
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        if let post = Post.create(postObject) {
                            // 配列に加える
                            self.posts.append(post)
                        }
                        
                        self.timelineTableView.reloadData()
                    }
                    
                }
            })
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(allAction)
        alertController.addAction(cafeAction)
        alertController.addAction(wasyokuAction)
        alertController.addAction(yousyokuAction)
        alertController.addAction(menAction)
        alertController.addAction(panAction)
        alertController.addAction(nikuAction)
        alertController.addAction(italianAction)
        alertController.addAction(izakayaAction)
        alertController.addAction(sonotaAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
}
