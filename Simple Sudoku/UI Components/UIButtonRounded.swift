//
//  UIButtonRounded.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-08-31.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class UIButtonRounded: UIButton {
    
    @IBInspectable var borderRadius: CGFloat = 5 {
        didSet {
            updateCorners(cornerRadius: borderRadius)
        }
    }
    
    @IBInspectable var borderThickness: CGFloat = 1 {
        didSet {
            self.layer.borderWidth = borderThickness
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.black {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        setup()
    }
 
    func setup() {
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.black.cgColor
        self.tintColor = UIColor.black
    }
    
    func updateCorners(cornerRadius radius: CGFloat) {
        self.layer.cornerRadius = radius
    }
}
