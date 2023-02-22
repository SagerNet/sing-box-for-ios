import Foundation
import Libbox
import NetworkExtension

func runBlocking<T>(_ body: @escaping () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = resultBox<T>()
    Task {
        do {
            let value = try await body()
            box.result = .success(value)
        } catch {
            box.result = .failure(error)
        }
        semaphore.signal()
    }
    semaphore.wait()
    return try box.result.get()
}

class resultBox<T> {
    var result: Result<T, Error>!
}

extension LibboxStringIteratorProtocol {
    func toArray() -> [String] {
        var array: [String] = []
        while hasNext() {
            array.append(next())
        }
        return array
    }
}

func createOnDemandRules(from options: LibboxOnDemandRuleIteratorProtocol) throws -> [NEOnDemandRule] {
    var rules: [NEOnDemandRule] = []
    while options.hasNext() {
        let ruleOptions = options.next()!
        var rule: NEOnDemandRule
        switch ruleOptions.target() {
        case 1:
            rule = NEOnDemandRuleConnect()
        case 2:
            rule = NEOnDemandRuleDisconnect()
        case 4:
            rule = NEOnDemandRuleIgnore()
        default:
            throw NSError(domain: "unsupported action type \(ruleOptions.target())", code: 0)
        }
        let dnsSearchDomainMatch = ruleOptions.dnsSearchDomainMatch()!
        if dnsSearchDomainMatch.hasNext() {
            rule.dnsSearchDomainMatch = dnsSearchDomainMatch.toArray()
        }
        let dnsServerAddressMatch = ruleOptions.dnsServerAddressMatch()!
        if dnsServerAddressMatch.hasNext() {
            rule.dnsServerAddressMatch = dnsServerAddressMatch.toArray()
        }
        let interfaceTypeMatch = ruleOptions.interfaceTypeMatch()
        if interfaceTypeMatch != 0 {
            rule.interfaceTypeMatch = NEOnDemandRuleInterfaceType(rawValue: Int(interfaceTypeMatch)) ?? .any
        }
        let ssidMatch = ruleOptions.ssidMatch()!
        if ssidMatch.hasNext() {
            rule.ssidMatch = ssidMatch.toArray()
        }
        let probeURL = ruleOptions.probeURL()
        if !probeURL.isEmpty {
            rule.probeURL = URL(string: probeURL)
        }
        rules.append(rule)
    }
    return rules
}
