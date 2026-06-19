import Foundation

public enum SchemeLoadingError: Error, Equatable {
    case fileReadFailed
    case invalidJSON
    case emptySchemeList
}

public struct SchemeLoader {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func loadSchemes(from url: URL) throws -> [AudioScheme] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw SchemeLoadingError.fileReadFailed
        }

        let schemes: [AudioScheme]
        do {
            schemes = try decoder.decode([AudioScheme].self, from: data)
        } catch {
            throw SchemeLoadingError.invalidJSON
        }

        if schemes.isEmpty {
            throw SchemeLoadingError.emptySchemeList
        }
        return schemes
    }
}
