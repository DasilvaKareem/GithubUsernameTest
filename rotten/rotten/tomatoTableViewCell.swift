//
//  tomatoTableViewCell.swift
//  rotten
//
//  Created by Kareem Dasilva on 6/10/16.
//  Copyright © 2016 kareem. All rights reserved.
//

import UIKit

class tomatoTableViewCell: UITableViewCell {
    @IBOutlet var preview: UIImageView!
    
    @IBOutlet var texter: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
