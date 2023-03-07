//
//  ViewController.swift
//  RVariacaoAtivo
//
//  Created by Ronaldo on 04/03/23.
//

import UIKit
import SwiftGraphKit

class ViewController: UIViewController {

    // MARK: - UI
    @IBOutlet weak var symbolLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var graphContainer: UIView!
    
    @IBOutlet weak var variationTable: UITableView!
    
    // MARK: - Model
    private var model = ViewModel()
    
    // MARK: - Variables
    private var minY = -100.0
    private var maxY = 100.0
    private let numberOfRecords = 30
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        model.fetchData { success in
            DispatchQueue.main.async { [self] in
                if success {
                    if let result = model.chart?.result[0] {
                        symbolLabel.text = result.meta.symbol
                        priceLabel.text = String(format: "\(result.meta.currency) $%.2f", result.meta.regularMarketPrice)
                        variationTable.reloadData()
                        fillGraph()
                    }
                }
                else {
                    let alert = UIAlertController(title: "Data not found", message: "Data not found, please try again at a later time.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRecords
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "variationCell", for: indexPath) as? TableViewCell
        else {
            return UITableViewCell()
        }
        
        if let result = model.chart?.result[0] {
            if let timestamp = result.timestamp {
                let date = Date(timeIntervalSince1970: TimeInterval(floatLiteral: timestamp[indexPath.row]))
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale.current
                cell.dateLabel.text = dateFormatter.string(from: date)
            }
            
            if let indicators = result.indicators {
                let closeValue = indicators.quote[0].close.reversed()[indexPath.row]
                let openValue = indicators.quote[0].open.reversed()[indexPath.row]
                cell.valueLabel.text = String(format: "$%.2f", openValue)
                cell.variationLabel.text = String(format: "$%.2f", (closeValue - openValue))
            }
            
            cell.dateLabel.sizeToFit()
            cell.valueLabel.sizeToFit()
            cell.variationLabel.sizeToFit()

        }
        return cell
    }
}

// MARK: - GraphView
extension ViewController {
    private func fillGraph() {
        // init GraphView
        let graphView = GraphView()
        graphView.translatesAutoresizingMaskIntoConstraints = false
        // graphView.allowsAutoresize = true
        graphContainer.addSubview(graphView)
        
        NSLayoutConstraint.activate([
            graphView.centerXAnchor.constraint(equalTo: graphContainer.centerXAnchor),
            graphView.centerYAnchor.constraint(equalTo: graphContainer.centerYAnchor),
            graphView.widthAnchor.constraint(equalTo: graphContainer.widthAnchor),
            graphView.heightAnchor.constraint(equalTo: graphContainer.heightAnchor)
        ])
        
        // init BezierGraph
        let graph = BezierGraph()
        graph.color = .darkGray
        graph.thickness = 3.0
        graphView.add(graph: graph)
        
        // add points
        var points = [GraphPoint]()
        if let closeValues = model.chart?.result[0].indicators?.quote[0].open, closeValues.count > numberOfRecords {
            let values = Array(closeValues[closeValues.count - numberOfRecords ..< closeValues.count])
            
            minY = values.min() ?? minY
            maxY = values.max() ?? maxY
            
            for index in 0 ..< numberOfRecords {
                let roundedPoint = RoundedPoint(x: CGFloat(index), y: CGFloat(values[index]))
                roundedPoint.fillColor = .white
                roundedPoint.strokeColor = .black
                roundedPoint.selected = false
                points.append(roundedPoint)
            }
        }
        graph.addData(data: points)
        
        let mod = maxY.truncatingRemainder(dividingBy: minY)
        let dataArea  = CGRect(x: -1.0, y: 20.0, width: 31.0, height: 10.0)
        let dataFrame = CGRect(x: -1.0, y: minY - mod, width: 9.0, height: mod * 3)
        graphView.configure(dataFrame: dataFrame, dataArea: dataArea)
        
        // decorate GraphView
        let grid = Grid(stepX: 1.0, stepY: mod)
        grid.color = .lightGray
        graphView.set(grid: grid)
        
        let verticalAxis = VerticalAxis(step: mod, position: .leftOutside)
        verticalAxis.axisDelegate = self
        graphView.set(verticalAxis: verticalAxis)
        
        let horizontalAxis = HorizontalAxis(step: 1, position: .bottomOutside)
        horizontalAxis.axisDelegate = self
        graphView.set(horizontalAxis: horizontalAxis)
    }
}

// MARK: - AxisDelegate
extension ViewController: AxisDelegate {
    func needStringValue(for axis: Axis, at index: CGFloat) -> String {
        return axis is VerticalAxis ? String(format: "%.2f", index) : String(format: "%1.0f", index + 1)
    }
}
