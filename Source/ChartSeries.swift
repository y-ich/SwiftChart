//
//  ChartSeries.swift
//
//  Created by Giampaolo Bellavite on 07/11/14.
//  Copyright (c) 2014 Giampaolo Bellavite. All rights reserved.
//

import UIKit

/**
The `ChartSeries` class create a chart series and configure its appearance and behavior.
*/
open class ChartSeries {
    /**
    Return the intersection of a line between two points and 'y = level' line
    */
    private static func intersectionWithLevel(_ p1: ChartPoint, and p2: ChartPoint, level: Double) -> ChartPoint {
        let dy1 = level - p1.y
        let dy2 = level - p2.y
        return (x: (p2.x * dy1 - p1.x * dy2) / (dy1 - dy2), y: level)
    }


    /**
    The data used for the chart series.
    */
    public var data: [(x: Double, y: Double)]

    /**
    When set to `false`, will hide the series line. Useful for drawing only the area with `area=true`.
    */
    public var line: Bool = true

    /**
    The line width of the series. If `nil`, the default line width in Chart will be used.
    */
    public var lineWidth: CGFloat? = nil

    /**
    Draws an area below the series line.
    */
    public var area: Bool = false
    
    var segments: [ChartSegment] = []

    /**
    The series color.
    */
    public var color: UIColor = ChartColors.blueColor() {
        didSet {
            colors = (above: color, below: color, 0)
        }
    }

    /**
    A tuple to specify the color above or below the zero
    */
    public var colors: (
        above: UIColor,
        below: UIColor,
        zeroLevel: Double
    ) = (above: ChartColors.blueColor(), below: ChartColors.redColor(), 0) {
        didSet {
            if oldValue.zeroLevel != colors.zeroLevel {
                recalcSegents()
            }
        }
    }

    public init(_ data: [Double]) {
        self.data = data.enumerated().map { (x: Double($0.offset), y: $0.element) }
    }

    public init(data: [(x: Double, y: Double)]) {
        self.data = data
        recalcSegents()
    }

    public init(data: [(x: Int, y: Double)]) {
      self.data = data.map { (Double($0.x), Double($0.y)) }
        recalcSegents()
    }
    
    public init(data: [(x: Float, y: Float)]) {
        self.data = data.map { (Double($0.x), Double($0.y)) }
        recalcSegents()
    }
    
    func append(point: ChartPoint) -> Bool {
        data.append(point)
        return updateSegmentsTail()
    }
    
    func createLayers(for chart: Chart) -> [CAShapeLayer] {
        var layers = Array<CAShapeLayer>()
        for segment in segments {
            if line {
                layers.append(segment.createLineLayer(lineWidth: lineWidth ?? chart.lineWidth, with: colors, for: chart))
            }
            if area {
                layers.append(segment.createAreaLayer(with: colors, for: chart))
            }
        }
        
        return layers
    }
    
    func createLayersOfLastSegment(for chart: Chart) -> [CAShapeLayer] {
        var layers = Array<CAShapeLayer>()
        if let last = segments.last {
            if line {
                layers.append(last.createLineLayer(lineWidth: lineWidth ?? chart.lineWidth, with: colors, for: chart))
            }
            if area {
                layers.append(last.createAreaLayer(with: colors, for: chart))
            }
        }
        return layers
    }
    
    func redraw(segmentIndex: Int, for chart: Chart) {
        segments[segmentIndex].redraw(lineWidth: lineWidth ?? chart.lineWidth, with: colors, on: chart)
    }

    func redraw(for chart: Chart) {
        for segment in segments {
            segment.redraw(lineWidth: lineWidth ?? chart.lineWidth, with: colors, on: chart)
        }
    }
    
    open func removeFromChart() {
        for segment in segments {
            segment.lineLayer?.removeFromSuperlayer()
            segment.areaLayer?.removeFromSuperlayer()
        }
    }

    /**
    Segment a line in multiple lines when the line touches the x-axis, i.e. separating
    positive from negative values.
    */
    private func recalcSegents() {
        for segment in segments {
            segment.removeFromSuperlayer()
        }
        segments = []

        var segment: [ChartPoint] = []

        for (i, point) in data.enumerated() {
            segment.append(point)
            let isAboveZeroLine = point.y >= colors.zeroLevel
            if i < data.count - 1 {
                let nextPoint = data[i+1]
                if isAboveZeroLine && nextPoint.y < colors.zeroLevel || !isAboveZeroLine && nextPoint.y >= colors.zeroLevel {
                    // The segment intersects zeroLevel, close the segment with the intersection point
                    let closingPoint = ChartSeries.intersectionWithLevel(point, and: nextPoint, level: colors.zeroLevel)
                    segment.append(closingPoint)
                    segments.append(ChartSegment(data: segment, isAboveZeroLine: isAboveZeroLine))
                    // Start a new segment
                    segment = [closingPoint]
                }
            } else {
                // End of the line
                segments.append(ChartSegment(data: segment, isAboveZeroLine: isAboveZeroLine))
            }
        }
    }

    /** segmentを追加した時trueを返す */
    private func updateSegmentsTail() -> Bool {
        guard let lastPoint = data.last else {
            return false
        }
        if let segment = segments.last {
            let point = segment.data.last!
            let isAboveZeroLine = point.y >= colors.zeroLevel
            if isAboveZeroLine && lastPoint.y < colors.zeroLevel || !isAboveZeroLine && lastPoint.y >= colors.zeroLevel {
                // The segment intersects zeroLevel, close the segment with the intersection point
                let closingPoint = ChartSeries.intersectionWithLevel(point, and: lastPoint, level: colors.zeroLevel)
                segment.data.append(closingPoint)
                segments.append(ChartSegment(data: [closingPoint, lastPoint], isAboveZeroLine: !isAboveZeroLine))
                return true
            } else {
                segment.data.append(lastPoint)
            }
        } else {
            segments.append(ChartSegment(data: [lastPoint], isAboveZeroLine: lastPoint.y >= colors.zeroLevel))
            return true
        }
        return false
    }
}
