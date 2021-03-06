//
//  YelpClient.swift
//  Yelp
//
//  Created by Timothy Lee on 9/19/14.
//  Copyright (c) 2014 Timothy Lee. All rights reserved.
//

import UIKit

import AFNetworking
import BDBOAuth1Manager
import CoreLocation

// You can register for Yelp API keys here: http://www.yelp.com/developers/manage_api_keys
let yelpConsumerKey = "vxKwwcR_NMQ7WaEiQBK_CA"
let yelpConsumerSecret = "33QCvh5bIF5jIHR5klQr7RtBDhQ"
let yelpToken = "uRcRswHFYa1VkDrGV6LAW2F8clGh5JHV"
let yelpTokenSecret = "mqtKIxMIR4iBtBPZCmCLEb-Dz3Y"

enum YelpSortMode: Int {
    case bestMatched = 0, distance, highestRated
}

class YelpClient: BDBOAuth1RequestOperationManager, LocationServiceDelegate {
    var accessToken: String!
    var accessSecret: String!
    
    //MARK: Shared Instance
    
    static let sharedInstance = YelpClient(consumerKey: yelpConsumerKey, consumerSecret: yelpConsumerSecret, accessToken: yelpToken, accessSecret: yelpTokenSecret)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(consumerKey key: String!, consumerSecret secret: String!, accessToken: String!, accessSecret: String!) {
        self.accessToken = accessToken
        self.accessSecret = accessSecret
        let baseUrl = URL(string: "https://api.yelp.com/v2/")
        super.init(baseURL: baseUrl, consumerKey: key, consumerSecret: secret);
        
        let token = BDBOAuth1Credential(token: accessToken, secret: accessSecret, expiration: nil)
        self.requestSerializer.saveAccessToken(token)
    }
    
    func searchWithTerm(_ term: String, offset: Int, completion: @escaping ([Business]?, Error?) -> Void) -> AFHTTPRequestOperation {
        return searchWithTerm(term, sort: nil, categories: nil, deals: nil, offset: offset, completion: completion)
    }
    
    
    func searchWithTerm(_ term: String, sort: YelpSortMode?, categories: [String]?, deals: Bool?, offset: Int?, completion: @escaping ([Business]?, Error?) -> Void) -> AFHTTPRequestOperation {
        // For additional parameters, see http://www.yelp.com/developers/documentation/v2/search_api
        
        var latitudeString: String?
        var longitudeString: String?
        if let latitude = LocationService.sharedInstance.currentLocation?.coordinate.latitude {
            latitudeString = String(describing: latitude)
        }
        if let longitude = LocationService.sharedInstance.currentLocation?.coordinate.longitude {
            longitudeString = String(describing: longitude)
        }
        print("\(latitudeString!) and \(longitudeString!)")
        // Default the location to San Francisco
        var parameters: [String : AnyObject] = ["term": term as AnyObject, "ll": "\(latitudeString!),\(longitudeString!)" as AnyObject, "actionlinks": true as AnyObject]
        
        if sort != nil {
            parameters["sort"] = sort!.rawValue as AnyObject?
        }
        
        if categories != nil && categories!.count > 0 {
            parameters["category_filter"] = (categories!).joined(separator: ",") as AnyObject?
        }
        
        if deals != nil {
            parameters["deals_filter"] = deals! as AnyObject?
        }
        
        if offset != nil {
            parameters["offset"] = offset! as AnyObject?
        }
        
        print(parameters)
        
        return self.get("search", parameters: parameters,
                        success: { (operation: AFHTTPRequestOperation, response: Any) -> Void in
                            if let response = response as? [String: Any]{
                                let dictionaries = response["businesses"] as? [NSDictionary]
                                if dictionaries != nil {
                                    //print(dictionaries)
                                    //print(dictionaries?[0]["actionlinks"])
                                    completion(Business.businesses(array: dictionaries!), nil)
                                }
                            }
                        },
                        failure: { (operation: AFHTTPRequestOperation?, error: Error) -> Void in
                            completion(nil, error)
                        })!
    }
    
    func getBusiness(withID id: String, completion: @escaping (Business?, Error?) -> Void) -> AFHTTPRequestOperation {
        var parameters = id //[String: AnyObject] = [".us": id as AnyObject]
        
        return self.get("business/\(id)", parameters: nil,
                        success: { (operation: AFHTTPRequestOperation, response: Any) -> Void in
                            print(response)
                            if let response = response as? NSDictionary {
                                var business: Business!
                                
                                business = Business(dictionary: response)!
                                print(business.name!)
                                completion(business, nil)
                            }
//                            if let response = response as? [String: Any]{
//                                let dictionaries = response["businesses"] as? [NSDictionary]
//                                if dictionaries != nil {
//                                    //print(dictionaries)
//                                    //print(dictionaries?[0]["actionlinks"])
//                                    completion(Business.businesses(array: dictionaries!), nil)
//                                }
//                            }
        },
                        failure: { (operation: AFHTTPRequestOperation?, error: Error) -> Void in
                            completion(nil, error)
        })!
    }
    
    func tracingLocation(_ currentLocation: CLLocation) {
        
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        print("tracing Location Error : \(error.description)")
    }
}


