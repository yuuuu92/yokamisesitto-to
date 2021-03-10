//
//  CommentViewController.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/07.
//

import UIKit
import NCMB
import SVProgressHUD
import Kingfisher
import SwiftDate

class CommentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CommentTableViewCellDelegate {
    
    var postId: String!
    
    var selectedComment: Comment?
    
    var comments = [Comment]()
    
    var blockUserIdArray = [String]()
    
    @IBOutlet var commentTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.dataSource = self
        commentTableView.delegate = self
        
        commentTableView.tableFooterView = UIView()
        
        commentTableView.rowHeight = 70
        
        setRefreshControl()
        
        getBlockUser()
        
        // カスタムセルの登録
        let nib = UINib(nibName: "CommentTableViewCell", bundle: Bundle.main)
        commentTableView.register(nib, forCellReuseIdentifier: "Cell")
        
        commentTableView.allowsSelection = false
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserPage" {
            let showUserPageVC = segue.destination as! ShowUserPageViewController
            showUserPageVC.selectedUser = selectedComment?.user
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! CommentTableViewCell
        
        cell.delegate = self
        cell.tag = indexPath.row
        
        // ユーザー画像を丸く
        cell.userImageView.layer.cornerRadius = cell.userImageView.bounds.width / 2.0
        cell.userImageView.layer.masksToBounds = true
        
        let user = comments[indexPath.row].user
        
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
        cell.userNameLabel.text = user.displayName
        cell.commentLabel.text = comments[indexPath.row].text
        
        let createDate = comments[indexPath.row].createDate
        let timeStampText = makeTimeIntervalText(createDate: createDate)
        cell.commentTimeLabel.text = timeStampText
        
        return cell
    }
    
    func didTapMenuButton(tableViewCell: UITableViewCell, button: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "削除する", style: .destructive) { (action) in
            SVProgressHUD.show()
            let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: self.comments[tableViewCell.tag].postId, block: { (post, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    // 取得した投稿オブジェクトを削除
                    post?.deleteInBackground({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error!.localizedDescription)
                        } else {
                            // 再読込
                            self.loadComments()
                            SVProgressHUD.dismiss()
                        }
                    })
                }
            })
        }
        let reportAction = UIAlertAction(title: "報告する", style: .destructive) { (action) in
            SVProgressHUD.showSuccess(withStatus: "この投稿を報告しました。ご協力ありがとうございました。")
            let object = NCMBObject(className: "Report")
            object?.setObject(self.comments[tableViewCell.tag].postId, forKey: "reportId")
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
            object?.setObject(self.comments[tableViewCell.tag].user.objectId, forKey: "blockUserID")
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
        if comments[tableViewCell.tag].user.objectId == NCMBUser.current().objectId {
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
                self.loadComments()
            }
        })
    }
    
    func didTapUserPageButton(tableViewCell: UITableViewCell) {
        selectedComment = comments[tableViewCell.tag]
        self.performSegue(withIdentifier: "toUserPage", sender: nil)
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
    
    func loadComments() {
        comments = [Comment]()
        let query = NCMBQuery(className: "Comment")
        query?.whereKey("postId", equalTo: postId)
        query?.includeKey("user")
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                for commentObject in result as! [NCMBObject] {
                    // コメントをしたユーザーの情報を取得
                    let user = commentObject.object(forKey: "user") as! NCMBUser
                    let userModel = User(objectId: user.objectId, userName: user.userName)
                    userModel.displayName = user.object(forKey: "displayName") as? String
                    
                    // コメントの文字を取得
                    let text = commentObject.object(forKey: "text") as! String
                    
                    // Commentクラスに格納
                    let comment = Comment(postId: self.postId, user: userModel, text: text, createDate: commentObject.createDate)
                    if self.blockUserIdArray.firstIndex(of: comment.user.objectId) == nil{
                              self.comments.append(comment)
                              }
                    
                    // テーブルをリロード
                    self.commentTableView.reloadData()
                }
                
            }
        })
    }
    
    func setRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadComments(refreshControl:)), for: .valueChanged)
        commentTableView.addSubview(refreshControl)
    }
    
    @objc func reloadComments(refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        self.getBlockUser()
       // self.loadFollowingUsers()
        // 更新が早すぎるので2秒遅延させる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshControl.endRefreshing()
        }
    }
    
    @IBAction func addComment() {
        let alert = UIAlertController(title: "コメント", message: "コメントを入力して下さい", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
            SVProgressHUD.show()
            let object = NCMBObject(className: "Comment")
            object?.setObject(self.postId, forKey: "postId")
            object?.setObject(NCMBUser.current(), forKey: "user")
            object?.setObject(alert.textFields?.first?.text, forKey: "text")
            object?.saveInBackground({ (error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    SVProgressHUD.dismiss()
                    self.getBlockUser()
                }
            })
        }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        alert.addTextField { (textField) in
            textField.placeholder = "ここにコメントを入力"
        }
        self.present(alert, animated: true, completion: nil)
    }
}

