//
//  NetworkManager.swift
//  Movieflex
//
//  Created by Shubham Singh on 15/09/20.
//  Copyright © 2020 Shubham Singh. All rights reserved.
//

import Alamofire

enum APIError: String {
    case networkError
    case apiError
    case decodingError
}

enum APIs: URLRequestConvertible  {
    
    // MARK:- cases containing APIs
    case titleautocomplete(query: String)
    case popularTitles(regionCode: String)
    case getTitleMetaData(titleIds: [String])
    
    
    // MARK:- variables
    static let endpoint = URL(string: "https://imdb8.p.rapidapi.com")!
    static let apiKey = "a748ca4d1fmshc734cfe79d4afb2p1eb669jsnb351ee595ac1"
    static let apiHost = "imdb8.p.rapidapi.com"
    
    var path: String {
        switch self {
        case .titleautocomplete(_):
            return "/title/auto-complete"
        case .popularTitles(_):
            return "/title/get-most-popular-movies"
        case .getTitleMetaData(_):
            return "/title/get-meta-data"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var encoding : URLEncoding {
        return URLEncoding.init(destination: .queryString, arrayEncoding: .noBrackets)
    }
    
    func addApiHeaders(request: inout URLRequest) {
        request.addValue(Self.apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.addValue(Self.apiKey, forHTTPHeaderField: "x-rapidapi-key")
    }
    
    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint.appendingPathComponent(path))
        var parameters = Parameters()
        
        switch self {
        case .titleautocomplete(let query):
            parameters["q"] = query
        case .popularTitles(let regionCode):
            parameters["currentCountry"] = regionCode
        case .getTitleMetaData(let titleIds):
            parameters["ids"] = titleIds
        }
        
        addApiHeaders(request: &request)
        request.addValue("iphone", forHTTPHeaderField: "User-Agent")
        request = try encoding.encode(request, with: parameters)
        return request
    }
}


struct NetworkManager {
    
    let jsonDecoder = JSONDecoder()
    
    // functions to call the APIs
    func getTitlesAutocomplete(query: String, completion: @escaping([Title]?, APIError? ) -> ()) {
        Alamofire.request(APIs.titleautocomplete(query: query)).validate().responseJSON { json in
            switch json.result {
            case .failure:
                completion(nil, .apiError)
            case .success(let jsonData):
                if let payload = jsonData as? [String:Any], let arrayData = payload["d"], let jsonData = try? JSONSerialization.data(withJSONObject: arrayData, options: .sortedKeys)  {
                    do {
                        let titles = try jsonDecoder.decode([Title].self, from: jsonData)
                        completion(titles, nil)
                    } catch {
                        completion(nil, .decodingError)
                    }
                } else {
                    completion(nil, .networkError)
                }
            }
        }
    }
    
    func getPopularTitles(completion: @escaping([String]?, APIError?) -> ()) {
        Alamofire.request(APIs.popularTitles(regionCode: "IN")).validate().responseJSON { json in
            switch json.result {
            case .failure:
                completion(nil, .apiError)
                break
            case .success(let jsonData):
                if let jsonData = try? JSONSerialization.data(withJSONObject: jsonData, options: .sortedKeys)  {
                    do {
                        let popularTitles = try jsonDecoder.decode([String].self, from: jsonData)
                        completion(popularTitles.map { $0.components(separatedBy: "/")[2] }, nil)
                    } catch {
                        print(error)
                        completion(nil, .decodingError)
                    }
                } else {
                    completion(nil, .networkError)
                }
            }
        }
    }
    
    func getTitlesMetaData(titleIds: [String], completion: @escaping([TitleMetaData]?, APIError?) -> ()) {
        Alamofire.request(APIs.getTitleMetaData(titleIds: titleIds)).validate().responseJSON { json in
            switch json.result {
            case .failure:
                completion(nil, .apiError)
            case .success(let jsonData):
                if let payload = try? JSONSerialization.data(withJSONObject: jsonData, options: .sortedKeys) {
                    do {
                        let decodedData = try jsonDecoder.decode(DecodedTitleMetaData.self, from: payload)
                        completion(decodedData.titlesMetaData, nil)
                    } catch {
                        print(error)
                        completion(nil, .decodingError)
                    }
                } else {
                    completion(nil, .networkError)
                }
            }
        }
    }
}

