//
//  HorizontalBarChartRenderer.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


open class HorizontalBarChartRenderer: BarChartRenderer
{
    private class Buffer
    {
        var rects = [CGRect]()
    }
    
    public override init(dataProvider: BarChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler)
    {
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }
    
    // [CGRect] per dataset
    private var _buffers = [Buffer]()
    
    open override func initBuffers()
    {
        if let barData = dataProvider?.barData
        {
            // Matche buffers count to dataset count
            if _buffers.count != barData.count
            {
                while _buffers.count < barData.count
                {
                    _buffers.append(Buffer())
                }
                while _buffers.count > barData.count
                {
                    _buffers.removeLast()
                }
            }
            
            for i in barData.indices
            {
                let set = barData.dataSets[i] as! BarChartDataSetProtocol
                let size = set.entryCount * (set.isStacked ? set.stackSize : 1)
                if _buffers[i].rects.count != size
                {
                    _buffers[i].rects = [CGRect](repeating: CGRect(), count: size)
                }
            }
        }
        else
        {
            _buffers.removeAll()
        }
    }
    
    private func prepareBuffer(dataSet: BarChartDataSetProtocol, index: Int)
    {
        guard let
            dataProvider = dataProvider,
            let barData = dataProvider.barData
            else { return }
        
        let barWidthHalf = barData.barWidth / 2.0
        
        let buffer = _buffers[index]
        var bufferIndex = 0
        let containsStacks = dataSet.isStacked
        
        let isInverted = dataProvider.isInverted(axis: dataSet.axisDependency)
        let phaseY = animator.phaseY
        var barRect = CGRect()
        var x: Double
        var y: Double
        
        for i in stride(from: 0, to: min(Int(ceil(Double(dataSet.entryCount) * animator.phaseX)), dataSet.entryCount), by: 1)
        {
            guard let e = dataSet.entryForIndex(i) as? BarChartDataEntry else { continue }
            
            let vals = e.yValues
            
            x = e.x
            y = e.y
            
            if !containsStacks || vals == nil
            {
                let bottom = CGFloat(x - barWidthHalf)
                let top = CGFloat(x + barWidthHalf)
                var right = isInverted
                    ? (y <= 0.0 ? CGFloat(y) : 0)
                    : (y >= 0.0 ? CGFloat(y) : 0)
                var left = isInverted
                    ? (y >= 0.0 ? CGFloat(y) : 0)
                    : (y <= 0.0 ? CGFloat(y) : 0)
                
                // multiply the height of the rect with the phase
                if right > 0
                {
                    right *= CGFloat(phaseY)
                }
                else
                {
                    left *= CGFloat(phaseY)
                }
                
                barRect.origin.x = left
                barRect.size.width = right - left
                barRect.origin.y = top
                barRect.size.height = bottom - top
                
                buffer.rects[bufferIndex] = barRect
                bufferIndex += 1
            }
            else
            {
                var posY = 0.0
                var negY = -e.negativeSum
                var yStart = 0.0
                
                // fill the stack
                for k in 0 ..< vals!.count
                {
                    let value = vals![k]
                    
                    if value == 0.0 && (posY == 0.0 || negY == 0.0)
                    {
                        // Take care of the situation of a 0.0 value, which overlaps a non-zero bar
                        y = value
                        yStart = y
                    }
                    else if value >= 0.0
                    {
                        y = posY
                        yStart = posY + value
                        posY = yStart
                    }
                    else
                    {
                        y = negY
                        yStart = negY + abs(value)
                        negY += abs(value)
                    }
                    
                    let bottom = CGFloat(x - barWidthHalf)
                    let top = CGFloat(x + barWidthHalf)
                    var right = isInverted
                        ? (y <= yStart ? CGFloat(y) : CGFloat(yStart))
                        : (y >= yStart ? CGFloat(y) : CGFloat(yStart))
                    var left = isInverted
                        ? (y >= yStart ? CGFloat(y) : CGFloat(yStart))
                        : (y <= yStart ? CGFloat(y) : CGFloat(yStart))
                    
                    // multiply the height of the rect with the phase
                    right *= CGFloat(phaseY)
                    left *= CGFloat(phaseY)
                    
                    barRect.origin.x = left
                    barRect.size.width = right - left
                    barRect.origin.y = top
                    barRect.size.height = bottom - top
                    
                    buffer.rects[bufferIndex] = barRect
                    bufferIndex += 1
                }
            }
        }
    }
    
    private var _barShadowRectBuffer: CGRect = CGRect()
    
    open override func drawDataSet(context: CGContext, dataSet: BarChartDataSetProtocol, index: Int)
    {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        prepareBuffer(dataSet: dataSet, index: index)
        trans.rectValuesToPixel(&_buffers[index].rects)
        
        let borderWidth = dataSet.barBorderWidth
        let borderColor = dataSet.barBorderColor
        let drawBorder = borderWidth > 0.0
        
        context.saveGState()
        
        // draw the bar shadow before the values
        if dataProvider.isDrawBarShadowEnabled
        {
            guard let barData = dataProvider.barData else { return }
            
            let barWidth = barData.barWidth
            let barWidthHalf = barWidth / 2.0
            var x: Double = 0.0
            
            for i in stride(from: 0, to: min(Int(ceil(Double(dataSet.entryCount) * animator.phaseX)), dataSet.entryCount), by: 1)
            {
                guard let e = dataSet.entryForIndex(i) as? BarChartDataEntry else { continue }
                
                x = e.x
                
                _barShadowRectBuffer.origin.y = CGFloat(x - barWidthHalf)
                _barShadowRectBuffer.size.height = CGFloat(barWidth)
                
                trans.rectValueToPixel(&_barShadowRectBuffer)
                
                if !viewPortHandler.isInBoundsTop(_barShadowRectBuffer.origin.y + _barShadowRectBuffer.size.height)
                {
                    break
                }
                
                if !viewPortHandler.isInBoundsBottom(_barShadowRectBuffer.origin.y)
                {
                    continue
                }
                
                _barShadowRectBuffer.origin.x = viewPortHandler.contentLeft
                _barShadowRectBuffer.size.width = viewPortHandler.contentWidth
                
                context.setFillColor(dataSet.barShadowColor.cgColor)
                context.fill(_barShadowRectBuffer)
            }
        }
        
        let buffer = _buffers[index]
        
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(borderWidth)
        context.setLineCap(.square)

        // In case the chart is stacked, we need to accomodate individual bars within accessibilityOrderedElements
        let isStacked = dataSet.isStacked
        let stackSize = isStacked ? dataSet.stackSize : 1
        
        if stackSize > 1 {
            
            var leftRoundedCorners = UIRectCorner.allCorners, rightRoundedCorners = UIRectCorner.allCorners
            if dataSet.roundedCorners.contains(.topLeft) && dataSet.roundedCorners.contains(.bottomLeft)
            {
                leftRoundedCorners = [.topLeft, .bottomLeft]
            }
            else if dataSet.roundedCorners.contains(.topLeft)
            {
                leftRoundedCorners = .topLeft
            }
            else if dataSet.roundedCorners.contains(.bottomLeft)
            {
                leftRoundedCorners = .bottomLeft
            }
            if dataSet.roundedCorners.contains(.topRight) && dataSet.roundedCorners.contains(.bottomRight)
            {
                rightRoundedCorners = [.topRight, .bottomRight]
            }
            else if dataSet.roundedCorners.contains(.topRight)
            {
                rightRoundedCorners = .topRight
            }
            else if dataSet.roundedCorners.contains(.bottomRight)
            {
                rightRoundedCorners = .bottomRight
            }
            
            for firstIndexInBar in stride(from: 0, to: buffer.rects.count, by: stackSize)
            {
                let lastIndexInBar = firstIndexInBar + stackSize - 1
                
                var leftIndexInBar = -1, rightIndexInBar = -1
                if dataSet.roundedCorners.contains(.topLeft) || dataSet.roundedCorners.contains(.bottomLeft)
                {
                    leftIndexInBar = findMostLeftIndexInBar(barRects: buffer.rects,
                                                            firstIndexInBar: firstIndexInBar,
                                                            lastIndexInBar: lastIndexInBar)
                }
                if dataSet.roundedCorners.contains(.bottomLeft) || dataSet.roundedCorners.contains(.bottomRight)
                {
                    rightIndexInBar = findMostRightIndexInBar(barRects: buffer.rects,
                                                              firstIndexInBar: firstIndexInBar,
                                                              lastIndexInBar: lastIndexInBar)
                }
                
                for stackIndex in firstIndexInBar...lastIndexInBar
                {
                    context.saveGState()
                    
                    let barRect = buffer.rects[stackIndex]
                    var path : UIBezierPath
                    if leftIndexInBar>=0 && stackIndex==leftIndexInBar
                    {
                        path = createBarPath(for: barRect, roundedCorners: leftRoundedCorners, cornerRadius: dataSet.cornerRadius)
                    }
                    else if rightIndexInBar>=0 && stackIndex==rightIndexInBar
                    {
                        path = createBarPath(for: barRect, roundedCorners: rightRoundedCorners, cornerRadius: dataSet.cornerRadius)
                    }
                    else
                    {
                        path = createBarPath(for: barRect, roundedCorners: .allCorners, cornerRadius: 0)
                    }
                    
                    context.addPath(path.cgPath)
                    context.clip()
                    
                    guard viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width) else { continue }
                    guard viewPortHandler.isInBoundsRight(barRect.origin.x) else { break }
                    
                    
                    drawBar(context: context, dataSet: dataSet, index: stackIndex, barRect: barRect)
                    
                    // Create and append the corresponding accessibility element to accessibilityOrderedElements
                    if let chart = dataProvider as? BarChartView
                    {
                        let element = createAccessibleElement(withIndex: stackIndex,
                                                              container: chart,
                                                              dataSet: dataSet,
                                                              dataSetIndex: index,
                                                              stackSize: stackSize)
                        { (element) in
                            element.accessibilityFrame = barRect
                        }
                        
                        accessibilityOrderedElements[stackIndex/stackSize].append(element)
                    }
                    
                    context.restoreGState()
                    
                    if drawBorder
                    {
                        context.addPath(path.cgPath)
                        context.strokePath()
                    }
                }
            }
            
        }else {
            for barIndex in buffer.rects.indices
            {
                context.saveGState()
                
                let barRect = buffer.rects[barIndex]
                
                let path = createBarPath(for: barRect, roundedCorners: dataSet.roundedCorners, cornerRadius: dataSet.cornerRadius)
                
                context.addPath(path.cgPath)
                context.clip()
                
                guard viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width) else { continue }
                guard viewPortHandler.isInBoundsRight(barRect.origin.x) else { break }
                
                drawBar(context: context, dataSet: dataSet, index: barIndex, barRect: barRect)
                
                if drawBorder {
                    context.saveGState()
                }
                
                // Create and append the corresponding accessibility element to accessibilityOrderedElements
                if let chart = dataProvider as? BarChartView
                {
                    let element = createAccessibleElement(withIndex: barIndex,
                                                          container: chart,
                                                          dataSet: dataSet,
                                                          dataSetIndex: index,
                                                          stackSize: stackSize)
                    { (element) in
                        element.accessibilityFrame = barRect
                    }
                    
                    accessibilityOrderedElements[barIndex/stackSize].append(element)
                }
                
                context.restoreGState()
                
                if drawBorder
                {
                    context.addPath(path.cgPath)
                    context.strokePath()
                }
            }
        }
    }
    
    open override func prepareBarHighlight(
        x: Double,
        y1: Double,
        y2: Double,
        barWidthHalf: Double,
        trans: Transformer,
        rect: inout CGRect)
    {
        let top = x - barWidthHalf
        let bottom = x + barWidthHalf
        let left = y1
        let right = y2
        
        rect.origin.x = CGFloat(left)
        rect.origin.y = CGFloat(top)
        rect.size.width = CGFloat(right - left)
        rect.size.height = CGFloat(bottom - top)
        
        trans.rectValueToPixelHorizontal(&rect, phaseY: animator.phaseY)
    }
    
    open override func drawValues(context: CGContext)
    {
        // if values are drawn
        if isDrawingValuesAllowed(dataProvider: dataProvider)
        {
            guard
                let dataProvider = dataProvider,
                let barData = dataProvider.barData
                else { return }
            
            var dataSets = barData.dataSets
            
            let textAlign = NSTextAlignment.left
            
            let valueOffsetPlus: CGFloat = 5.0
            var posOffset: CGFloat
            var negOffset: CGFloat
            let drawValueAboveBar = dataProvider.isDrawValueAboveBarEnabled
            
            for dataSetIndex in barData.indices
            {
                guard let dataSet = dataSets[dataSetIndex] as? BarChartDataSetProtocol else { continue }
                
                let angleRadians = dataSet.valueLabelAngle.DEG2RAD
                
                if !shouldDrawValues(forDataSet: dataSet) || !(dataSet.isDrawIconsEnabled && dataSet.isVisible)
                {
                    continue
                }
                
                let isInverted = dataProvider.isInverted(axis: dataSet.axisDependency)
                
                let valueFont = dataSet.valueFont
                let yOffset = -valueFont.lineHeight / 2.0
                
                let formatter = dataSet.valueFormatter
                
                let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
                
                let phaseY = animator.phaseY
                
                let iconsOffset = dataSet.iconsOffset
                
                let buffer = _buffers[dataSetIndex]
                
                // if only single values are drawn (sum)
                if !dataSet.isStacked
                {
                    for j in 0 ..< Int(ceil(Double(dataSet.entryCount) * animator.phaseX))
                    {
                        guard let e = dataSet.entryForIndex(j) as? BarChartDataEntry else { continue }
                        
                        let rect = buffer.rects[j]
                        
                        let y = rect.origin.y + rect.size.height / 2.0
                        
                        if !viewPortHandler.isInBoundsTop(rect.origin.y)
                        {
                            break
                        }
                        
                        if !viewPortHandler.isInBoundsX(rect.origin.x)
                        {
                            continue
                        }
                        
                        if !viewPortHandler.isInBoundsBottom(rect.origin.y)
                        {
                            continue
                        }
                        
                        let val = e.y
                        let valueText = formatter.stringForValue(
                            val,
                            entry: e,
                            dataSetIndex: dataSetIndex,
                            viewPortHandler: viewPortHandler)
                        
                        // calculate the correct offset depending on the draw position of the value
                        let valueTextWidth = valueText.size(withAttributes: [.font: valueFont]).width
                        posOffset = (drawValueAboveBar ? valueOffsetPlus : -(valueTextWidth + valueOffsetPlus))
                        negOffset = (drawValueAboveBar ? -(valueTextWidth + valueOffsetPlus) : valueOffsetPlus)
                        
                        if isInverted
                        {
                            posOffset = -posOffset - valueTextWidth
                            negOffset = -negOffset - valueTextWidth
                        }
                        
                        if dataSet.isDrawValuesEnabled
                        {
                            drawValue(
                                context: context,
                                value: valueText,
                                xPos: (rect.origin.x + rect.size.width)
                                    + (val >= 0.0 ? posOffset : negOffset),
                                yPos: y + yOffset,
                                font: valueFont,
                                align: textAlign,
                                color: dataSet.valueTextColorAt(j),
                                anchor: CGPoint.zero,
                                angleRadians: angleRadians)
                        }
                        
                        if let icon = e.icon, dataSet.isDrawIconsEnabled
                        {
                            var px = (rect.origin.x + rect.size.width)
                                + (val >= 0.0 ? posOffset : negOffset)
                            var py = y
                            
                            px += iconsOffset.x
                            py += iconsOffset.y
                            
                            context.drawImage(icon,
                                              atCenter: CGPoint(x: px, y: py),
                                              size: icon.size)
                        }
                    }
                }
                else
                {
                    // if each value of a potential stack should be drawn
                    
                    var bufferIndex = 0
                    
                    for index in 0 ..< Int(ceil(Double(dataSet.entryCount) * animator.phaseX))
                    {
                        guard let e = dataSet.entryForIndex(index) as? BarChartDataEntry else { continue }
                        
                        let rect = buffer.rects[bufferIndex]
                        
                        let vals = e.yValues
                        
                        // we still draw stacked bars, but there is one non-stacked in between
                        if vals == nil
                        {
                            if !viewPortHandler.isInBoundsTop(rect.origin.y)
                            {
                                break
                            }
                            
                            if !viewPortHandler.isInBoundsX(rect.origin.x)
                            {
                                continue
                            }
                            
                            if !viewPortHandler.isInBoundsBottom(rect.origin.y)
                            {
                                continue
                            }
                            
                            let val = e.y
                            let valueText = formatter.stringForValue(
                                val,
                                entry: e,
                                dataSetIndex: dataSetIndex,
                                viewPortHandler: viewPortHandler)
                            
                            // calculate the correct offset depending on the draw position of the value
                            let valueTextWidth = valueText.size(withAttributes: [NSAttributedString.Key.font: valueFont]).width
                            posOffset = (drawValueAboveBar ? valueOffsetPlus : -(valueTextWidth + valueOffsetPlus))
                            negOffset = (drawValueAboveBar ? -(valueTextWidth + valueOffsetPlus) : valueOffsetPlus)
                            
                            if isInverted
                            {
                                posOffset = -posOffset - valueTextWidth
                                negOffset = -negOffset - valueTextWidth
                            }
                            
                            if dataSet.isDrawValuesEnabled
                            {
                                drawValue(
                                    context: context,
                                    value: valueText,
                                    xPos: (rect.origin.x + rect.size.width)
                                        + (val >= 0.0 ? posOffset : negOffset),
                                    yPos: rect.origin.y + yOffset,
                                    font: valueFont,
                                    align: textAlign,
                                    color: dataSet.valueTextColorAt(index),
                                    anchor: CGPoint.zero,
                                    angleRadians: angleRadians)
                            }
                            
                            if let icon = e.icon, dataSet.isDrawIconsEnabled
                            {
                                var px = (rect.origin.x + rect.size.width)
                                    + (val >= 0.0 ? posOffset : negOffset)
                                var py = rect.origin.y
                                
                                px += iconsOffset.x
                                py += iconsOffset.y
                                
                                context.drawImage(icon,
                                                  atCenter: CGPoint(x: px, y: py),
                                                  size: icon.size)
                            }
                        }
                        else
                        {
                            let vals = vals!
                            var transformed = [CGPoint]()
                            
                            var posY = 0.0
                            var negY = -e.negativeSum
                            
                            for k in 0 ..< vals.count
                            {
                                let value = vals[k]
                                var y: Double
                                
                                if value == 0.0 && (posY == 0.0 || negY == 0.0)
                                {
                                    // Take care of the situation of a 0.0 value, which overlaps a non-zero bar
                                    y = value
                                }
                                else if value >= 0.0
                                {
                                    posY += value
                                    y = posY
                                }
                                else
                                {
                                    y = negY
                                    negY -= value
                                }
                                
                                transformed.append(CGPoint(x: CGFloat(y * phaseY), y: 0.0))
                            }
                            
                            trans.pointValuesToPixel(&transformed)
                            
                            for k in 0 ..< transformed.count
                            {
                                let val = vals[k]
                                let valueText = formatter.stringForValue(
                                    val,
                                    entry: e,
                                    dataSetIndex: dataSetIndex,
                                    viewPortHandler: viewPortHandler)
                                
                                // calculate the correct offset depending on the draw position of the value
                                let valueTextWidth = valueText.size(withAttributes: [.font: valueFont]).width
                                posOffset = (drawValueAboveBar ? valueOffsetPlus : -(valueTextWidth + valueOffsetPlus))
                                negOffset = (drawValueAboveBar ? -(valueTextWidth + valueOffsetPlus) : valueOffsetPlus)
                                
                                if isInverted
                                {
                                    posOffset = -posOffset - valueTextWidth
                                    negOffset = -negOffset - valueTextWidth
                                }
                                
                                let drawBelow = (val == 0.0 && negY == 0.0 && posY > 0.0) || val < 0.0

                                let x = transformed[k].x + (drawBelow ? negOffset : posOffset)
                                let y = rect.origin.y + rect.size.height / 2.0
                                
                                if (!viewPortHandler.isInBoundsTop(y))
                                {
                                    break
                                }
                                
                                if (!viewPortHandler.isInBoundsX(x))
                                {
                                    continue
                                }
                                
                                if (!viewPortHandler.isInBoundsBottom(y))
                                {
                                    continue
                                }
                                
                                if dataSet.isDrawValuesEnabled
                                {
                                    drawValue(context: context,
                                              value: valueText,
                                              xPos: x,
                                              yPos: y + yOffset,
                                              font: valueFont,
                                              align: textAlign,
                                              color: dataSet.valueTextColorAt(index),
                                              anchor: CGPoint.zero,
                                              angleRadians: angleRadians)
                                }
                                
                                if let icon = e.icon, dataSet.isDrawIconsEnabled
                                {
                                    context.drawImage(icon,
                                                      atCenter: CGPoint(x: x + iconsOffset.x,
                                                                      y: y + iconsOffset.y),
                                                      size: icon.size)
                                }
                            }
                        }
                        
                        bufferIndex = vals == nil ? (bufferIndex + 1) : (bufferIndex + vals!.count)
                    }
                }
            }
        }
    }
    
    open override func isDrawingValuesAllowed(dataProvider: ChartDataProvider?) -> Bool
    {
        guard let data = dataProvider?.data
            else { return false }
        return data.entryCount < Int(CGFloat(dataProvider?.maxVisibleCount ?? 0) * self.viewPortHandler.scaleY)
    }
    
    /// Sets the drawing position of the highlight object based on the riven bar-rect.
    internal override func setHighlightDrawPos(highlight high: Highlight, barRect: CGRect)
    {
        high.setDraw(x: barRect.midY, y: barRect.origin.x + barRect.size.width)
    }
    
    override internal func createBarPath(for rect: CGRect, roundedCorners: UIRectCorner, cornerRadius: CGFloat) -> UIBezierPath {
        let modifyCornerRadius = min(cornerRadius, rect.size.height/2)
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: roundedCorners,
                                cornerRadii: CGSize(width: modifyCornerRadius, height: modifyCornerRadius))
        
        return path
    }
    
    private func findMostLeftIndexInBar(barRects: [CGRect], firstIndexInBar: Int, lastIndexInBar: Int) -> Int {
        var leftIndexInBar = firstIndexInBar
        var leftRectInBar = barRects[leftIndexInBar]
        if barRects[lastIndexInBar].origin.x < leftRectInBar.origin.x {
            leftIndexInBar = lastIndexInBar
            leftRectInBar = barRects[leftIndexInBar]
        }
        
        var width: CGFloat = 0
        for index in firstIndexInBar...lastIndexInBar {
            width += barRects[index].width
        }
        
        leftRectInBar.size.width = width
        
        return leftIndexInBar
    }
    
    private func findMostRightIndexInBar(barRects: [CGRect], firstIndexInBar: Int, lastIndexInBar: Int) -> Int {
        var rightIndexInBar = firstIndexInBar
        var rightRectInBar = barRects[rightIndexInBar]
        if barRects[lastIndexInBar].origin.x > rightRectInBar.origin.x {
            rightIndexInBar = lastIndexInBar
            rightRectInBar = barRects[rightIndexInBar]
        }
        
        var width: CGFloat = 0
        for index in firstIndexInBar...lastIndexInBar {
            width += barRects[index].width
        }
        
        rightRectInBar.size.width = width
        
        return rightIndexInBar
    }
}
