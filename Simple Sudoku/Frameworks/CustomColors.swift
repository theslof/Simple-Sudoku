//
//  CustomColors.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-08-31.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import Foundation
import UIKit


extension Sudoku {
    static var colorBackground: UIColor = UIColor.white
    static var colorForeground: UIColor = UIColor.black
    static var colorHighlight: UIColor = UIColor(hue: 0.586, saturation: 0.5, brightness: 1.0, alpha: 1.0)
    static var colorLocked: UIColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1.0)
    static var colorError: UIColor = UIColor(hue: 0, saturation: 1, brightness: 1.0, alpha: 1.0)
}
