import Foundation

public struct AudioScheme: Codable, Equatable {
    public let name: String
    public let displayName: String
    public let files: [String]
    public let nonUniqueCount: UInt8
    public let keyAudioMap: [UInt8: UInt8]

    public init(
        name: String,
        displayName: String,
        files: [String],
        nonUniqueCount: UInt8,
        keyAudioMap: [UInt8: UInt8]
    ) {
        self.name = name
        self.displayName = displayName
        self.files = files
        self.nonUniqueCount = nonUniqueCount
        self.keyAudioMap = keyAudioMap
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case files
        case nonUniqueCount = "non_unique_count"
        case keyAudioMap = "key_audio_map"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        files = try container.decode([String].self, forKey: .files)
        nonUniqueCount = try container.decode(UInt8.self, forKey: .nonUniqueCount)

        let rawMap = try container.decode([String: UInt8].self, forKey: .keyAudioMap)
        var decodedMap: [UInt8: UInt8] = [:]
        for (key, value) in rawMap {
            guard let keyCode = UInt8(key) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .keyAudioMap,
                    in: container,
                    debugDescription: "Invalid key code '\(key)' in key_audio_map"
                )
            }
            decodedMap[keyCode] = value
        }
        keyAudioMap = decodedMap
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(files, forKey: .files)
        try container.encode(nonUniqueCount, forKey: .nonUniqueCount)

        let encodedMap = Dictionary(uniqueKeysWithValues: keyAudioMap.map { (String($0.key), $0.value) })
        try container.encode(encodedMap, forKey: .keyAudioMap)
    }
}
