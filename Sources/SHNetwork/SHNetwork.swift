//
//  SHNetwork.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation
import Alamofire

open class SHNetwork {
    
    public typealias completion = (_ response: Result<[String: Any], Error>) -> Void
    public typealias dataCompletion = (_ response: Result<Data, Error>) -> Void
    public typealias codableCompletion<T: Codable> = (_ response: Result<T, Error>) -> Void
    
    public typealias codableResponse<T: Codable> = Result<T, Error>
    
    private var baseURL: String = ""
    private var headers: [String: String] = [:]
    
    public func getBaseURL() -> String { baseURL }
    public func getGlobalHeaders() -> [String: String] { headers }
    
    
    public static let shared = SHNetwork()
    private init () {
        headers = ["Content-Type": "application/json"]
    }
    
    public func initialise(_ baseURL: String, globalHeaders: [String: String]? = nil) {
        self.baseURL = baseURL
        if let globalHeaders { self.headers = globalHeaders }
    }
    
    public func setGlobalHeader(_ key: String, value: String) {
        headers[key] = value
        headers = sanitizeParam(headers)
    }
    
    public func removeGlobalHeader(_ key: String) {
        headers[key] = nil
        headers = sanitizeParam(headers)
    }
    
    public func createCustomError(_ message: String?, code: Int = 0) -> Error {
        guard let message = message else {return SHNetworkError.unknown}
        let customError = NSError(domain:"", code: code, userInfo:[ NSLocalizedDescriptionKey: message])
        return customError as Error
    }
    
    
    // MARK: - parameter related
    public func jsonToString(_ json: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {return nil}
        return String(data: data, encoding: .utf8)
    }
    
    public func convertToGetParam(_ param: [String: Any]) -> String {
        
        var localParam = ""
        for (key, value) in param {
            let stringValue = "\(value)"
            if stringValue != "" {
                localParam += key + "=" + stringValue + "&"
            }
        }
        
        return String(localParam.dropLast())
        
    }
    
    public func sanitizeParam(_ param: [String: Any]) -> [String: Any] {
        
        var localParam: [String: Any] = [:]
        for (key, _) in param {
            if let value = param[key] as? String, value != "" { localParam[key] = value }
            if let value = param[key] as? Int { localParam[key] = value }
            if let value = param[key] as? Double { localParam[key] = value }
            if let value = param[key] as? Bool { localParam[key] = value }
        }
        return localParam
        
    }
    
    public func sanitizeParam(_ param: [String: String]) -> [String: String] {
        
        var localParam: [String: String] = [:]
        for (key, _) in param {
            if let value = param[key], value != "" { localParam[key] = value }
        }
        return localParam
        
    }
    
    
}

// MARK: - data completion response -
public extension SHNetwork {
    
    // MARK: - post request
    func sendPostRequest(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    func sendPostRequest(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: .init(localHeaders))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data): comp(.success(data))
            case .failure(let error): comp(.failure(error))
            }
        })
        
    }
    
    
    // MARK: - get request
    func sendGetRequest(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    
    // MARK: - general request
    func sendRequest(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendRequest(with completeUrl: String, method: HTTPMethod, param: [String: Any], headers: [String: String], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping dataCompletion) {
        
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    func uploadMedia(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false, comp: @escaping dataCompletion) {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data): comp(.success(data))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
}

// MARK: - Dict completion response -
public extension SHNetwork {
    
    // MARK: - post request
    func sendPostRequest(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    func sendPostRequest(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: .init(localHeaders))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    comp(.failure(SHNetworkError.invalidResponse))
                    return
                }
                comp(.success(json))
            case .failure(let error): comp(.failure(error))
            }
        })
        
    }
    
    
    // MARK: - get request
    func sendGetRequest(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    
    // MARK: - general request
    func sendRequest(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendRequest(with completeUrl: String, method: HTTPMethod, param: [String: Any], headers: [String: String], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    func uploadMedia(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false, comp: @escaping completion) {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(SHNetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
}

// MARK: - Codable completion response -
public extension SHNetwork {
    
    // MARK: - post request
    func sendPostRequest<T: Codable>(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    func sendPostRequest<T: Codable>(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: HTTPHeaders(localHeaders))
        .responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let result): comp(.success(result))
            case .failure(let error): comp(.failure(error))
            }
        }
    }
    
    
    // MARK: - get request
    func sendGetRequest<T: Codable>(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendGetRequest(urlExt, param: convertToGetParam(param), customHeader: customHeader, comp: comp)
    }
    
    func sendGetRequest<T: Codable>(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendGetRequest<T: Codable>(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendGetRequest(with: completeUrl, param: convertToGetParam(param), customHeader: customHeader, comp: comp)
    }
    
    func sendGetRequest<T: Codable>(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - general request
    func sendRequest<T: Codable>(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendRequest<T: Codable>(with completeUrl: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], headers: [String: String], comp: @escaping codableCompletion<T>) {
        
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    func uploadMedia<T: Codable>(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false, comp: @escaping codableCompletion<T>) {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
}

