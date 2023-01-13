//
//  DataFetcher.swift
//  TnKsToiletMap
//
//  Created by Riddle Ling on 2023/1/5.
//

import Foundation
import MapKit


struct Toilet: Identifiable {
    let id = UUID()
    let coordinate : CLLocationCoordinate2D
    let address : String
    let city: String
}


@MainActor
class DataFetcher: ObservableObject {
    
    @Published var dataArray : [Toilet]?

    private var tnResults = Array<Dictionary<String,Any>>()
    private var ksResults = Array<Dictionary<String,Any>>()
    
    private let infoUrlString = "https://wlmaplab.github.io/json/tn-ks-toilet-dataset.json"
    
    private var tnUrlString = ""
    private var ksUrlString = ""
    
    
    // MARK: - Functions
    
    func download() async {
        print(">> 正在下載資料集...")
        dataArray = nil
        
        if let json = try? await httpGET_withFetchJsonObject(URLString: infoUrlString) {
            if let tnUrlStr = json["tn"] as? String {
                tnUrlString = tnUrlStr
            }
            if let ksUrlStr = json["ks"] as? String {
                ksUrlString = ksUrlStr
            }
            await fetchData()
        }
    }
    
    
    // MARK: - Fetch Data
    
    private func fetchData() async {
        async let tnData = fetchTnData()
        async let ksData = fetchKsData()
        
        if let tnData = await tnData {
            tnResults.append(contentsOf: tnData)
        }
        if let ksData = await ksData {
            ksResults.append(contentsOf: ksData)
        }
        convertResultsToDataArray()
    }
    
    private func fetchTnData() async -> [[String: Any]]? {
        if let json = try? await httpGET_withFetchJsonObject(URLString: tnUrlString),
           let results = json["data"] as? Array<Dictionary<String,Any>>
        {
            return results
        }
        return nil
    }
    
    private func fetchKsData() async -> [[String: Any]]? {
        if let json = try? await httpGET_withFetchJsonArray(URLString: ksUrlString) {
            return json
        }
        return nil
    }
    
    private func convertResultsToDataArray() {
        var tmpArray = [Toilet]()
        
        for info in tnResults {
            if let item = createTnToiletPinItem(info) {
                tmpArray.append(item)
            }
        }
        print(">> tnResults count: \(tnResults.count)")
        
        for info in ksResults {
            if let item = createKsToiletPinItem(info) {
                tmpArray.append(item)
            }
        }
        print(">> ksResults count: \(ksResults.count)")
        
        dataArray = tmpArray
        print(">> dataArray count: \(tmpArray.count)")
    }
    
    
    // MARK: - Pin Item
    
    private func createTnToiletPinItem(_ info: Dictionary<String,Any>) -> Toilet? {
        let latitude = Double("\(info["緯度"] ?? "")")
        let longitude = Double("\(info["經度"] ?? "")")
        
        if let lat = latitude, let lng = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let address = "\(info["公廁名稱"] ?? "")"
            return Toilet(coordinate: coordinate, address: address, city: "tn")
        }
        return nil
    }
    
    private func createKsToiletPinItem(_ info: Dictionary<String,Any>) -> Toilet? {
        let latitude = Double("\(info["Lat"] ?? "")")
        let longitude = Double("\(info["Lng"] ?? "")")
        
        if let lat = latitude, let lng = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let address = "\(info["name"] ?? "")（\(info["address"] ?? "")）"
            return Toilet(coordinate: coordinate, address: address, city: "ks")
        }
        return nil
    }
    
    
    // MARK: - HTTP GET
    
    private func httpGET_withFetchJsonObject(URLString: String) async throws -> [String: Any]? {
        let json = try await httpRequestWithFetchJsonObject(httpMethod: "GET", URLString: URLString, parameters: nil)
        return json
    }
    
    private func httpGET_withFetchJsonArray(URLString: String) async throws -> [[String: Any]]? {
        let json = try await httpRequestWithFetchJsonArray(httpMethod: "GET", URLString: URLString, parameters: nil)
        return json
    }
    
    
    // MARK: - HTTP Request with Method
    
    private func httpRequestWithFetchJsonObject(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?) async throws -> [String: Any]? {
        // Create request
        let url = URL(string: URLString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // Header
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        // Body
        if let parameterDict = parameters {
            // parameter dict to json data
            let jsonData = try? JSONSerialization.data(withJSONObject: parameterDict)
            // insert json data to the request
            request.httpBody = jsonData
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let json = json as? [String: Any] {
            return json
        }
        return nil
    }
    
    private func httpRequestWithFetchJsonArray(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?) async throws -> [[String: Any]]? {
        // Create request
        let url = URL(string: URLString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // Header
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        // Body
        if let parameterDict = parameters {
            // parameter dict to json data
            let jsonData = try? JSONSerialization.data(withJSONObject: parameterDict)
            // insert json data to the request
            request.httpBody = jsonData
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let json = json as? [[String: Any]] {
            return json
        }
        return nil
    }
}
