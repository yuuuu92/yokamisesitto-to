//
//  User.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/05.
//

import UIKit

class User: NSObject {
    
    var objectId: String
    var userName: String
    var displayName: String?
    var introduction: String?

    init(objectId: String, userName: String) {
        self.objectId = objectId
        self.userName = userName
    }

}
