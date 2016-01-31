//
//  Extension.swift
//  illuminataeyewear
//
//  Created by Bushko Konstantyn on 1/19/16.
//  Copyright © 2016 illuminataeyewear. All rights reserved.
//

import Foundation

extension String {
    func htmlDecoded()->String {
        guard (self != "") else { return self }
        
        var newStr = self
        
        let entities = [
            "&quot;"    : "\"",
            "&amp;"     : "&",
            "&apos;"    : "'",
            "&lt;"      : "<",
            "&gt;"      : ">",
        ]
        
        for (name,value) in entities {
            newStr = newStr.stringByReplacingOccurrencesOfString(name, withString: value)
        }
        return newStr
    }
}