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
    typealias ChartLineSegment = [ChartPoint]

    /**
    Segment a line in multiple lines when the line touches the x-axis, i.e. separating
    positive from negative values.
    */
    private static func segmentLine(_ line: ChartLineSegment, zeroLevel: Double) -> [ChartLineSegment] {
        var segments: [ChartLineSegment] = []
        var segment: ChartLineSegment = []

        for (i, point) in line.enumerated() {
            segment.append(point)
            if i < line.count - 1 {
                let nextPoint = line[i+1]
                if point.y >= zeroLevel && nextPoint.y < zeroLevel || point.y < zeroLevel && nextPoint.y >= zeroLevel {
                    // The segment intersects zeroLevel, close the segment with the intersection point
                    let closingPoint = ChartSeries.intersectionWithLevel(point, and: nextPoint, level: zeroLevel)
                    segment.append(closingPoint)
                    segments.append(segment)
                    // Start a new segment
                    segment = [closingPoint]
                }
            } else {
                // End of the line
                segments.append(segment)
            }
        }
        return segments
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
    
    private var segments: [ChartLineSegment] = []
    
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
    
    func updateSegments() {
        // Separate each line in multiple segments over and below the x axis
        segments = ChartSeries.segmentLine(data as ChartLineSegment, zeroLevel: colors.zeroLevel)
    }
    
    func createLayers(for chart: Chart) -> [CAShapeLayer] {
        layers = []
        for segment in segments {
            if line {
                layers.append(drawLine(segment: segment, on: chart))
            }
            if area {
                layers.append(drawArea(segment: segment, on: chart))
            }
        }
        
        return layers
    }

    private func drawLine(segment: ChartLineSegment, on chart: Chart) -> CAShapeLayer {
        let xValues = chart.scaleValuesOnXAxis( segment.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( segment.map { $0.y } )

        // YValues are "reverted" from top to bottom, so 'above' means <= level
        let isAboveZeroLine = yValues.max()! <= chart.scaleValueOnYAxis(colors.zeroLevel)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: CGFloat(xValues.first!), y: CGFloat(yValues.first!)))
        for i in 1..<yValues.count {
            let y = yValues[i]
            path.addLine(to: CGPoint(x: CGFloat(xValues[i]), y: CGFloat(y)))
        }

        let lineLayer = CAShapeLayer()
        lineLayer.frame = chart.bounds
        lineLayer.path = path

        if isAboveZeroLine {
            lineLayer.strokeColor = colors.above.cgColor
        } else {
            lineLayer.strokeColor = colors.below.cgColor
        }
        lineLayer.fillColor = nil
        lineLayer.lineWidth = lineWidth ?? chart.lineWidth
        lineLayer.lineJoin = CAShapeLayerLineJoin.bevel

        return lineLayer
    }

    private func drawArea(segment: ChartLineSegment, on chart: Chart) -> CAShapeLayer {
        let xValues = chart.scaleValuesOnXAxis( segment.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( segment.map { $0.y } )

        // YValues are "reverted" from top to bottom, so 'above' means <= level
        let isAboveZeroLine = yValues.max()! <= chart.scaleValueOnYAxis(colors.zeroLevel)
        let area = CGMutablePath()
        let zero = CGFloat(chart.getZeroValueOnYAxis(zeroLevel: colors.zeroLevel))

        area.move(to: CGPoint(x: CGFloat(xValues[0]), y: zero))
        for i in 0..<xValues.count {
            area.addLine(to: CGPoint(x: CGFloat(xValues[i]), y: CGFloat(yValues[i])))
        }
        area.addLine(to: CGPoint(x: CGFloat(xValues.last!), y: zero))
        let areaLayer = CAShapeLayer()
        areaLayer.frame = chart.bounds
        areaLayer.path = area
        areaLayer.strokeColor = nil
        if isAboveZeroLine {
            areaLayer.fillColor = colors.above.withAlphaComponent(chart.areaAlphaComponent).cgColor
        } else {
            areaLayer.fillColor = colors.below.withAlphaComponent(chart.areaAlphaComponent).cgColor
        }
        areaLayer.lineWidth = 0

        return areaLayer
    }
}
