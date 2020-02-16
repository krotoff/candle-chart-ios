//
//  ViewController.swift
//  CandlesChart
//
//  Created by Andrew Krotov on 16.02.2020.
//  Copyright © 2020 Andrew Krotov. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    struct LayoutConstants {
        static let candleBodyWidth: CGFloat = 16
        static let candleShadowWidth: CGFloat = 2
        static let candleSpacing: CGFloat = 8
        static let availableScrollContentHeight: CGFloat = 0.8
    }
    
    struct ColorConstants {
        static let positiveCandle: UIColor = .green
        static let negativeCandle: UIColor = .red
        static let candleShadow: UIColor = .darkGray
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: - Private properties
    
    private let _mainLayer: CALayer = CALayer()
    private let _networkService: NetworkServiceType = NetworkService()
    private var _maxValue: Float = 0
    private var _minValue: Float = Float.infinity
    private var _ticks = [Tick]()
    private var _requiredContentWidth: CGFloat {
        return (LayoutConstants.candleSpacing + LayoutConstants.candleBodyWidth) * CGFloat(_ticks.count) + LayoutConstants.candleSpacing
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _networkService.connect(with: { [weak self] ticks in
            self?.receivedUpdatedData(ticks: ticks)
        })
        
        scrollView.layer.addSublayer(_mainLayer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateUIWithUpdatedData()
    }
    
    // MARK: - Private methods
    
    private func receivedUpdatedData(ticks: [Tick]) {
        for tick in ticks {
            _ticks.append(tick)
            if tick.maxValue > _maxValue {
                _maxValue = tick.maxValue
            }
            if tick.minValue < _minValue {
                _minValue = tick.minValue
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateUIWithUpdatedData()
        }
    }
    
    private func updateUIWithUpdatedData() {
        let scrollViewWidth = scrollView.frame.width
        let needToScroll = abs(scrollView.bounds.origin.x + scrollViewWidth - scrollView.contentSize.width) <= 10
            || scrollViewWidth > scrollView.contentSize.width
        
        _mainLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        
        scrollView.contentSize = CGSize(width: _requiredContentWidth, height: scrollView.frame.size.height)
        _mainLayer.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        _ticks.enumerated().forEach(showTick)
        
        guard needToScroll else { return }
        
        let rectToScroll = CGRect(x: scrollView.contentSize.width - scrollViewWidth, y: scrollView.frame.minY, width: scrollViewWidth, height: scrollView.frame.height)
        scrollView.scrollRectToVisible(rectToScroll, animated: true)
    }
    
    private func showTick(index: Int, tick: Tick) {
        let color = tick.bFloat > tick.aFloat ? ColorConstants.positiveCandle : ColorConstants.negativeCandle
        
        let chartHeightRatio = _maxValue - _minValue
        
        let availableHeight = scrollView.frame.height * LayoutConstants.availableScrollContentHeight
        
        let tickHeight = CGFloat((tick.maxValue - tick.minValue) / chartHeightRatio) * availableHeight
        
        let tickOriginY = CGFloat((_maxValue - tick.maxValue) / chartHeightRatio) * availableHeight
            + (view.frame.height - availableHeight) / 2.0
        let tickOriginX = CGFloat(index) * (LayoutConstants.candleSpacing + LayoutConstants.candleBodyWidth) + LayoutConstants.candleSpacing
        
        let frameForTick = CGRect(x: tickOriginX, y: tickOriginY, width: LayoutConstants.candleBodyWidth, height: tickHeight)
        
        _mainLayer.addRectangleLayer(frame: frameForTick, color: color.cgColor)
    }
}

extension CALayer {
    func addRectangleLayer(frame: CGRect, color: CGColor) {
        let layer = CALayer()
        layer.frame = frame
        layer.backgroundColor = color
        addSublayer(layer)
    }
}
