//
//  NetworkService.swift
//  CandlesChart
//
//  Created by Andrew Krotov on 16.02.2020.
//  Copyright © 2020 Andrew Krotov. All rights reserved.
//

import Foundation
import Starscream

protocol NetworkServiceType {
    func connect(with updateCompletion: (([Candle]) -> Void)?)
    func disconnect()
}

final class NetworkService {
    
    // MARK: - Private properties
    
    private var _receivedUpdatedData: (([Candle]) -> Void)?
    private var _receivedNewTicks: (([Tick]) -> Void)?
    private var _candles = [Candle]()
    private let _socket: WebSocket
    private var _timer: Timer?
    
    // MARK: - Initialization
    
    init() {
        var urlComponents = URLComponents()
        urlComponents.scheme = "wss"
        urlComponents.host = "quotes.eccalls.mobi"
        urlComponents.port = 18400
        
        class Pinner: CertificatePinning {
            func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
                completion(.success)
            }
        }
        
        _socket = WebSocket(request: URLRequest(url: urlComponents.url!), certPinner: Pinner())
        _socket.delegate = self
    }
}

extension NetworkService: NetworkServiceType {
    
    // MARK: - NetworkServiceType methods
    
    func connect(with updateCompletion: (([Candle]) -> Void)?) {
        _receivedUpdatedData = updateCompletion
        
        _socket.connect()
        // FOR MOCKS
//        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] (timer) in
//            self.receivedUpdatedData(candles: self.generateRandomCandles())
//        }
//        timer.fire()
    }
    
    func disconnect() {
        _socket.write(string: "UNSUBSCRIBE: BTCUSD")
        _socket.disconnect()
    }
    
    func receivedUpdatedData(candles: [Candle]) {
        _receivedUpdatedData?(candles)
    }
    
    private func wasSubscribed() {
        _timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [unowned self] (timer) in
            self.receivedUpdatedData(candles: self._candles.filter { !$0.ticks.isEmpty })
            self._candles.append(Candle(ticks: []))
            if self._candles.count > 1 {
                self._candles[self._candles.count - 2].ticks.last.map { self._candles[self._candles.count - 1].ticks.append($0) }
            }
            self._receivedNewTicks = { [weak self] ticks in
                guard let `self` = self, !self._candles.isEmpty else { return }
                
                DispatchQueue.main.async {
                    self._candles[self._candles.count - 1].ticks.append(contentsOf: ticks)
                }
            }
        }
        _timer?.fire()
    }
    
    // MARK: - Mocks
    
    private func generateRandomCandles() -> [Candle] {
        var ticks: [Tick] = []
        for i in 0..<10 {
            let aValue: Int
            if i == 0 {
                if let lastCandle = _candles.last {
                    aValue = Int(lastCandle.closeValue)
                } else {
                    aValue = abs(Int((arc4random() % 4000) + 1000))
                }
            } else {
                let aDifference = (arc4random() % 200)
                aValue = abs(Int(ticks[i - 1].aFloat) + Int(aDifference) - 100)
            }
            
            let tick = Tick(s: "BTCUSD", bf: 0, af: 0, spr: "", b: "", a: String(aValue))
            ticks.append(tick)
        }
        
        _candles.append(Candle(ticks: ticks))
        return _candles
    }
}

extension NetworkService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        struct TickBox: Codable {
            let ticks: [Tick]?
        }
        
        struct SubscriptionInfo: Codable {
            let subscribed_count: Int?
        }
        
        switch event {
        case .text(let string):
            if let subsInfo = try? JSONDecoder().decode(SubscriptionInfo.self, from: string.data(using: .utf8)!),
                (subsInfo.subscribed_count ?? 0) > 0 {
                wasSubscribed()
            }
            if let tickBox = try? JSONDecoder().decode(TickBox.self, from: string.data(using: .utf8)!),
                let ticks = tickBox.ticks {
                _receivedNewTicks?(ticks)
            }
        case .connected:
            _socket.write(string: "SUBSCRIBE: BTCUSD") { [weak self] in self?.wasSubscribed() }
        case .cancelled:
            _socket.connect()
        default:
            print(event)
        }
    }
}
