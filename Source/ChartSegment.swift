import UIKit

final class ChartSegment {
    var data: [ChartPoint]
    var lineLayer: CAShapeLayer?
    var areaLayer: CAShapeLayer?

    init(data: [ChartPoint]) {
        self.data = data
    }
    
    func getLineLayer(width: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), for chart: Chart) -> CAShapeLayer {
        self.lineLayer = drawLine(width: width, with: colors, on: chart)
        return lineLayer!
    }
    
    func getAreaLayer(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), for chart: Chart) -> CAShapeLayer {
        self.areaLayer = drawArea(with: colors, on: chart)
        return areaLayer!
    }
    
    private func drawLine(width: CGFloat, with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) -> CAShapeLayer {
        let xValues = chart.scaleValuesOnXAxis( data.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( data.map { $0.y } )

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
        lineLayer.lineWidth = width
        lineLayer.lineJoin = CAShapeLayerLineJoin.bevel
        
        return lineLayer
    }

    private func drawArea(with colors: (above: UIColor, below: UIColor, zeroLevel: Double), on chart: Chart) -> CAShapeLayer {
        let xValues = chart.scaleValuesOnXAxis( data.map { $0.x } )
        let yValues = chart.scaleValuesOnYAxis( data.map { $0.y } )

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
