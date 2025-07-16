//
//  Chart.swift
//
//  Created by Giampaolo Bellavite on 07/11/14.
//  Copyright (c) 2014 Giampaolo Bellavite. All rights reserved.
//

import UIKit

public protocol ChartDelegate: AnyObject {

    /**
    Tells the delegate that the specified chart has been touched.

    - parameter chart: The chart that has been touched.
    - parameter indexes: Each element of this array contains the index of the data that has been touched, one for each 
      series. If the series hasn't been touched, its index will be nil.
    - parameter x: The value on the x-axis that has been touched.
    - parameter left: The distance from the left side of the chart.

    */
    func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat)

    /**
    Tells the delegate that the user finished touching the chart. The user will 
    "finish" touching the chart only swiping left/right outside the chart.

    - parameter chart: The chart that has been touched.

    */
    func didFinishTouchingChart(_ chart: Chart)
    /**
     Tells the delegate that the user ended touching the chart. The user 
     will "end" touching the chart whenever the touchesDidEnd method is 
     being called.
     
     - parameter chart: The chart that has been touched.
     
     */
    func didEndTouchingChart(_ chart: Chart)
}

/**
Represent the x- and the y-axis values for each point in a chart series.
*/
public typealias ChartPoint = (x: Double, y: Double)

/**
Set the a x-label orientation.
*/
public enum ChartLabelOrientation {
    case horizontal
    case vertical
}

@IBDesignable
open class Chart: UIView {

    // MARK: Options

    @IBInspectable
    public var identifier: String?

    /**
    Series to display in the chart.
    */
    public var series: [ChartSeries] = [] {
      didSet {
        recalcMinMax()
      }
    }

    /**
    The values to display as labels on the x-axis. You can format these values  with the `xLabelFormatter` attribute. 
    As default, it will display the values of the series which has the most data.
    */
    public var xLabels: [Double]?

    /**
    Formatter for the labels on the x-axis. `index` represents the `xLabels` index, `value` its value.
    */
    public var xLabelsFormatter = { (labelIndex: Int, labelValue: Double) -> String in
        String(Int(labelValue))
    }

    /**
    Text alignment for the x-labels.
    */
    public var xLabelsTextAlignment: NSTextAlignment = .left

    /**
    Orientation for the x-labels.
    */
    public var xLabelsOrientation: ChartLabelOrientation = .horizontal

    /**
    Skip the last x-label. Setting this to false may make the label overflow the frame width.
    */
    public var xLabelsSkipLast: Bool = true

    /**
    Values to display as labels of the y-axis. If not specified, will display the lowest, the middle and the highest
    values.
    */
    public var yLabels: [Double]?

    /**
    Formatter for the labels on the y-axis.
    */
    public var yLabelsFormatter = { (labelIndex: Int, labelValue: Double) -> String in
        String(Int(labelValue))
    }

    /**
    Displays the y-axis labels on the right side of the chart.
    */
    public var yLabelsOnRightSide: Bool = false

    /**
    Font used for the labels.
    */
    public var labelFont: UIFont = UIFont.systemFont(ofSize: 12)

    /**
    The color used for the labels.
    */
    @IBInspectable
    public var labelColor: UIColor = UIColor.black

    /**
    Color for the axes.
    */
    @IBInspectable
    public var axesColor: UIColor = UIColor.gray.withAlphaComponent(0.3)

    /**
    Color for the grid.
    */
    @IBInspectable
    public var gridColor: UIColor = UIColor.gray.withAlphaComponent(0.3)
    /**
    Enable the lines for the labels on the x-axis
    */
    public var showXLabelsAndGrid: Bool = true
    /**
    Enable the lines for the labels on the y-axis
    */
    public var showYLabelsAndGrid: Bool = true

    /**
    Height of the area at the bottom of the chart, containing the labels for the x-axis.
    */
    public var bottomInset: CGFloat = 20

    /**
    Height of the area at the top of the chart, acting a padding to make place for the top y-axis label.
    */
    public var topInset: CGFloat = 20

    /**
    Width of the chart's lines.
    */
    @IBInspectable
    public var lineWidth: CGFloat = 2

    /**
    Delegate for listening to Chart touch events.
    */
    weak public var delegate: ChartDelegate?

    /**
    Custom minimum value for the x-axis.
    */
    public var minX: Double? {
        didSet {
            if let minX {
                min.x = Swift.min(min.x, minX)
            }
        }
    }

    /**
    Custom minimum value for the y-axis.
    */
    public var minY: Double? {
        didSet {
            if let minY {
                min.y = Swift.min(min.y, minY)
            }
        }
    }

    /**
    Custom maximum value for the x-axis.
    */
    public var maxX: Double? {
        didSet {
            if let maxX {
                max.x = Swift.max(max.x, maxX)
            }
        }
    }

    /**
    Custom maximum value for the y-axis.
    */
    public var maxY: Double? {
        didSet {
            if let maxY {
                max.y = Swift.max(max.y, maxY)
            }
        }
    }

    /**
    Color for the highlight line.
    */
    public var highlightLineColor = UIColor.gray

    /**
    Width for the highlight line.
    */
    public var highlightLineWidth: CGFloat = 0.5

    /**
    Hide the highlight line when touch event ends, e.g. when stop swiping over the chart
    */
    public var hideHighlightLineOnTouchEnd = false

    /**
    Alpha component for the area color.
    */
    public var areaAlphaComponent: CGFloat = 0.1

    // MARK: Private variables

    private var highlightShapeLayer: CAShapeLayer!

    private var drawingHeight: CGFloat!
    private var drawingWidth: CGFloat!

    // Minimum and maximum values represented in the chart
    private var min: ChartPoint = (x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
    private var max: ChartPoint = (x: -CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude)

    // Represent a set of points corresponding to a segment line on the chart.
    typealias ChartLineSegment = [ChartPoint]

    // MARK: initializations

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    convenience public init() {
        self.init(frame: .zero)
    }

    private func commonInit() {
        //backgroundColor = UIColor.clear // オリジナルで強制的にclearしているが、storyboardの初期化を使うためコメントアウト
        contentMode = .redraw // redraw rects on bounds change
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        drawChart()
    }

    /**
    Adds a chart series.
    */
    open func add(_ series: ChartSeries) {
        self.series.append(series)
        updateMinMax(by: series)
    }

    /**
    Adds multiple chart series.
    */
    open func add(_ series: [ChartSeries]) {
        for s in series {
            add(s)
        }
    }

    /**
    Remove the series at the specified index.
    */
    open func removeSeriesAt(_ index: Int) {
        series.remove(at: index)
        min = (x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
        max = (x: -CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude)
    }

    /**
    Remove all the series.
    */
    open func removeAllSeries() {
        series = []
    }

    /**
    Return the value for the specified series at the given index.
    */
    open func valueForSeries(_ seriesIndex: Int, atIndex dataIndex: Int?) -> Double? {
        if dataIndex == nil { return nil }
        let series = self.series[seriesIndex] as ChartSeries
        return series.data[dataIndex!].y
    }

    open func add(point: ChartPoint, to seriesIndex: Int) {
        let series = self.series[seriesIndex]
        series.append(point: point)
        updateMinMax(by: point)
    }

    override open func prepareForInterfaceBuilder() {
        let placeholder = UIView(frame: self.frame)
        placeholder.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
        let label = UILabel()
        label.text = "Chart"
        label.font = UIFont.systemFont(ofSize: 28)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        label.sizeToFit()
        label.frame.origin.x += frame.width/2 - (label.frame.width / 2)
        label.frame.origin.y += frame.height/2 - (label.frame.height / 2)
        
        placeholder.addSubview(label)
        addSubview(placeholder)
    }
    
    private func drawChart() {

        drawingHeight = bounds.height - bottomInset - topInset
        drawingWidth = bounds.width
        
        highlightShapeLayer = nil

        // Remove things before drawing, e.g. when changing orientation

        for layer in layer.sublayers ?? [] {
            layer.removeFromSuperlayer()
        }

        // Draw content

        for series in self.series {
            for layer in series.createLayers(for: self) {
                self.layer.addSublayer(layer)
            }
        }

        drawAxes()

        if showXLabelsAndGrid && (xLabels != nil || series.count > 0) {
            drawLabelsAndGridOnXAxis()
        }
        if showYLabelsAndGrid && (yLabels != nil || series.count > 0) {
            drawLabelsAndGridOnYAxis()
        }
    }

    // MARK: - Scaling

    private func updateMinMax(by point: ChartPoint) {
        if point.x < min.x { min.x = point.x }
        if point.y < min.y { min.y = point.y }
        if point.x > max.x { max.x = point.x }
        if point.y > max.y { max.y = point.y }
    }

    private func updateMinMax(by series: ChartSeries) {
        let xValues =  series.data.map { $0.x }
        let yValues =  series.data.map { $0.y }

        let newMinX = xValues.minOrZero()
        let newMinY = yValues.minOrZero()
        let newMaxX = xValues.maxOrZero()
        let newMaxY = yValues.maxOrZero()

        if newMinX < min.x { min.x = newMinX }
        if newMinY < min.y { min.y = newMinY }
        if newMaxX > max.x { max.x = newMaxX }
        if newMaxY > max.y { max.y = newMaxY }
    }

    private func recalcMinMax() {
        // Start with user-provided values

        min = (x: minX ?? CGFloat.greatestFiniteMagnitude, y: minY ?? CGFloat.greatestFiniteMagnitude)
        max = (x: maxX ?? -CGFloat.greatestFiniteMagnitude, y: maxY ?? -CGFloat.greatestFiniteMagnitude)

        // Check in datasets

        for series in self.series {
            if series.data.count == 0 {
                continue
            }
            let xValues =  series.data.map { $0.x }
            let yValues =  series.data.map { $0.y }

            min.x = Swift.min(min.x, xValues.min()!)
            min.y = Swift.min(min.y, yValues.min()!)
            max.x = Swift.max(max.x, xValues.max()!)
            max.y = Swift.max(max.y, yValues.max()!)
        }

        // Check in labels

        if let xLabels = self.xLabels, xLabels.count > 0 {
            min.x = Swift.min(min.x, xLabels.min()!)
            max.x = Swift.max(max.x, xLabels.max()!)
        }

        if let yLabels = self.yLabels, yLabels.count > 0 {
            min.y = Swift.min(min.y, yLabels.min()!)
            max.y = Swift.max(max.y, yLabels.max()!)
        }
    }

    func scaleValuesOnXAxis(_ values: [Double]) -> [Double] {
        let width = Double(drawingWidth)

        var factor: Double
        if max.x - min.x == 0 {
            factor = 0
        } else {
            factor = width / (max.x - min.x)
        }

        let scaled = values.map { factor * ($0 - self.min.x) }
        return scaled
    }

    func scaleValuesOnYAxis(_ values: [Double]) -> [Double] {
        let height = Double(drawingHeight)
        var factor: Double
        if max.y - min.y == 0 {
            factor = 0
        } else {
            factor = height / (max.y - min.y)
        }

        let scaled = values.map { Double(self.topInset) + height - factor * ($0 - self.min.y) }

        return scaled
    }

    public func scaleValueOnXAxis(_ value: Double) -> Double {
        let width = Double(drawingWidth)
        var factor: Double
        if max.x - min.x == 0 {
            factor = 0
        } else {
            factor = width / (max.x - min.x)
        }

        let scaled = factor * (value - min.x)
        return scaled
    }

    public func scaleValueOnYAxis(_ value: Double) -> Double {
        let height = Double(drawingHeight)
        var factor: Double
        if max.y - min.y == 0 {
            factor = 0
        } else {
            factor = height / (max.y - min.y)
        }

        let scaled = Double(self.topInset) + height - factor * (value - min.y)
        return scaled
    }

    func getZeroValueOnYAxis(zeroLevel: Double) -> Double {
        if min.y > zeroLevel {
            return scaleValueOnYAxis(min.y)
        } else {
            return scaleValueOnYAxis(zeroLevel)
        }
    }

    // MARK: - Drawings

    private func drawAxes() {
        let path = CGMutablePath()

        // horizontal axis at the bottom
        path.move(to: CGPoint(x: CGFloat(0), y: drawingHeight + topInset))
        path.addLine(to: CGPoint(x: CGFloat(drawingWidth), y: drawingHeight + topInset))

        // horizontal axis at the top
        path.move(to: CGPoint(x: CGFloat(0), y: CGFloat(0)))
        path.addLine(to: CGPoint(x: CGFloat(drawingWidth), y: CGFloat(0)))

        // horizontal axis when y = 0
        if min.y < 0 && max.y > 0 {
            let y = CGFloat(getZeroValueOnYAxis(zeroLevel: 0))
            path.move(to: CGPoint(x: CGFloat(0), y: y))
            path.addLine(to: CGPoint(x: CGFloat(drawingWidth), y: y))
        }

        // vertical axis on the left
        path.move(to: CGPoint(x: CGFloat(0), y: CGFloat(0)))
        path.addLine(to: CGPoint(x: CGFloat(0), y: drawingHeight + topInset))

        // vertical axis on the right
        path.move(to: CGPoint(x: CGFloat(drawingWidth), y: CGFloat(0)))
        path.addLine(to: CGPoint(x: CGFloat(drawingWidth), y: drawingHeight + topInset))
        
        let axesLayer = CAShapeLayer()
        axesLayer.frame = self.bounds
        axesLayer.path = path
        axesLayer.strokeColor = axesColor.cgColor
        axesLayer.lineWidth = 0.5

        layer.addSublayer(axesLayer)
    }

    private func drawLabelsAndGridOnXAxis() {
        let path = CGMutablePath()

        var labels: [Double]
        if xLabels == nil {
            // Use labels from the first series
            labels = series[0].data.map({ (point: ChartPoint) -> Double in
                return point.x })
        } else {
            labels = xLabels!
        }

        let scaled = scaleValuesOnXAxis(labels)
        let padding: CGFloat = 5
        for (i, value) in scaled.enumerated() {
            let x = CGFloat(value)
            let isLastLabel = x == drawingWidth

            // Add vertical grid for each label, except axes on the left and right

            if x != 0 && x != drawingWidth {
                path.move(to: CGPoint(x: x, y: CGFloat(0)))
                path.addLine(to: CGPoint(x: x, y: bounds.height))
            }

            if xLabelsSkipLast && isLastLabel {
                // Do not add label at the most right position
                return
            }

            let text = xLabelsFormatter(i, labels[i])
            let font = labelFont
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let size = (text as NSString).size(withAttributes: attributes)

            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.font = font
            textLayer.fontSize = font.pointSize
            textLayer.foregroundColor = labelColor.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.alignmentMode = {
                switch xLabelsTextAlignment {
                case .center: return .center
                case .left: return .left
                case .right: return .right
                default: return .left
                }
            }()

            var frame = CGRect(x: x, y: drawingHeight, width: size.width, height: size.height)

            // 共通: 垂直中央に
            frame.origin.y += topInset

            if xLabelsOrientation == .horizontal {
                // 左右にパディング
                frame.origin.y -= (size.height - bottomInset) / 2
                frame.origin.x += padding

                // 幅を明示的に制限し、改行せず切れることを防ぐなら isWrapped = false
                frame.size.width = (drawingWidth / CGFloat(labels.count)) - padding * 2
                textLayer.isWrapped = false
            } else {
                // 縦書き風に回転
                textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))

                // 垂直位置調整
                frame.origin.y += size.height / 2

                // 横位置をラベルに合わせて調整
                frame.origin.x = x
                if xLabelsTextAlignment == .center {
                    frame.origin.x += ((drawingWidth / CGFloat(labels.count)) / 2) - (size.width / 2)
                } else {
                    frame.origin.x += padding
                }
            }

            textLayer.frame = frame
            layer.addSublayer(textLayer)
        }
        let gridLayer = CAShapeLayer()
        gridLayer.frame = self.bounds
        gridLayer.path = path
        gridLayer.strokeColor = gridColor.cgColor
        gridLayer.lineWidth = 0.5

        layer.addSublayer(gridLayer)
    }

    private func drawLabelsAndGridOnYAxis() {
        let dashed = CGMutablePath()
        let solid = CGMutablePath()

        var labels: [Double]
        if yLabels == nil {
            labels = [(min.y + max.y) / 2, max.y]
            if yLabelsOnRightSide || min.y != 0 {
                labels.insert(min.y, at: 0)
            }
        } else {
            labels = yLabels!
        }

        let scaled = scaleValuesOnYAxis(labels)
        let padding: CGFloat = 5
        let zero = CGFloat(getZeroValueOnYAxis(zeroLevel: 0))

        for (i, value) in scaled.enumerated() {

            let y = CGFloat(value)

            // Add horizontal grid for each label, but not over axes
            if y != drawingHeight + topInset && y != zero {
                if labels[i] != 0 {
                    dashed.move(to: CGPoint(x: CGFloat(0), y: y))
                    dashed.addLine(to: CGPoint(x: self.bounds.width, y: y))
                } else {
                    solid.move(to: CGPoint(x: CGFloat(0), y: y))
                    solid.addLine(to: CGPoint(x: self.bounds.width, y: y))
                }
            }

            let text = yLabelsFormatter(i, labels[i])
            let font = labelFont
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let size = (text as NSString).size(withAttributes: attributes)

            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.font = font
            textLayer.fontSize = font.pointSize
            textLayer.foregroundColor = labelColor.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.alignmentMode = .left // デフォルト、必要に応じて変更可能
            textLayer.isWrapped = false

            // 初期X座標（左側のY軸用）
            var xPosition = padding

            // Y軸が右側にある場合
            if yLabelsOnRightSide {
                xPosition = drawingWidth - size.width - padding
            }

            // フレーム設定
            let frame = CGRect(x: xPosition,
                            y: y - size.height, // グリッド線の上に表示
                            width: size.width,
                            height: size.height)

            textLayer.frame = frame
            layer.addSublayer(textLayer)
        }

        let dashedLayer = CAShapeLayer()
        dashedLayer.frame = self.bounds
        dashedLayer.path = dashed
        dashedLayer.strokeColor = gridColor.cgColor
        dashedLayer.lineWidth = 0.5
        dashedLayer.lineDashPattern = [5]
        dashedLayer.lineDashPhase = 0

        layer.addSublayer(dashedLayer)

        let solidLayer = CAShapeLayer()
        solidLayer.frame = self.bounds
        solidLayer.path = solid
        solidLayer.strokeColor = gridColor.cgColor
        solidLayer.lineWidth = 0.5

        layer.addSublayer(solidLayer)
    }

    // MARK: - Touch events

    private func drawHighlightLineFromLeftPosition(_ left: CGFloat) {
        if let shapeLayer = highlightShapeLayer {
            // Use line already created
            let path = CGMutablePath()

            path.move(to: CGPoint(x: left, y: 0))
            path.addLine(to: CGPoint(x: left, y: drawingHeight + topInset))
            shapeLayer.path = path
        } else {
            // Create the line
            let path = CGMutablePath()

            path.move(to: CGPoint(x: left, y: CGFloat(0)))
            path.addLine(to: CGPoint(x: left, y: drawingHeight + topInset))
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = self.bounds
            shapeLayer.path = path
            shapeLayer.strokeColor = highlightLineColor.cgColor
            shapeLayer.fillColor = nil
            shapeLayer.lineWidth = highlightLineWidth

            highlightShapeLayer = shapeLayer
            layer.addSublayer(shapeLayer)
        }
    }

    func handleTouchEvents(_ touches: Set<UITouch>, event: UIEvent!) {
        let point = touches.first!
        let left = point.location(in: self).x
        let x = valueFromPointAtX(left)

        if left < 0 || left > (drawingWidth as CGFloat) {
            // Remove highlight line at the end of the touch event
            if let shapeLayer = highlightShapeLayer {
                shapeLayer.path = nil
            }
            delegate?.didFinishTouchingChart(self)
            return
        }

        drawHighlightLineFromLeftPosition(left)

        if delegate == nil {
            return
        }

        var indexes: [Int?] = []

        for series in self.series {
            var index: Int? = nil
            let xValues = series.data.map({ (point: ChartPoint) -> Double in
                return point.x })
            let closest = Chart.findClosestInValues(xValues, forValue: x)
            if closest.lowestIndex != nil && closest.highestIndex != nil {
                // Consider valid only values on the right
                index = closest.lowestIndex
            }
            indexes.append(index)
        }
        delegate!.didTouchChart(self, indexes: indexes, x: x, left: left)
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchEvents(touches, event: event)
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchEvents(touches, event: event)
        if self.hideHighlightLineOnTouchEnd {
            if let shapeLayer = highlightShapeLayer {
                shapeLayer.path = nil
            }
        }
        delegate?.didEndTouchingChart(self)
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchEvents(touches, event: event)
    }

    // MARK: - Utilities

    private func valueFromPointAtX(_ x: CGFloat) -> Double {
        let value = ((max.x-min.x) / Double(drawingWidth)) * Double(x) + min.x
        return value
    }

    private func valueFromPointAtY(_ y: CGFloat) -> Double {
        let value = ((max.y - min.y) / Double(drawingHeight)) * Double(y) + min.y
        return -value
    }

    private static func findClosestInValues(
        _ values: [Double],
        forValue value: Double
    ) -> (
            lowestValue: Double?,
            highestValue: Double?,
            lowestIndex: Int?,
            highestIndex: Int?
        ) {
        var lowestValue: Double?, highestValue: Double?, lowestIndex: Int?, highestIndex: Int?

        for (i, currentValue) in values.enumerated() {

            if currentValue <= value && (lowestValue == nil || lowestValue! < currentValue) {
                lowestValue = currentValue
                lowestIndex = i
            }
            if currentValue >= value && (highestValue == nil || highestValue! > currentValue) {
                highestValue = currentValue
                highestIndex = i
            }

        }
        return (
            lowestValue: lowestValue,
            highestValue: highestValue,
            lowestIndex: lowestIndex,
            highestIndex: highestIndex
        )
    }

}

extension Sequence where Element == Double {
    func minOrZero() -> Double {
        return self.min() ?? 0.0
    }
    func maxOrZero() -> Double {
        return self.max() ?? 0.0
    }
}
