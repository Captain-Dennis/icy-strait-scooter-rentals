import Foundation

/// Tiny HTTP pipe both apps share. This is the v1 live event list.
/// CloudKit is compiled separately and is not entitled on the shipping customer app.
actor HTTPLotStore: SharedLotStore {
    nonisolated var providerName: String { "HTTPLotStore" }

    var baseURL: URL
    var session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func setBaseURL(_ url: URL) {
        baseURL = url
    }

    func snapshot() async throws -> LotSnapshot {
        try await get(path: "snapshot", as: LotSnapshot.self)
    }

    func publish(_ event: RentalLifecycleEvent) async throws {
        try await post(path: "events", body: event)
    }

    func publishAlert(_ alert: StaffAlertRecord) async throws {
        try await post(path: "alerts", body: alert)
    }

    func upsertStaff(_ member: SharedStaffMember) async throws {
        try await put(path: "staff/\(member.id.uuidString)", body: member)
    }

    func replaceStaff(_ members: [SharedStaffMember]) async throws {
        try await put(path: "staff", body: members)
    }

    private func get<T: Decodable>(path: String, as type: T.Type) async throws -> T {
        var request = URLRequest(url: url(path))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data = try await send(request)
        do {
            return try LotJSON.decoder().decode(T.self, from: data)
        } catch {
            throw SharedLotStoreError.decoding
        }
    }

    private func post<T: Encodable>(path: String, body: T) async throws {
        try await write(method: "POST", path: path, body: body)
    }

    private func put<T: Encodable>(path: String, body: T) async throws {
        try await write(method: "PUT", path: path, body: body)
    }

    private func write<T: Encodable>(method: String, path: String, body: T) async throws {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try LotJSON.encoder().encode(body)
        } catch {
            throw SharedLotStoreError.encoding
        }
        _ = try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw SharedLotStoreError.unreachable("HTTP \(http.statusCode)")
            }
            return data
        } catch let error as SharedLotStoreError {
            throw error
        } catch {
            throw SharedLotStoreError.unreachable(error.localizedDescription)
        }
    }

    private func url(_ path: String) -> URL {
        var root = baseURL.absoluteString
        if !root.hasSuffix("/") {
            root += "/"
        }
        return URL(string: path, relativeTo: URL(string: root))!.absoluteURL
    }
}
