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
                    model.fillTexts(symbolLabel, priceLabel)
                    variationTable.reloadData()
                    fillGraph()
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
        guard var cell = tableView.dequeueReusableCell(withIdentifier: "variationCell", for: indexPath) as? TableViewCell
        else {
            return UITableViewCell()
        }
        model.fillCell(cell: &cell, indexPath: indexPath)
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
        let points = model.fillPoints(quantity: numberOfRecords, min: &minY, max: &maxY)
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
