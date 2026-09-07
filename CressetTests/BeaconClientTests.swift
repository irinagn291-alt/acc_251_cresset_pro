import XCTest
@testable import Cresset

private struct ProbeDTO: Decodable {
    var remainder: Double
}

private actor ScriptedCarrier: BeaconCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class BeaconClientTests: XCTestCase {
    private let url = URL(string: "https://cresset-isle.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"remainder\":1}".utf8), http(200))),
        ])
        let client = BeaconClient(carrier: carrier)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), BeaconClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(BeaconClient.userAgent, "Cresset/1.0 (iOS; +https://cresset-isle.pro)")
        XCTAssertEqual(BeaconClient.contactURL.absoluteString, "https://cresset-isle.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"remainder\":4.5}".utf8), http(200))),
        ])
        let client = BeaconClient(carrier: carrier)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.remainder, 4.5)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), http(404))),
            .success((Data("{\"remainder\":1}".utf8), http(200))),
        ])
        let client = BeaconClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? BeaconFault, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = BeaconClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? BeaconFault, .decoding)
        }
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
