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

class DataFetcher: ObservableObject {
    
    @Published var dataArray : [Toilet]?

    private var tnResults = Array<Dictionary<String,Any>>()
    private var ksResults = Array<Dictionary<String,Any>>()
    
    private let infoUrlString = "https://wlmaplab.github.io/json/tn-ks-toilet-dataset.json"
    
    private var tnUrlString = ""
    private var ksUrlString = ""
    
    
    // MARK: - Functions
    
    func download() {
        print(">> 正在下載資料集...")
        dataArray = nil
        downloadInfoData()
    }
    
    
    // MARK: - Download Data
    
    private func downloadInfoData() {
        httpGET_withFetchJsonObject(URLString: infoUrlString) { json in
            if let json = json {
                if let tnUrlStr = json["tn"] as? String {
                    self.tnUrlString = tnUrlStr
                }
                if let ksUrlStr = json["ks"] as? String {
                    self.ksUrlString = ksUrlStr
                }
            }
            self.downloadTnData()
        }
    }
    
    
    private func downloadTnData() {
        httpGET_withFetchJsonObject(URLString: tnUrlString) { json in
            if let json = json,
               let results = json["data"] as? Array<Dictionary<String,Any>>
            {
                self.tnResults.append(contentsOf: results)
            }
            self.downloadKsData()
        }
    }
    
    private func downloadKsData() {
        httpGET_withFetchJsonArray(URLString: ksUrlString) { json in
            if let results = json {
                self.ksResults.append(contentsOf: results)
            }
            self.convertResultsToDataArray()
        }
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
    
    private func httpGET_withFetchJsonObject(URLString: String, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        httpRequestWithFetchJsonObject(httpMethod: "GET", URLString: URLString, parameters: nil, callback: callback)
    }
    
    private func httpGET_withFetchJsonArray(URLString: String, callback: @escaping (Array<Dictionary<String,Any>>?) -> Void) {
        httpRequestWithFetchJsonArray(httpMethod: "GET", URLString: URLString, parameters: nil, callback: callback)
    }
    
    
    // MARK: - HTTP Request with Method
    
    private func httpRequestWithFetchJsonObject(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?,
                                                callback: @escaping (Dictionary<String,Any>?) -> Void)
    {
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
        
        // Task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    callback(nil)
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    callback(responseJSON)
                } else {
                    callback(nil)
                }
            }
        }
        task.resume()
    }
    
    private func httpRequestWithFetchJsonArray(httpMethod: String,
                                               URLString: String,
                                               parameters: Dictionary<String,Any>?,
                                               callback: @escaping (Array<Dictionary<String,Any>>?) -> Void)
    {
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
        
        // Task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    callback(nil)
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? Array<Dictionary<String,Any>> {
                    callback(responseJSON)
                } else {
                    callback(nil)
                }
            }
        }
        task.resume()
    }
}
