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
    Segment a line in multiple lines when the line touches the x-axis, i.e. separating
    positive from negative values.
    */
    private func updateSegments() {
        segments = []
        var segment: [ChartPoint] = []

        for (i, point) in data.enumerated() {
            segment.append(point)
            if i < data.count - 1 {
                let nextPoint = data[i+1]
                if point.y >= colors.zeroLevel && nextPoint.y < colors.zeroLevel || point.y < colors.zeroLevel && nextPoint.y >= colors.zeroLevel {
                    // The segment intersects zeroLevel, close the segment with the intersection point
                    let closingPoint = ChartSeries.intersectionWithLevel(point, and: nextPoint, level: colors.zeroLevel)
                    segment.append(closingPoint)
                    segments.append(ChartSegment(data: segment))
                    // Start a new segment
                    segment = [closingPoint]
                }
            } else {
                // End of the line
                segments.append(ChartSegment(data: segment))
            }
        }
    }

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
    
    private var segments: [ChartSegment] = []
    
    private var layers: [CAShapeLayer] = []

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
    ) = (above: ChartColors.blueColor(), below: ChartColors.redColor(), 0)

    public init(_ data: [Double]) {
        self.data = data.enumerated().map { (x: Double($0.offset), y: $0.element) }
    }

    public init(data: [(x: Double, y: Double)]) {
        self.data = data
        updateSegments()
    }

    public init(data: [(x: Int, y: Double)]) {
      self.data = data.map { (Double($0.x), Double($0.y)) }
        updateSegments()
    }
    
    public init(data: [(x: Float, y: Float)]) {
        self.data = data.map { (Double($0.x), Double($0.y)) }
        updateSegments()
    }
    
    func append(point: ChartPoint) {
        data.append(point)
        updateSegments()
    }
    
    func createLayers(for chart: Chart) -> [CAShapeLayer] {
        layers = []
        for segment in segments {
            if line {
                layers.append(segment.getLineLayer(width: lineWidth ?? chart.lineWidth, with: colors, for: chart))
            }
            if area {
                layers.append(segment.getAreaLayer(with: colors, for: chart))
            }
        }
        
        return layers
    }

}
