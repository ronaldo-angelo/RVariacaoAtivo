//
//  ViewModel.swift
//  RVariacaoAtivo
//
//  Created by Ronaldo on 04/03/23.
//

import Foundation
import UIKit
import SwiftGraphKit

class ViewModel {
    // MARK: - Variables
    private var isFetching = false
    private(set) var chart: Chart?
    private let timeIntervalNow = Date().timeIntervalSince1970
    
    // MARK: - Methods
    private func fetch(completion: @escaping (Asset?) -> Void) {
        
        if isFetching {
            return
        }
        isFetching = true
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let intervalDate = Calendar.current.date(byAdding: .month, value: -2, to: startDate)!

        let startAsEpoch = Int(startDate.timeIntervalSince1970)
        let intervalAsEpoch = Int(intervalDate.timeIntervalSince1970)

        var request = URLRequest(url: URL(string: "https://query2.finance.yahoo.com/v8/finance/chart/AAPL?period1=\(intervalAsEpoch)&period2=\(startAsEpoch)&interval=1d")!)
        request.httpMethod = "GET"
        request.addValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            
            if let data = data {
                do {
                    var json = try JSONDecoder().decode(Asset.self, from: data)
                    if let timestamp = json.chart.result[0].timestamp {
                        json.chart.result[0].timestamp = timestamp.reversed()
                    }
                    completion(json)
                } catch {
                    debugPrint(error)
                    completion(nil)
                }
            }
            else {
                completion(nil)
            }
            self.isFetching = false
        })
        
        task.resume()
    }
    
    func fetchData(completion: ((Bool) -> Void)? = nil) {
        fetch() { [weak self] result in
            if let result = result {
                self?.chart = result.chart
                completion?(true)
            }
            else {
                completion?(false)
            }
        }
        
    }
    
    func fillTexts(_ symbolLabel: UILabel, _ priceLabel: UILabel) {
        if let result = chart?.result[0] {
            symbolLabel.text = result.meta.symbol
            priceLabel.text = String(format: "\(result.meta.currency) $%.2f", result.meta.regularMarketPrice)
        }
    }
    
    func fillCell(cell: inout TableViewCell, indexPath: IndexPath) {
        if let result = chart?.result[0] {
            if let timestamp = result.timestamp {
                let date = Date(timeIntervalSince1970: TimeInterval(floatLiteral: timestamp[indexPath.row]))
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale.current
                cell.dateLabel.text = dateFormatter.string(from: date)
            }
            
            if let indicators = result.indicators, indicators.quote.count > 0 {
                let openValues:[Double] = indicators.quote[0].open.reversed()
                let openValue = openValues[indexPath.row]
                
                cell.valueLabel.text = String(format: "$%.2f", openValue)
                cell.variationLabel.text = indexPath.row - 1 >= 0 ? calculatePercentages(value1: openValues[indexPath.row], value2: openValues[indexPath.row - 1]) : "-"
                cell.variationFirstLabel.text = calculatePercentages(value1: openValues[indexPath.row], value2: openValues[29])
            }
            
            cell.dateLabel.sizeToFit()
            cell.valueLabel.sizeToFit()
            cell.variationLabel.sizeToFit()
            cell.variationFirstLabel.sizeToFit()
        }
    }
    
    func fillPoints(quantity: Int, min: inout Double, max: inout Double) -> [GraphPoint] {
        var points = [GraphPoint]()
        if let result = chart?.result[0],
            let closeValues = result.indicators?.quote[0].open,
            closeValues.count > quantity {
            let values = Array(closeValues[closeValues.count - quantity ..< closeValues.count])
            
            min = values.min() ?? min
            max = values.max() ?? max
            
            for index in 0 ..< quantity {
                let roundedPoint = RoundedPoint(x: CGFloat(index), y: CGFloat(values[index]))
                roundedPoint.fillColor = .white
                roundedPoint.strokeColor = .black
                roundedPoint.selected = false
                points.append(roundedPoint)
            }
        }
        return points
    }
    
    func calculatePercentages(value1: Double, value2: Double) -> String {
        let percentValue = ((value1 - value2) * 100) / value2
        return String(format: "%.1f%%", percentValue)
    }
}
