import UIKit

final class ChartSegment {
    var data: [ChartPoint]
    var lineLayer: CAShapeLayer?
    var areaLayer: CAShapeLayer?

    init(data: [ChartPoint]) {
        self.data = data
    }
    
    func getLineLayer(width: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), for chart: Chart) -> CAShapeLayer {
        drawLine(width: width, with: colors, on: chart)
        return lineLayer!
    }
    
    func getAreaLayer(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), for chart: Chart) -> CAShapeLayer {
        drawArea(with: colors, on: chart)
        return areaLayer!
    }
    
    func redraw(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        if lineLayer != nil {
            setLinePathAndColor(with: colors, on: chart)
        }
        if areaLayer != nil {
            setAreaPathAndColor(with: colors, on: chart)
        }
    }
    
    private func setLinePathAndColor(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        let xValues = chart.scaleValuesOnXAxis( data.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( data.map { $0.y } )
        let isAboveZeroLine = yValues.max()! <= chart.scaleValueOnYAxis(colors.zeroLevel)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: CGFloat(xValues.first!), y: CGFloat(yValues.first!)))
        for i in 1..<yValues.count {
            let y = yValues[i]
            path.addLine(to: CGPoint(x: CGFloat(xValues[i]), y: CGFloat(y)))
        }
        lineLayer?.frame = chart.bounds
        lineLayer?.path = path
        lineLayer?.strokeColor = (isAboveZeroLine ? colors.above : colors.below).cgColor
    }
    
    private func setAreaPathAndColor(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        let xValues = chart.scaleValuesOnXAxis( data.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( data.map { $0.y } )
        let isAboveZeroLine = yValues.max()! <= chart.scaleValueOnYAxis(colors.zeroLevel)
        let area = CGMutablePath()
        let zero = CGFloat(chart.getZeroValueOnYAxis(zeroLevel: colors.zeroLevel))

        area.move(to: CGPoint(x: CGFloat(xValues[0]), y: zero))
        for i in 0..<xValues.count {
            area.addLine(to: CGPoint(x: CGFloat(xValues[i]), y: CGFloat(yValues[i])))
        }
        area.addLine(to: CGPoint(x: CGFloat(xValues.last!), y: zero))
        lineLayer?.frame = chart.bounds
        lineLayer?.path = area
        lineLayer?.fillColor = (isAboveZeroLine ? colors.above : colors.below).withAlphaComponent(chart.areaAlphaComponent).cgColor
    }
    
    private func drawLine(width: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        lineLayer = CAShapeLayer()
        lineLayer?.fillColor = nil
        lineLayer?.lineWidth = width
        lineLayer?.lineJoin = CAShapeLayerLineJoin.bevel
        setLinePathAndColor(with: colors, on: chart)
    }

    private func drawArea(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        areaLayer = CAShapeLayer()
        areaLayer?.strokeColor = nil
        areaLayer?.lineWidth = 0
        setAreaPathAndColor(with: colors, on: chart)
    }
}
