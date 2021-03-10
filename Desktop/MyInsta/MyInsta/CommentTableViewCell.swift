//
//  CommentTableViewCell.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/12/14.
//

import UIKit

protocol CommentTableViewCellDelegate {
    func didTapMenuButton(tableViewCell: UITableViewCell, button: UIButton)
    func didTapUserPageButton(tableViewCell: UITableViewCell)
}

class CommentTableViewCell: UITableViewCell {
    
    var delegate: CommentTableViewCellDelegate?
    
    @IBOutlet var userImageView: UIImageView!
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var commentLabel: UILabel!
    @IBOutlet var commentTimeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        userImageView.clipsToBounds = true
        
        userNameLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showUserPage(_:)))
        userNameLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc func showUserPage(_ sender: UITapGestureRecognizer) {
        self.delegate?.didTapUserPageButton(tableViewCell: self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func openMenu(button: UIButton) {
        self.delegate?.didTapMenuButton(tableViewCell: self, button: button)
    }
    
}
