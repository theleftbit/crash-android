//
//  Created by Pierluigi Cifani.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

import Foundation

enum JSONParser {
    
    static let Options: JSONSerialization.ReadingOptions = [.allowFragments]

    static func dataIsNull(_ data: Data) -> Bool {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else {
            return false
        }
        
        guard let _ = j as? NSNull else {
            return false
        }
        
        return true
    }
    
    /// Parses a `Data` as a JSON to pretty print. Useful for debugging.
    /// - Parameter data: The given Data.
    /// - Returns: The String as pretty print, for easy debug
    static func parseDataAsJSONPrettyPrint(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else { return nil }
        let options: JSONSerialization.WritingOptions = [.fragmentsAllowed,.withoutEscapingSlashes, .sortedKeys]
        guard let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: options) else { return nil }
        return String(data: prettyPrintedData, encoding: .utf8)
    }
    
    static func parseDataAsBSWServerErrorMessage(_ data: Data) -> String? {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else {
            return nil
        }
        guard let dictionary = j as? [String: String] else {
            return nil
        }
        return dictionary[APIClient.Error.ServerMessage]
    }
    
    /// Attempts to extract an error string from the passed JSON data.
    /// - Parameter data: The JSON data that should include an `"error"` key
    /// - Returns: The error string if found
    static func errorMessageFromData(_ data: Data) -> String? {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: JSONParser.Options) else {
            return nil
        }
        guard let dictionary = j as? [String: String] else {
            return nil
        }        
        return dictionary["error"]
    }
    
    /// Parses `Data` to the `T: Decodable` value.
    /// - Parameter data: The JSON data.
    /// - Returns: The `T` parsed value
    static func parseData<T: Decodable>(_ data: Data) throws -> T {
        
        let jsonDecoder = JSONDecoder()

        guard T.self != VoidResponse.self else {
            let response = VoidResponse.init() as! T
            return response
        }
        
        if let provider = T.self as? DateDecodingStrategyProvider.Type {
            jsonDecoder.dateDecodingStrategy = .formatted(provider.dateDecodingStrategy)
        } else {
            jsonDecoder.dateDecodingStrategy = .formatted(iso8601DateFormatter)
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let missingKey, let context):
                print("*ERROR* decoding, key \"\(missingKey)\" is missing, Context: \(context)")
                throw Error.malformedSchema
            case .typeMismatch(let type, let context):
                print("*ERROR* decoding, type \"\(type)\" mismatched, context: \(context)")
                throw Error.malformedSchema
            case .valueNotFound(let type, let context):
                print("*ERROR* decoding, value not found \"\(type)\", context: \(context)")
                throw Error.malformedSchema
            case .dataCorrupted(let context):
                print("*ERROR* Data Corrupted \"\(context)\")")
                if let string = String(data: data, encoding: .utf8) {
                    print("*ERROR* incoming JSON: \(string)")
                }
                throw Error.malformedJSON
            @unknown default:
                throw Error.unknownError
            }
        } catch {
            throw Error.unknownError
        }
    }

    //MARK: Error

    enum Error: Swift.Error {
        case malformedJSON
        case malformedSchema
        case unknownError
        case canceled
    }
}

protocol DateDecodingStrategyProvider {
    static var dateDecodingStrategy: DateFormatter { get }
}

private var iso8601DateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return formatter
}

extension Array: DateDecodingStrategyProvider where Element: DateDecodingStrategyProvider {
    static var dateDecodingStrategy: DateFormatter {
        return Element.dateDecodingStrategy
    }
}
