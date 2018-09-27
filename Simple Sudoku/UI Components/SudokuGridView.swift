//
//  SudokuGridView.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-26.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class SudokuGridView: UIView {
    var gridColor: UIColor = Sudoku.colorForeground

    override func draw(_ rect: CGRect) {

        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        drawGrid(rect, ctx)
        drawSections(rect, ctx)

    }

    private func drawGrid(_ rect: CGRect, _ ctx: CGContext) {
        let width = rect.width / CGFloat(Globals.ROW_SIZE)

        ctx.beginPath()

        for i in 1..<Globals.ROW_SIZE {
            let x = width * CGFloat(i)

            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: rect.width))

            ctx.move(to: CGPoint(x: 0, y: x))
            ctx.addLine(to: CGPoint(x: rect.width, y: x))
        }

        ctx.setLineWidth(1)
        ctx.setStrokeColor(gridColor.cgColor)
        ctx.strokePath()

    }

    private func drawSections(_ rect: CGRect, _ ctx: CGContext) {
        let width = rect.width / CGFloat(Globals.ROW_SIZE)

        ctx.beginPath()

        for i in 0...Globals.SEC_WIDTH {
            let x = width * CGFloat(i * 3)

            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: rect.width))

            ctx.move(to: CGPoint(x: 0, y: x))
            ctx.addLine(to: CGPoint(x: rect.width, y: x))
        }

        ctx.setLineWidth(2)
        ctx.setStrokeColor(gridColor.cgColor)
        ctx.strokePath()

    }
}
