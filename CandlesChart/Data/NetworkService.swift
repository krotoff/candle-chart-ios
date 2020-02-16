//
//  NetworkService.swift
//  CandlesChart
//
//  Created by Andrew Krotov on 16.02.2020.
//  Copyright © 2020 Andrew Krotov. All rights reserved.
//

import Foundation
import Starscream
import SocketIO

protocol NetworkServiceType {
    func connect(with updateCompletion: (([Tick]) -> Void)?)
    func disconnect()
}

final class NetworkService {
    
    // MARK: - Private properties
    
    private var _receivedUpdatedData: (([Tick]) -> Void)?
    private var _ticks = [Tick]()
}

extension NetworkService: NetworkServiceType {
    
    // MARK: - NetworkServiceType methods
    
    func connect(with updateCompletion: (([Tick]) -> Void)?) {
        _receivedUpdatedData = updateCompletion
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] (timer) in
            self.receivedUpdatedData(ticks: self.generateRandomTicks())
        }
        timer.fire()
    }
    
    func disconnect() {
        
    }
    
    func receivedUpdatedData(ticks: [Tick]) {
        _receivedUpdatedData?(ticks)
    }
    
    // MARK: - Mocks
    
    func generateRandomTicks() -> [Tick] {
        var result: [Tick] = []
        for i in 0..<1 {
            let aValue: Int
            let bValue: Int
            if i == 0 {
                if let lastTick = _ticks.last {
                    let aDifference = (arc4random() % 50)
                    aValue = abs(Int(lastTick.bFloat) + Int(aDifference) - 25)
                } else {
                    aValue = abs(Int((arc4random() % 4000) + 1000))
                }
                let difference = (arc4random() % 200)
                bValue = abs(Int(aValue) + Int(difference) - 100)
            } else {
                let aDifference = (arc4random() % 50)
                aValue = abs(Int(result[i - 1].bFloat) + Int(aDifference) - 25)
                let bDifference = (arc4random() % 200)
                bValue = abs(Int(aValue) + Int(bDifference) - 100)
            }
            
            let tick = Tick(s: "BTCUSD", bf: "", af: "", spr: "", b: String(bValue), a: String(aValue))
            result.append(tick)
            _ticks.append(tick)
        }
        return result
    }
}
