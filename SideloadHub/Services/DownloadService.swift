import Foundation

@MainActor
final class DownloadService: NSObject, ObservableObject {
    @Published private(set) var downloads: [String: AppDownloadProgress] = [:]

    private var tasks: [String: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func download(app: HubAppItem, from url: URL) {
        downloads[app.id] = AppDownloadProgress(
            id: app.id,
            appName: app.name,
            progress: 0,
            state: .downloading,
            localFileURL: nil,
            errorMessage: nil
        )

        let task = session.downloadTask(with: url)
        tasks[app.id] = task
        task.taskDescription = app.id
        task.resume()
    }

    func localFileURL(for appId: String) -> URL? {
        downloads[appId]?.localFileURL
    }
}

extension DownloadService: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let appId = downloadTask.taskDescription else { return }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("IPAs", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let destination = folder.appendingPathComponent("\(appId).ipa")
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            Task { @MainActor in
                downloads[appId]?.localFileURL = destination
                downloads[appId]?.state = .finished
                downloads[appId]?.progress = 1
            }
        } catch {
            Task { @MainActor in
                downloads[appId]?.state = .failed
                downloads[appId]?.errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let appId = downloadTask.taskDescription, totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            downloads[appId]?.progress = progress
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let appId = task.taskDescription, let error else { return }
        Task { @MainActor in
            if downloads[appId]?.state != .finished {
                downloads[appId]?.state = .failed
                downloads[appId]?.errorMessage = error.localizedDescription
            }
        }
    }
}
