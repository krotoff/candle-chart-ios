//
//  Candle.swift
//  CandlesChart
//
//  Created by Andrew Krotov on 18.02.2020.
//  Copyright © 2020 Andrew Krotov. All rights reserved.
//

// e.g. for "a" parameter
struct Candle {
    var ticks: [Tick]
    
    var openValue: Float { ticks.first?.aFloat ?? 0 }
    var closeValue: Float { ticks.last?.aFloat ?? 0 }
    var minValue: Float { ticks.sorted { $0.aFloat < $1.aFloat }.first?.aFloat ?? Float.infinity }
    var maxValue: Float { ticks.sorted { $0.aFloat > $1.aFloat }.first?.aFloat ?? 0 }
}
