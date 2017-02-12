//
//  SimpleCustomCell.swift
//  DEH Narrator
//
//  Created by 蔡佳旅 on 2016/11/27.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

class SimpleCustomCell: UITableViewCell {
    
    @IBOutlet weak var identifier: UIImageView!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}