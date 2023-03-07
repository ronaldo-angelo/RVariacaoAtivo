//
//  Meta.swift
//  RVariacaoAtivo
//
//  Created by Ronaldo on 05/03/23.
//

struct Meta: Decodable {
    var currency: String
    var symbol: String
    var regularMarketPrice: Float
    var previousClose: Float?
}
