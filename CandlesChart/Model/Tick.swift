//
//  Tick.swift
//  CandlesChart
//
//  Created by Andrew Krotov on 16.02.2020.
//  Copyright © 2020 Andrew Krotov. All rights reserved.
//

import Foundation

struct Tick: Codable {
    let s: String
    let bf: String
    let af: String
    let spr: String
    private let b: String
    private let a: String
    
    var aFloat: Float { Float(a) ?? 0 }
    var bFloat: Float { Float(b) ?? 0 }
    var maxValue: Float { max(aFloat, bFloat) }
    var minValue: Float { min(aFloat, bFloat) }
    
    init(s: String, bf: String, af: String, spr: String, b: String, a: String) {
        self.s = s
        self.bf = bf
        self.af = af
        self.spr = spr
        self.b = b
        self.a = a
    }
}
