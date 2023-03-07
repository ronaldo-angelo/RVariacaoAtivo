//
//  ViewModel.swift
//  RVariacaoAtivo
//
//  Created by Ronaldo on 04/03/23.
//

import Foundation

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
}
