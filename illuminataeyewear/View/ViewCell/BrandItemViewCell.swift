//
//  BrandItemViewCell.swift
//  illuminataeyewear
//
//  Created by Bushko Konstantyn on 1/13/16.
//  Copyright © 2016 illuminataeyewear. All rights reserved.
//

import UIKit

class BrandItemViewCell: UITableViewCell {

    // MARK: Properties
    var brandItem: BrandItem?
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var number: UILabel!
    
    
    @IBOutlet weak var BuyNowButton: ExButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func getDataModelObject() -> BrandItem {
        brandItem = BrandItem()
        brandItem?.setImage(self.photo.image!)
        brandItem?.setName(self.name.text!)
        return brandItem!
    }
}
