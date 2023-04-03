import Foundation
import Libbox

class HTTPClient {
    static var userAgent: String {
        var userAgent = "SFI/"
        userAgent += Bundle.main.version
        userAgent += " (Build "
        userAgent += Bundle.main.versionNumber
        userAgent += "; sing-box "
        userAgent += LibboxVersion()
        userAgent += ")"
        return userAgent
    }

    let client: any LibboxHTTPClientProtocol

    init() {
        client = LibboxNewHTTPClient()!
        client.modernTLS()
    }

    func getString(_ url: String?) throws -> String {
        let request = client.newRequest()!
        request.setUserAgent(HTTPClient.userAgent)
        try request.setURL(url)
        let response = try request.execute()
        var error: NSError?
        let contentString = response.getContentString(&error)
        if let error {
            throw error
        }
        return contentString
    }

    func close() {
        client.close()
    }
}
