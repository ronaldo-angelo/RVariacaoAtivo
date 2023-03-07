//
//  Result.swift
//  RVariacaoAtivo
//
//  Created by Ronaldo on 05/03/23.
//

struct Result: Decodable {
    var meta: Meta
    var timestamp: [Double]?
    var indicators: Indicators?
}
