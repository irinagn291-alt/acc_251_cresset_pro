import Foundation

/// Role: Lamp. Typed transport failures. This product has no remote catalog.
enum BeaconFault: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Lamp. One HTTP hop. Injected so tests never leave the process.
protocol BeaconCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Lamp. URLSession hop, 15 s timeout, app User-Agent on every request.
struct BeaconSessionCarrier: BeaconCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": BeaconClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Lamp. Owns the session. Offline board — contact URL is a Settings link, not fetched here.
actor BeaconClient {
    static let userAgent = "Cresset/1.0 (iOS; +https://cresset-isle.pro)"
    /// Programmer constant; the domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://cresset-isle.pro/contact-us")!

    private let carrier: any BeaconCarrying

    init(carrier: any BeaconCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = BeaconSessionCarrier()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await fetch(request(for: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw BeaconFault.cancelled
        } catch {
            throw BeaconFault.decoding
        }
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as BeaconFault {
            throw fault
        } catch is CancellationError {
            throw BeaconFault.cancelled
        } catch {
            if Self.cancelled(error) {
                throw BeaconFault.cancelled
            }
            guard Self.transient(error) else { throw BeaconFault.transport }
            do {
                return try await send(request)
            } catch let fault as BeaconFault {
                throw fault
            } catch is CancellationError {
                throw BeaconFault.cancelled
            } catch {
                if Self.cancelled(error) { throw BeaconFault.cancelled }
                throw BeaconFault.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BeaconFault.invalidResponse
        }
        if http.statusCode == 404 {
            throw BeaconFault.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw BeaconFault.transport
        }
        return data
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
