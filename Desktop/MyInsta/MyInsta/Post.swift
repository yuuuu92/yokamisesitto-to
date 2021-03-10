//
//  Post.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/05.
//

import UIKit
import NCMB

class Post: NSObject {
    
    var objectId: String
    var user: User
    var imageUrl: String
    var text: String
    var createDate: Date
    var isLiked: Bool?
    var comments: [Comment]?
    var likeCount: Int = 0
    var label: String
    
    init(objectId: String, user: User, imageUrl: String, text: String, createDate: Date, label: String) {
        self.objectId = objectId
        self.user = user
        self.imageUrl = imageUrl
        self.text = text
        self.createDate = createDate
        self.label = label
    }
    
    static func create(_ postObject: NCMBObject) -> Post? {
        
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
            return nil
        }
        // ユーザー情報をUserクラスにセット
        let user = postObject.object(forKey: "user") as! NCMBUser
        
        // 退会済みユーザーの投稿を避けるため、activeがfalse以外のモノだけを表示
        if user.object(forKey: "active") as? Bool != false {
            // 投稿したユーザーの情報をUserモデルにまとめる
            let userModel = User(objectId: user.objectId, userName: user.userName)
            userModel.displayName = user.object(forKey: "displayName") as? String
            userModel.introduction = user.object(forKey: "introduction") as? String
            
            // 投稿の情報を取得
            let imageUrl = postObject.object(forKey: "imageUrl") as! String
            let text = postObject.object(forKey: "text") as! String
            let label = postObject.object(forKey: "label") as! String
            
            // 2つのデータ(投稿情報と誰が投稿したか?)を合わせてPostクラスにセット
            let post = Post(objectId: postObject.objectId, user: userModel, imageUrl: imageUrl, text: text, createDate: postObject.createDate, label: label)
            
            // likeの状況(自分が過去にLikeしているか？)によってデータを挿入
            let likeUsers = postObject.object(forKey: "likeUser") as? [String]
            if likeUsers?.contains(currentUser.objectId) == true {
                post.isLiked = true
            } else {
                post.isLiked = false
            }
            
            // いいねの件数
            if let likes = likeUsers {
                post.likeCount = likes.count
            }
            return post
        }
        return nil
    }
    
    static func create(_ postObject: NCMBObject, blockUserIdArray: [String]) -> Post? {
        let user = postObject.object(forKey: "user") as! NCMBUser
        let userId = user.objectId
        if blockUserIdArray.contains(userId!) {
            return nil
        }
        return create(postObject)
    }
}
