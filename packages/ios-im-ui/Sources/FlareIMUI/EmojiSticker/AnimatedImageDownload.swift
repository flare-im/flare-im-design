import Foundation

func flareCollectLimitedBytes<S: AsyncSequence>(
    _ bytes: S, maximum: Int = FlareAnimatedImageBudget.encodedBytes
) async throws -> Data where S.Element == UInt8 {
    guard maximum > 0 else { throw URLError(.dataLengthExceedsMaximum) }
    var data = Data()
    for try await byte in bytes {
        try Task.checkCancellation()
        guard data.count < maximum else { throw URLError(.dataLengthExceedsMaximum) }
        data.append(byte)
    }
    return data
}

func flareLoadAnimatedData(from url: URL) async throws -> Data {
    guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
        throw URLError(.unsupportedURL)
    }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 30
    let session = URLSession(configuration: configuration)
    defer { session.invalidateAndCancel() }
    let (bytes, response) = try await session.bytes(from: url)
    guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
        throw URLError(.badServerResponse)
    }
    guard response.expectedContentLength <= Int64(FlareAnimatedImageBudget.encodedBytes) else {
        throw URLError(.dataLengthExceedsMaximum)
    }
    // The actual stream is bounded even when Content-Length is absent or false.
    return try await flareCollectLimitedBytes(bytes)
}
