//
//  koinex.swift
//  Cryptex
//
//  Created by Sathyakumar Rajaraman on 01/01/18.
//  Copyright © 2018 Sathyakumar. All rights reserved.
//

import Foundation

public extension CurrencyPair {
    var koinexSymbol: String {
        return quantity.code
    }
}

public struct Koinex {
    public struct Ticker {
        public var symbol: CurrencyPair
        public var price: NSDecimalNumber
        
        public init(symbol: CurrencyPair, price: NSDecimalNumber) {
            self.symbol = symbol
            self.price = price
        }
    }
    
    public class Store: ExchangeDataStoreType {
        public static var shared = Store()
        
        public var name: String = "Koinex"
        
        private init() { }
        
        public var tickerResponse: (response: HTTPURLResponse?, tickers: [Koinex.Ticker]) = (nil, [])
    }
    
    public enum API {
        case ticker
    }
    
    public class Service: Network {
        
        fileprivate let store = Koinex.Store.shared
        
        public func getTickers(completion: @escaping (ResponseType) -> Void) {
            let apiType = Koinex.API.ticker
            if apiType.checkInterval(response: store.tickerResponse.response) {
                completion(.cached)
            } else {
                dataTaskFor(api: apiType, completion: { (json, httpResponse, error) in
                    guard let json = json as? [String: Any], let prices = json["prices"] as? [String: Any] else {
                        print("Error: Cast Failed in \(#function)")
                        return
                    }
                    var tickers: [Koinex.Ticker] = []
                    for (key, value) in prices {
                        let currency = self.userPreference.currencyStore.forCode(key)
                        let inr = self.userPreference.currencyStore.forCode("inr")
                        let symbol = CurrencyPair(quantity: currency, price: inr)
                        let price = NSDecimalNumber(any: value)
                        let ticker = Koinex.Ticker(symbol: symbol, price: price)
                        tickers.append(ticker)
                    }
                    self.store.tickerResponse = (httpResponse, tickers)
                    completion(.fetched)
                }).resume()
            }
        }
    }
}

extension Koinex.API: APIType {
    
    public var host: String {
        return "https://koinex.in/api"
    }
    
    public var path: String {
        switch self {
        case .ticker: return "/ticker"
        }
    }
    
    public var httpMethod: HttpMethod {
        return .GET
    }
    
    public var authenticated: Bool {
        return false
    }
    
    public var loggingEnabled: LogLevel {
        switch self {
        case .ticker:              return .url
        }
    }
    
    public var postData: [String: String] {
        return [:]
    }
    
    public var refetchInterval: TimeInterval {
        switch self {
        case .ticker:              return .aMinute
        }
    }
}
