import BackgroundTasks

class BackgroundTask: BGAppRefreshTask {
    static let taskSchedulerPermittedIdentifier = "org.sagernet.sfi.update_profiles"
    static let taskInterval: TimeInterval = 15 * 60

    static func setup() async throws {
        let success = BGTaskScheduler.shared.register(forTaskWithIdentifier: taskSchedulerPermittedIdentifier, using: nil) { task in
            NSLog("background task started")
            do {
                let success = try updateProfiles()
                try? scheduleUpdate(Date(timeIntervalSinceNow: taskInterval))
                task.setTaskCompleted(success: success)
                NSLog("background task succeed")
            } catch {
                try? scheduleUpdate(nil)
                task.setTaskCompleted(success: false)
                NSLog("background task failed: \(error.localizedDescription)")
            }
            task.expirationHandler = {
                try? scheduleUpdate(nil)
                NSLog("background task expired")
            }
        }
        if !success {
            throw NSError(domain: "register failed", code: 0)
        }
        if try await BGTaskScheduler.shared.pendingTaskRequests().isEmpty {
            var earliestBeginDate: Date? = nil
            if let updatedAt = try oldestUpdated() {
                if updatedAt > Date(timeIntervalSinceNow: -taskInterval) {
                    earliestBeginDate = updatedAt.addingTimeInterval(taskInterval)
                }
            }
            try scheduleUpdate(earliestBeginDate)
        }
    }

    static func scheduleUpdate(_ earliestBeginDate: Date?) throws {
        let request = BGAppRefreshTaskRequest(identifier: taskSchedulerPermittedIdentifier)
        request.earliestBeginDate = earliestBeginDate
        try BGTaskScheduler.shared.submit(request)
    }

    static func oldestUpdated() throws -> Date? {
        let profileManager = try ProfileManager.shared()
        let profiles = try profileManager.listAutoUpdateEnabled()
        return profiles.map { profile in
            profile.lastUpdated!
        }
        .min()
    }

    static func updateProfiles() throws -> Bool {
        let profileManager = try ProfileManager.shared()
        let profiles = try profileManager.listAutoUpdateEnabled()
        var success = true
        for profile in profiles {
            do {
                try profileManager.updateRemoteProfile(profile)
            } catch {
                success = false
            }
        }
        return success
    }
}
