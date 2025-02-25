import Foundation

/// A location of the resource.
public enum ResourceLocation: Hashable, CustomStringConvertible, Codable {
    /// direct path to the file on disk
    case localFilePath(String)
    
    /// URL to archive that should be extracted in order to get the file.
    /// Filename in this case can be specified by fragment:
    /// http://example.com/file.zip#actualFileInsideZip
    case remoteUrl(URL, _ headers: [String: String]?)
    
    public enum ValidationError: Error, CustomStringConvertible {
        case cannotCreateUrl(String)
        case fileDoesNotExist(String)
        
        public var description: String {
            switch self {
            case .cannotCreateUrl(let string):
                return "Attempt to create a URL from string '\(string)' failed"
            case .fileDoesNotExist(let path):
                return "File does not exist at path: '\(path)'"
            }
        }
    }
    
    public var url: URL? {
        switch self {
        case .remoteUrl(let url, _):
            return url
        case .localFilePath:
            return nil
        }
    }
    
    public var headers: [String: String]? {
        switch self {
        case .remoteUrl(_, let headers):
            return headers
        case .localFilePath:
            return nil
        }
    }
    
    private enum CodingKeys: CodingKey {
        case url
        case headers
    }
    
    public static func from(_ string: String) throws -> ResourceLocation {
        if let decoded = try? JSONDecoder().decode(self, from: Data(string.utf8)) {
            return decoded
        }
        let components = try urlComponents(string)
        guard let url = components.url else { throw ValidationError.cannotCreateUrl(string) }
        if url.isFileURL {
            return try withPathString(string)
        } else {
            return withUrl(url, [:])
        }
    }
    
    private static let percentEncodedCharacters: CharacterSet = CharacterSet()
        .union(.urlQueryAllowed)
        .union(.urlHostAllowed)
        .union(.urlPathAllowed)
        .union(.urlUserAllowed)
        .union(.urlFragmentAllowed)
        .union(CharacterSet(charactersIn: "#"))
        .union(.urlPasswordAllowed)
    
    private static func urlComponents(_ string: String) throws -> URLComponents {
        let string = string.addingPercentEncoding(withAllowedCharacters: percentEncodedCharacters) ?? string
        guard var components = URLComponents(string: string) else { throw ValidationError.cannotCreateUrl(string) }
        if components.scheme == nil {
            components.scheme = "file"
        }
        return components
    }
    
    private static func withoutValueValidation(_ string: String, _ headers: [String: String]?) throws -> ResourceLocation {
        let components = try urlComponents(string)
        guard let url = components.url else { throw ValidationError.cannotCreateUrl(string) }
        if url.isFileURL {
            return .localFilePath(string)
        } else {
            return .remoteUrl(url, headers)
        }
    }
    
    private static func withUrl(_ url: URL, _ headers: [String: String]) -> ResourceLocation {
        return ResourceLocation.remoteUrl(url, headers)
    }
    
    private static func withPathString(_ string: String) throws -> ResourceLocation {
        guard FileManager.default.fileExists(atPath: string) else { throw ValidationError.fileDoesNotExist(string) }
        return ResourceLocation.localFilePath(string)
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .localFilePath(let path):
            hasher.combine(path)
        case .remoteUrl(let url, _):
            hasher.combine(url)
        }
    }
    
    public var description: String {
        switch self {
        case .localFilePath(let path):
            return "\(path)"
        case .remoteUrl(let url, _):
            return "\(url)"
        }
    }
    
    public func stringValue() throws -> String {
        switch self {
        case .localFilePath(let path):
            return path
        case .remoteUrl(let url, let headers):
            guard let headers = headers,
                  headers.count > 0 else {
                return url.absoluteString
            }
            struct Params: Encodable {
                let url: String
                let headers: [String: String]
            }
            let params = Params(url: url.absoluteString, headers: headers)
            let data = try JSONEncoder().encode(params)
            if let result = String(data: data, encoding: .utf8) {
                return result
            } else {
                throw ResourceLocationError.encodeRemoteUrl(url: url.absoluteString)
            }
        }
    }
    
    public static func == (left: ResourceLocation, right: ResourceLocation) -> Bool {
        switch (left, right) {
        case (.localFilePath(let leftPath), .localFilePath(let rightPath)):
            return leftPath == rightPath
        case (.remoteUrl(let leftUrl, _), .remoteUrl(let rightUrl, _)):
            return leftUrl == rightUrl
        default:
            return false
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let url = try container.decode(String.self, forKey: .url)
            let headers = try? container.decodeIfPresent([String: String].self, forKey: .headers)
            self = try ResourceLocation.withoutValueValidation(url, headers)
        } else {
            let container = try decoder.singleValueContainer()
            self = try ResourceLocation.withoutValueValidation(try container.decode(String.self), nil)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .localFilePath(let path):
            try container.encode(path, forKey: .url)
        case .remoteUrl(let url, let headers):
            try container.encode(url, forKey: .url)
            if let headers = headers {
                try container.encode(headers, forKey: .headers)
            }
        }
    }
    
    public func mapLocalFile(_ mapper: (String) throws -> Self) rethrows -> Self {
        switch self {
        case .localFilePath(let string):
            return try mapper(string)
        case .remoteUrl:
            return self
        }
    }
}
