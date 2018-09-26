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
    static let colorBackgroundLight: UIColor = UIColor.white
    static let colorForegroundLight: UIColor = UIColor.black
    static let colorHighlightLight: UIColor = UIColor(hue: 0.586, saturation: 0.5, brightness: 1.0, alpha: 1.0)
    static let colorLockedLight: UIColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1.0)
    static let colorErrorLight: UIColor = UIColor(hue: 0, saturation: 1, brightness: 1.0, alpha: 1.0)

    static let colorBackgroundDark: UIColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1.0)
    static let colorForegroundDark: UIColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1.0)
    static let colorHighlightDark: UIColor = UIColor(hue: 0.586, saturation: 0.3, brightness: 0.5, alpha: 1.0)
    static let colorLockedDark: UIColor = UIColor(hue: 0, saturation: 0, brightness: 0.35, alpha: 1.0)
    static let colorErrorDark: UIColor = UIColor(hue: 0, saturation: 1, brightness: 1.0, alpha: 1.0)

    static var colorBackground: UIColor {
        if isDarkTheme() {
            return colorBackgroundDark
        }
        return colorBackgroundLight
    }
    static var colorForeground: UIColor {
        if isDarkTheme() {
            return colorForegroundDark
        }
        return colorForegroundLight
    }
    static var colorHighlight: UIColor {
        if isDarkTheme() {
            return colorHighlightDark
        }
        return colorHighlightLight
    }
    static var colorLocked: UIColor {
        if isDarkTheme() {
            return colorLockedDark
        }
        return colorLockedLight
    }
    static var colorError: UIColor {
        if isDarkTheme() {
            return colorErrorDark
        }
        return colorErrorLight
    }
}
