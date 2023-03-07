//
//  Quote.swift
//  RVariacaoAtivo
//
//  Created by Ronaldo on 05/03/23.
//

struct Quote: Decodable {
    var low: [Double]
    var volume: [Int]
    var open: [Double]
    var high: [Double]
    var close: [Double]
}
