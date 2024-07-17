//
//  ApiRequest.swift
//  BoxJs
//
//  Created by Senku on 7/12/24.
//

import Alamofire
import AnyCodable
import Foundation
import SwiftyJSON

enum RequestError: Error {
    case networkFail
    case statusFail(code: Int, message: String)
    case decodeFail(message: String)
}

enum ApiRequest {
    enum EndPoint {
        static let boxdata = "https://boxjs.com/query/boxdata"
    }

    static func requestJSON(_ url: URLConvertible,
                            method: HTTPMethod = .get,
                            parameters: Parameters = [:],
                            encoding: ParameterEncoding = URLEncoding.default,
                            complete: ((Result<JSON, RequestError>) -> Void)? = nil)
    {
        var parameters = parameters
        AF.request(url, method: method, parameters: parameters, encoding: encoding).responseData { response in
            switch response.result {
            case let .success(data):
                let json = JSON(data)
//                print(json)
                let errorCode = json["code"].intValue
                if errorCode != 0 {
                    let message = json["message"].stringValue
                    print(errorCode, message)
                    complete?(.failure(.statusFail(code: errorCode, message: message)))
                    return
                }
                complete?(.success(json))
            case let .failure(err):
                print(err)
                complete?(.failure(.networkFail))
            }
        }
    }

    static func request<T: Decodable>(_ url: URLConvertible,
                                      method: HTTPMethod = .get,
                                      parameters: Parameters = [:],
                                      auth _: Bool = true,
                                      encoding: ParameterEncoding = URLEncoding.default,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      complete: ((Result<T, RequestError>) -> Void)?)
    {
        requestJSON(url, method: method, parameters: parameters, encoding: encoding) { result in
            switch result {
            case let .success(data):
                do {
                    let data = try data.rawData()
                    let object = try decoder.decode(T.self, from: data)
                    complete?(.success(object))
                } catch let err {
                    print(err)
                    complete?(.failure(.decodeFail(message: err.localizedDescription + String(describing: err))))
                }
            case let .failure(err):
                complete?(.failure(err))
            }
        }
    }

    static func request<T: Decodable>(_ url: URLConvertible,
                                      method: HTTPMethod = .get,
                                      parameters: Parameters = [:],
                                      encoding: ParameterEncoding = URLEncoding.default,
                                      decoder: JSONDecoder = JSONDecoder()) async throws -> T
    {
        try await withCheckedThrowingContinuation { configure in
            request(url, method: method, parameters: parameters, encoding: encoding, decoder: decoder) { resp in
                configure.resume(with: resp)
            }
        }
    }
    
    
    static func getBoxData(lastIdx: Int = 0) async throws -> BodxDataResp {
        let resp: BodxDataResp = try await request(EndPoint.boxdata)
        return resp
    }
}