//
//  ErrorView.swift
//  Simple Sudoku
//
//  Created by Jonas Theslöf on 2018-09-26.
//  Copyright © 2018 Jonas Theslöf. All rights reserved.
//

import UIKit

class ErrorView: UIView {

    var errors: [Sudoku.Error] = []

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(self.bounds)
        drawConflicts(rect, ctx)
    }

    private func drawConflicts(_ rect: CGRect, _ ctx: CGContext) {

        // First we draw the lines...
        for error in errors {
            drawLineBetweenCirclesOn(context: ctx, rect: rect, first: error.first, second: error.second)
        }

        // ...then we draw the circles. This way we can mask out any lines that show inside circles.
        for error in errors {
            drawCircleOn(context: ctx, rect: rect, position: error.first)
            drawCircleOn(context: ctx, rect: rect, position: error.second)
        }
    }

    private func drawCircleOn(context ctx: CGContext, rect: CGRect, position a: Int) {
        // Setup all variables we need:
        let width = rect.width / CGFloat(Globals.ROW_SIZE)
        let radius = width * 0.5
        let x = CGFloat(a % Globals.ROW_SIZE) * width + radius
        let y = CGFloat(a / Globals.ROW_SIZE) * width + radius
        let color = Sudoku.colorError

        // Tell our GFX context how we want our circles to appear
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2.0)

        // Create a path for the circle
        let path: CGPath = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: radius * 0.8, startAngle: CGFloat(0),
                endAngle:CGFloat(Double.pi * 2), clockwise: true).cgPath
        // Add the path to our context
        ctx.addPath(path)

        // First we mask out anything inside the circle
        ctx.setBlendMode(.clear)
        ctx.fillPath()

        // Then we draw the outlines of the circle
        ctx.setBlendMode(.normal)
        ctx.addPath(path)
        ctx.strokePath()
    }

    private func drawLineBetweenCirclesOn(context ctx: CGContext, rect: CGRect, first a: Int, second b: Int) {
        let width = rect.width / CGFloat(Globals.ROW_SIZE)
        let radius = width * 0.5
        let x1 = CGFloat(a % Globals.ROW_SIZE) * width + radius
        let y1 = CGFloat(a / Globals.ROW_SIZE) * width + radius
        let x2 = CGFloat(b % Globals.ROW_SIZE) * width + radius
        let y2 = CGFloat(b / Globals.ROW_SIZE) * width + radius
        let color = Sudoku.colorError

        ctx.beginPath()

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2.0)

        ctx.move(to: CGPoint(x: x1, y: y1))
        ctx.addLine(to: CGPoint(x: x2, y: y2))
        ctx.strokePath()
    }
}
