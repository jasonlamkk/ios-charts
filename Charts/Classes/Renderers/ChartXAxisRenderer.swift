//
//  ChartXAxisRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 3/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics
import UIKit

public class ChartXAxisRenderer: ChartAxisRendererBase
{
    internal var _xAxis: ChartXAxis!
  
    public init(viewPortHandler: ChartViewPortHandler, xAxis: ChartXAxis, transformer: ChartTransformer!)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer)
        
        _xAxis = xAxis
    }
    
    public func computeAxis(xValAverageLength xValAverageLength: Double, xValues: [String?])
    {
        var a = ""
        
        let max = Int(round(xValAverageLength + Double(_xAxis.spaceBetweenLabels)))
        
        for (var i = 0; i < max; i++)
        {
            a += "h"
        }
        
        let widthText = a as NSString
        
        let labelSize = widthText.sizeWithAttributes([NSFontAttributeName: _xAxis.labelFont])
        
        let labelWidth = labelSize.width
        let labelHeight = labelSize.height
        
        let labelRotatedSize = ChartUtils.sizeOfRotatedRectangle(labelSize, degrees: _xAxis.labelRotationAngle)
        
        _xAxis.labelWidth = labelWidth
        _xAxis.labelHeight = labelHeight
        _xAxis.labelRotatedWidth = labelRotatedSize.width
        _xAxis.labelRotatedHeight = labelRotatedSize.height
        
        _xAxis.values = xValues
    }
    
    public override func renderAxisLabels(context context: CGContext)
    {
        if (!_xAxis.isEnabled || !_xAxis.isDrawLabelsEnabled)
        {
            return
        }
        
        let yOffset = _xAxis.yOffset
        
        if (_xAxis.labelPosition == .Top)
        {
            drawLabels(context: context, pos: viewPortHandler.contentTop - yOffset, anchor: CGPoint(x: 0.5, y: 1.0))
        }
        else if (_xAxis.labelPosition == .TopInside)
        {
            drawLabels(context: context, pos: viewPortHandler.contentTop + yOffset + _xAxis.labelRotatedHeight, anchor: CGPoint(x: 0.5, y: 1.0))
        }
        else if (_xAxis.labelPosition == .Bottom)
        {
            drawLabels(context: context, pos: viewPortHandler.contentBottom + yOffset, anchor: CGPoint(x: 0.5, y: 0.0))
        }
        else if (_xAxis.labelPosition == .BottomInside)
        {
            drawLabels(context: context, pos: viewPortHandler.contentBottom - yOffset - _xAxis.labelRotatedHeight, anchor: CGPoint(x: 0.5, y: 0.0))
        }
        else
        { // BOTH SIDED
            drawLabels(context: context, pos: viewPortHandler.contentTop - yOffset, anchor: CGPoint(x: 0.5, y: 1.0))
            drawLabels(context: context, pos: viewPortHandler.contentBottom + yOffset, anchor: CGPoint(x: 0.5, y: 0.0))
        }
    }
    
    private var _axisLineSegmentsBuffer = [CGPoint](count: 2, repeatedValue: CGPoint())
    
    public override func renderAxisLine(context context: CGContext)
    {
        if (!_xAxis.isEnabled || !_xAxis.isDrawAxisLineEnabled)
        {
            return
        }
        
        CGContextSaveGState(context)
        
        CGContextSetStrokeColorWithColor(context, _xAxis.axisLineColor.CGColor)
        CGContextSetLineWidth(context, _xAxis.axisLineWidth)
        if (_xAxis.axisLineDashLengths != nil)
        {
            CGContextSetLineDash(context, _xAxis.axisLineDashPhase, _xAxis.axisLineDashLengths, _xAxis.axisLineDashLengths.count)
        }
        else
        {
            CGContextSetLineDash(context, 0.0, nil, 0)
        }

        if (_xAxis.labelPosition == .Top
                || _xAxis.labelPosition == .TopInside
                || _xAxis.labelPosition == .BothSided)
        {
            _axisLineSegmentsBuffer[0].x = viewPortHandler.contentLeft
            _axisLineSegmentsBuffer[0].y = viewPortHandler.contentTop
            _axisLineSegmentsBuffer[1].x = viewPortHandler.contentRight
            _axisLineSegmentsBuffer[1].y = viewPortHandler.contentTop
            CGContextStrokeLineSegments(context, _axisLineSegmentsBuffer, 2)
        }

        if (_xAxis.labelPosition == .Bottom
                || _xAxis.labelPosition == .BottomInside
                || _xAxis.labelPosition == .BothSided)
        {
            _axisLineSegmentsBuffer[0].x = viewPortHandler.contentLeft
            _axisLineSegmentsBuffer[0].y = viewPortHandler.contentBottom
            _axisLineSegmentsBuffer[1].x = viewPortHandler.contentRight
            _axisLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
            CGContextStrokeLineSegments(context, _axisLineSegmentsBuffer, 2)
        }
        
        CGContextRestoreGState(context)
    }
    
    /// draws the x-labels on the specified y-position
    internal func drawLabels(context context: CGContext, pos: CGFloat, anchor: CGPoint)
    {
        let paraStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paraStyle.alignment = .Center
        
        let labelAttrs = [NSFontAttributeName: _xAxis.labelFont,
            NSForegroundColorAttributeName: _xAxis.labelTextColor,
            NSParagraphStyleAttributeName: paraStyle]
        let labelRotationAngleRadians = _xAxis.labelRotationAngle * ChartUtils.Math.FDEG2RAD
        
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        var labelMaxSize = CGSize()
        
        if (_xAxis.isWordWrapEnabled)
        {
            labelMaxSize.width = _xAxis.wordWrapWidthPercent * valueToPixelMatrix.a
        }
        
        for (var i = _minX, maxX = min(_maxX + 1, _xAxis.values.count); i < maxX; i += _xAxis.axisLabelModulus)
        {
            let label = _xAxis.values[i]
            if (label == nil)
            {
                continue
            }
            
            position.x = CGFloat(i)
            position.y = 0.0
            position = CGPointApplyAffineTransform(position, valueToPixelMatrix)
            
            if (viewPortHandler.isInBoundsX(position.x))
            {
                let labelns = label! as NSString
                
                if (_xAxis.isAvoidFirstLastClippingEnabled)
                {
                    // avoid clipping of the last
                    if (i == _xAxis.values.count - 1 && _xAxis.values.count > 1)
                    {
                        let width = labelns.boundingRectWithSize(labelMaxSize, options: .UsesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        
                        if (width > viewPortHandler.offsetRight * 2.0
                            && position.x + width > viewPortHandler.chartWidth)
                        {
                            position.x -= width / 2.0
                        }
                    }
                    else if (i == 0)
                    { // avoid clipping of the first
                        let width = labelns.boundingRectWithSize(labelMaxSize, options: .UsesLineFragmentOrigin, attributes: labelAttrs, context: nil).size.width
                        position.x += width / 2.0
                    }
                }
                
                drawLabel(context: context, label: label!, xIndex: i, x: position.x, y: pos, attributes: labelAttrs, constrainedToSize: labelMaxSize, anchor: anchor, angleRadians: labelRotationAngleRadians)
            }
        }
    }
    
    internal func drawLabel(context context: CGContext, label: String, xIndex: Int, x: CGFloat, y: CGFloat, attributes: [String: NSObject], constrainedToSize: CGSize, anchor: CGPoint, angleRadians: CGFloat)
    {
        let formattedLabel = _xAxis.valueFormatter?.stringForXValue(xIndex, original: label, viewPortHandler: viewPortHandler) ?? label
        ChartUtils.drawMultilineText(context: context, text: formattedLabel, point: CGPoint(x: x, y: y), attributes: attributes, constrainedToSize: constrainedToSize, anchor: anchor, angleRadians: angleRadians)
    }
    
    private var _gridLineSegmentsBuffer = [CGPoint](count: 2, repeatedValue: CGPoint())
    
    public override func renderGridLines(context context: CGContext)
    {
        if (!_xAxis.isDrawGridLinesEnabled || !_xAxis.isEnabled)
        {
            return
        }
        
        CGContextSaveGState(context)

        if (!_xAxis.gridAntialiasEnabled)
        {
            CGContextSetShouldAntialias(context, false)
        }

        CGContextSetStrokeColorWithColor(context, _xAxis.gridColor.CGColor)
        
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        if _xAxis.gridLineDashLengths != nil {
            
            for (var i = _minX+1; i < _maxX; i += 1)
            {
                position.x = CGFloat(i)
                position.y = 0.0
                position = CGPointApplyAffineTransform(position, valueToPixelMatrix)
                
                if (position.x >= viewPortHandler.offsetLeft
                    && position.x <= viewPortHandler.chartWidth)
                {
                    if i % _xAxis.axisLabelModulus == 0 {
                        //old dash line
                        CGContextSetLineWidth(context, _xAxis.gridLineWidth)
                        CGContextSetLineDash(context, _xAxis.gridLineDashPhase, _xAxis.gridLineDashLengths, _xAxis.gridLineDashLengths.count)
                        _gridLineSegmentsBuffer[0].x = position.x
                        _gridLineSegmentsBuffer[0].y = viewPortHandler.contentTop
                        _gridLineSegmentsBuffer[1].x = position.x
                        _gridLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
                        CGContextStrokeLineSegments(context, _gridLineSegmentsBuffer, 2)
                        //top hair
                        CGContextSetLineWidth(context, _xAxis.gridLineWidth+1)
                        CGContextSetLineDash(context, 0.0, nil, 0)
                        _gridLineSegmentsBuffer[0].x = position.x
                        _gridLineSegmentsBuffer[0].y = viewPortHandler.contentTop
                        _gridLineSegmentsBuffer[1].x = position.x
                        _gridLineSegmentsBuffer[1].y = viewPortHandler.contentTop + 10
                        CGContextStrokeLineSegments(context, _gridLineSegmentsBuffer, 2)
                        //bottom hair
                        _gridLineSegmentsBuffer[0].x = position.x
                        _gridLineSegmentsBuffer[0].y = viewPortHandler.contentBottom - 10
                        _gridLineSegmentsBuffer[1].x = position.x
                        _gridLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
                        CGContextStrokeLineSegments(context, _gridLineSegmentsBuffer, 2)
                    }else{
                        //short hair line for each skipped x
                        CGContextSetLineDash(context, 0.0, nil, 0)
                        CGContextSetLineWidth(context, _xAxis.gridLineWidth+1)
                        
                        _gridLineSegmentsBuffer[0].x = position.x
                        _gridLineSegmentsBuffer[0].y = viewPortHandler.contentTop
                        _gridLineSegmentsBuffer[1].x = position.x
                        _gridLineSegmentsBuffer[1].y = viewPortHandler.contentTop + 5
                        CGContextStrokeLineSegments(context, _gridLineSegmentsBuffer, 2)
                        
                        
                        _gridLineSegmentsBuffer[0].x = position.x
                        _gridLineSegmentsBuffer[0].y = viewPortHandler.contentBottom - 5
                        _gridLineSegmentsBuffer[1].x = position.x
                        _gridLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
                        CGContextStrokeLineSegments(context, _gridLineSegmentsBuffer, 2)
                    }
                }
            }
        } else {
            
            CGContextSetLineDash(context, 0.0, nil, 0)
            CGContextSetLineWidth(context, _xAxis.gridLineWidth)
            for (var i = _minX+1; i < _maxX; i += _xAxis.axisLabelModulus)
            {
                position.x = CGFloat(i)
                position.y = 0.0
                position = CGPointApplyAffineTransform(position, valueToPixelMatrix)
                
                if (position.x >= viewPortHandler.offsetLeft
                    && position.x <= viewPortHandler.chartWidth)
                {
                    _gridLineSegmentsBuffer[0].x = position.x
                    _gridLineSegmentsBuffer[0].y = viewPortHandler.contentTop
                    _gridLineSegmentsBuffer[1].x = position.x
                    _gridLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
                    CGContextStrokeLineSegments(context, _gridLineSegmentsBuffer, 2)
                }
            }
        }
        
        CGContextRestoreGState(context)
    }
    
    public override func renderLimitLines(context context: CGContext)
    {
        var limitLines = _xAxis.limitLines
        
        if (limitLines.count == 0)
        {
            return
        }
        
        CGContextSaveGState(context)
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for (var i = 0; i < limitLines.count; i++)
        {
            let l = limitLines[i]
            
            if !l.isEnabled
            {
                continue
            }

            position.x = CGFloat(l.limit)
            position.y = 0.0
            position = CGPointApplyAffineTransform(position, trans)
            
            renderLimitLineLine(context: context, limitLine: l, position: position)
            renderLimitLineLabel(context: context, limitLine: l, position: position, yOffset: 2.0 + l.yOffset)
        }
        
        CGContextRestoreGState(context)
    }
    
    private var _limitLineSegmentsBuffer = [CGPoint](count: 2, repeatedValue: CGPoint())
    
    public func renderLimitLineLine(context context: CGContext, limitLine: ChartLimitLine, position: CGPoint)
    {
        _limitLineSegmentsBuffer[0].x = position.x
        _limitLineSegmentsBuffer[0].y = viewPortHandler.contentTop
        _limitLineSegmentsBuffer[1].x = position.x
        _limitLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
        
        CGContextSetStrokeColorWithColor(context, limitLine.lineColor.CGColor)
        CGContextSetLineWidth(context, limitLine.lineWidth)
        if (limitLine.lineDashLengths != nil)
        {
            CGContextSetLineDash(context, limitLine.lineDashPhase, limitLine.lineDashLengths!, limitLine.lineDashLengths!.count)
        }
        else
        {
            CGContextSetLineDash(context, 0.0, nil, 0)
        }
        
        CGContextStrokeLineSegments(context, _limitLineSegmentsBuffer, 2)
    }
    
    public func renderLimitLineLabel(context context: CGContext, limitLine: ChartLimitLine, position: CGPoint, yOffset: CGFloat)
    {
        let label = limitLine.label
        
        // if drawing the limit-value label is enabled
        if (label.characters.count > 0)
        {
            let labelLineHeight = limitLine.valueFont.lineHeight
            
            let xOffset: CGFloat = limitLine.lineWidth + limitLine.xOffset
            
            if (limitLine.labelPosition == .RightTop)
            {
                ChartUtils.drawText(context: context,
                    text: label,
                    point: CGPoint(
                        x: position.x + xOffset,
                        y: viewPortHandler.contentTop + yOffset),
                    align: .Left,
                    attributes: [NSFontAttributeName: limitLine.valueFont, NSForegroundColorAttributeName: limitLine.valueTextColor])
            }
            else if (limitLine.labelPosition == .RightBottom)
            {
                ChartUtils.drawText(context: context,
                    text: label,
                    point: CGPoint(
                        x: position.x + xOffset,
                        y: viewPortHandler.contentBottom - labelLineHeight - yOffset),
                    align: .Left,
                    attributes: [NSFontAttributeName: limitLine.valueFont, NSForegroundColorAttributeName: limitLine.valueTextColor])
            }
            else if (limitLine.labelPosition == .LeftTop)
            {
                ChartUtils.drawText(context: context,
                    text: label,
                    point: CGPoint(
                        x: position.x - xOffset,
                        y: viewPortHandler.contentTop + yOffset),
                    align: .Right,
                    attributes: [NSFontAttributeName: limitLine.valueFont, NSForegroundColorAttributeName: limitLine.valueTextColor])
            }
            else
            {
                ChartUtils.drawText(context: context,
                    text: label,
                    point: CGPoint(
                        x: position.x - xOffset,
                        y: viewPortHandler.contentBottom - labelLineHeight - yOffset),
                    align: .Right,
                    attributes: [NSFontAttributeName: limitLine.valueFont, NSForegroundColorAttributeName: limitLine.valueTextColor])
            }
        }
    }

}
