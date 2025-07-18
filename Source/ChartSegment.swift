import UIKit

final class ChartSegment {
    let isAboveZeroLine: Bool
    var data: [ChartPoint]
    var lineLayer: CAShapeLayer?
    var areaLayer: CAShapeLayer?

    init(data: [ChartPoint], isAboveZeroLine: Bool) {
        self.isAboveZeroLine = isAboveZeroLine
        self.data = data
    }
    
    func createLineLayer(lineWidth: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), for chart: Chart) -> CAShapeLayer {
        lineLayer = CAShapeLayer()
        lineLayer?.fillColor = nil
        lineLayer?.lineJoin = CAShapeLayerLineJoin.bevel
        setLinePathAndColor(lineWidth: lineWidth, with: colors, on: chart)
        return lineLayer!
    }
    
    func createAreaLayer(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), for chart: Chart) -> CAShapeLayer {
        areaLayer = CAShapeLayer()
        areaLayer?.strokeColor = nil
        areaLayer?.lineWidth = 0
        setAreaPathAndColor(with: colors, on: chart)
        return areaLayer!
    }
    
    func redraw(lineWidth: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        if lineLayer != nil {
            setLinePathAndColor(lineWidth: lineWidth, with: colors, on: chart)
        }
        if areaLayer != nil {
            setAreaPathAndColor(with: colors, on: chart)
        }
    }
    
    func removeFromSuperlayer() {
        lineLayer?.removeFromSuperlayer()
        areaLayer?.removeFromSuperlayer()
    }
    
    private func setLinePathAndColor(lineWidth: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        let xValues = chart.scaleValuesOnXAxis( data.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( data.map { $0.y } )
        let path = CGMutablePath()
        path.move(to: CGPoint(x: CGFloat(xValues.first!), y: CGFloat(yValues.first!)))
        for i in 1..<yValues.count {
            let y = yValues[i]
            path.addLine(to: CGPoint(x: CGFloat(xValues[i]), y: CGFloat(y)))
        }
        lineLayer?.lineWidth = lineWidth
        lineLayer?.frame = chart.bounds
        lineLayer?.path = path
        lineLayer?.strokeColor = (isAboveZeroLine ? colors.above : colors.below).cgColor
    }
    
    private func setAreaPathAndColor(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) {
        let xValues = chart.scaleValuesOnXAxis( data.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( data.map { $0.y } )
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
}
