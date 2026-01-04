//
//  DailyGoldPrice.swift
//  SmartInvest
//
//  Created by user on 31/12/2025.
//

import Foundation

// data structure for the daily gold price history
struct DailyGoldPrice: Decodable {
    let date: String
    let close_price: Double
}
