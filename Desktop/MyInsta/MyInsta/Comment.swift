//
//  Comment.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/05.
//

import UIKit

class Comment: NSObject {
    
    var postId: String
        var user: User
        var text: String
        var createDate: Date

        init(postId: String, user: User, text: String, createDate: Date) {
            self.postId = postId
            self.user = user
            self.text = text
            self.createDate = createDate
        }

}
