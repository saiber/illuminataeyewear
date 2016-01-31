//
//  RoundRectButton.swift
//  illuminataeyewear
//
//  Created by Bushko Konstantyn on 1/26/16.
//  Copyright © 2016 illuminataeyewear. All rights reserved.
//

import UIKit

class RoundRectButton: UIButton {
    
    var id: Int = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 8.0;
    }

}