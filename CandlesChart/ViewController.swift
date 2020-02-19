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
        static let candleShadowWidth: CGFloat = 1
        static let candleSpacing: CGFloat = 8
        static let availableScrollContentHeight: CGFloat = 0.8
    }
    
    struct ColorConstants {
        static let positiveCandle: UIColor = .green
        static let negativeCandle: UIColor = .red
        static let candleShadow: UIColor = .lightGray
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: - Private properties
    
    private let _mainLayer: CALayer = CALayer()
    private let _networkService: NetworkServiceType = NetworkService()
    private var _maxValue: Float = 0
    private var _minValue: Float = Float.infinity
    private var _candles = [Candle]()
    private var _requiredContentWidth: CGFloat {
        return (LayoutConstants.candleSpacing + LayoutConstants.candleBodyWidth) * CGFloat(_candles.count) + LayoutConstants.candleSpacing
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _networkService.connect(with: { [weak self] candles in
            self?.receivedUpdatedData(candles: candles)
        })
        
        scrollView.layer.addSublayer(_mainLayer)
        scrollView.delegate = self
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateUIWithUpdatedData()
    }
    
    // MARK: - Private methods
    
    private func receivedUpdatedData(candles: [Candle]) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            self._candles = candles
            for candle in candles {
                if candle.maxValue > self._maxValue {
                    self._maxValue = candle.maxValue
                }
                if candle.minValue < self._minValue {
                    self._minValue = candle.minValue
                }
            }

            self.updateUIWithUpdatedData()
        }
    }
    
    private func updateUIWithUpdatedData() {
        let scrollViewWidth = scrollView.frame.width
        let needToScroll = abs(scrollView.bounds.origin.x + scrollViewWidth - scrollView.contentSize.width) <= 10
            || scrollViewWidth > scrollView.contentSize.width
        
        _mainLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        
        scrollView.contentSize = CGSize(width: _requiredContentWidth, height: scrollView.frame.size.height)
        _mainLayer.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        let availableHeight = scrollView.frame.height * LayoutConstants.availableScrollContentHeight
        let chartHeightRatio = availableHeight / CGFloat(_maxValue - _minValue)
        
        guard chartHeightRatio != 0, availableHeight != 0 else { return }
        
        _candles.enumerated().forEach { index, element in
            showCandle(index: index, candle: element, availableHeight: availableHeight, with: chartHeightRatio)
        }

        let lineColor = UIColor.white.withAlphaComponent(0.1).cgColor
        let topLineFrame = CGRect(x: 0, y: (scrollView.frame.height - availableHeight) / 2.0, width: scrollViewWidth, height: 1)
        let bottomLineFrame = CGRect(x: 0, y: (scrollView.frame.height + availableHeight) / 2.0, width: scrollViewWidth, height: 1)
        
        let fontSize: CGFloat = 14
        let textColor = UIColor.white.withAlphaComponent(0.2).cgColor
        let textHeight = UIFont.systemFont(ofSize: fontSize).lineHeight
        let maxTextFrame = CGRect(x: topLineFrame.minX, y: topLineFrame.minY - textHeight, width: topLineFrame.width, height: textHeight)
        let minTextFrame = CGRect(x: bottomLineFrame.minX, y: bottomLineFrame.maxY, width: bottomLineFrame.width, height: textHeight)
        
        _mainLayer.addRectangleLayer(frame: topLineFrame, color: lineColor)
        _mainLayer.addRectangleLayer(frame: bottomLineFrame, color: lineColor)
        _mainLayer.addTextLayer(frame: maxTextFrame, color: textColor, fontSize: fontSize,
                                text: _maxValue == 0 ? String() : String(_maxValue))
        _mainLayer.addTextLayer(frame: minTextFrame, color: textColor, fontSize: fontSize,
                                text: _minValue == .infinity ? String() : String(_minValue))
        
        guard needToScroll else { return }
        
        let rectToScroll = CGRect(x: scrollView.contentSize.width - scrollViewWidth, y: scrollView.frame.minY, width: scrollViewWidth, height: scrollView.frame.height)
        scrollView.scrollRectToVisible(rectToScroll, animated: true)
    }
    
    private func showCandle(index: Int, candle: Candle, availableHeight: CGFloat, with chartHeightRatio: CGFloat) {
        let color = candle.openValue < candle.closeValue ? ColorConstants.positiveCandle : ColorConstants.negativeCandle
        
        let candleShadowHeight = CGFloat(candle.maxValue - candle.minValue) * chartHeightRatio
        let candleShadowOriginY = CGFloat(_maxValue - candle.maxValue) * chartHeightRatio
            + (scrollView.frame.height - availableHeight) / 2.0
        let candleShadowOriginX = CGFloat(index) * (LayoutConstants.candleSpacing + LayoutConstants.candleBodyWidth) + LayoutConstants.candleSpacing + LayoutConstants.candleBodyWidth / 2.0
        
        let frameForCandleShadow = CGRect(x: candleShadowOriginX, y: candleShadowOriginY, width: LayoutConstants.candleShadowWidth, height: candleShadowHeight)
        
        let maxCandleBodyValue = max(candle.openValue, candle.closeValue)
        let minCandleBodyValue = min(candle.openValue, candle.closeValue)
        
        let candleBodyHeight = CGFloat(maxCandleBodyValue - minCandleBodyValue) * chartHeightRatio
        let candleBodyOriginY = CGFloat(_maxValue - maxCandleBodyValue) * chartHeightRatio
            + (scrollView.frame.height - availableHeight) / 2.0
        let candleBodyOriginX = CGFloat(index) * (LayoutConstants.candleSpacing + LayoutConstants.candleBodyWidth) + LayoutConstants.candleSpacing
        
        let frameForCandleBody = CGRect(x: candleBodyOriginX, y: candleBodyOriginY, width: LayoutConstants.candleBodyWidth, height: candleBodyHeight)
        
        if scrollView.contentOffset.x <= frameForCandleBody.maxX && scrollView.contentOffset.x + scrollView.bounds.width >= frameForCandleBody.minX {
            _mainLayer.addRectangleLayer(frame: frameForCandleShadow, color: ColorConstants.candleShadow.cgColor)
            _mainLayer.addRectangleLayer(frame: frameForCandleBody, color: color.cgColor, cornered: true)
        }
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.panGestureRecognizer.state != .possible else { return }

        updateUIWithUpdatedData()
    }
}

extension CALayer {
    func addRectangleLayer(frame: CGRect, color: CGColor, cornered: Bool = false) {
        let layer = CALayer()
        layer.frame = frame
        layer.backgroundColor = color
        if cornered {
            layer.cornerRadius = 3
        }
        addSublayer(layer)
    }
    
    func addTextLayer(frame: CGRect, color: CGColor, fontSize: CGFloat, text: String) {
        let textLayer = CATextLayer()
        textLayer.frame = frame
        textLayer.foregroundColor = color
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.alignmentMode = CATextLayerAlignmentMode.left
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
        textLayer.fontSize = fontSize
        textLayer.string = text
        addSublayer(textLayer)
    }
}
