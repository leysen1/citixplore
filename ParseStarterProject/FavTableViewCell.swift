//
//  FavTableViewCell.swift
//  ParseStarterProject-Swift
//
//  Created by Charlotte Leysen on 29/11/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit

class FavTableViewCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var starRating: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
