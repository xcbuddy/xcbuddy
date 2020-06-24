import Foundation
import RxSwift
import TSCBasic
import TuistSupport

enum FileUploaderError: LocalizedError, FatalError {
    case unreachableFileSize(String)
    case urlSessionError(String, Error)
    case serverSideError(String, HTTPURLResponse)
    case invalidResponse(String)

    // MARK: - FatalError

    public var description: String {
        switch self {
        case let .unreachableFileSize(path): return "Could not get the file size at path \(path)"
        case let .urlSessionError(path, error):
            let output = "Received a session error while uploading file at path \(path)"
            if let error = error as? LocalizedError {
                return "\(output). Error: \(error.localizedDescription)"
            } else {
                return output
            }
        case let .invalidResponse(path): return "Received unexpected response from the network while uploading file at path \(path)"
        case let .serverSideError(path, response):
            return "Got error code: \(response.statusCode) returned by the server, when uploading file at path \(path). (String, HTTPURLResponse: \(response.description)"
        }
    }

    var type: ErrorType {
        switch self {
        case .unreachableFileSize: return .abort
        case .urlSessionError: return .bug
        case .serverSideError: return .bug
        case .invalidResponse: return .bug
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? { description }
}

public protocol FileUploading {
    func upload(file: AbsolutePath, hash: String, to url: URL) -> Single<Bool>
}

public class FileUploader: FileUploading {
    // MARK: - Attributes

    let session: URLSession
    let fileManager: FileManager

    // MARK: - Init

    public init(session: URLSession = URLSession.shared,
                fileManager: FileManager = FileManager.default) {
        self.session = session
        self.fileManager = fileManager
    }

    // MARK: - Public

    public func upload(file: AbsolutePath, hash _: String, to url: URL) -> Single<Bool> {
        Single<Bool>.create { observer -> Disposable in
            do {
                let filePath = file.pathString
                let fileSize = try self.fileSize(path: filePath)
                let fileData = try Data(contentsOf: file.url)

                let request = self.uploadRequest(url: url, fileSize: fileSize, data: fileData)
                let uploadTask = self.session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        observer(.error(FileUploaderError.urlSessionError(filePath, error)))
                    } else if let data = data, let response = response as? HTTPURLResponse {
                        print(response)
                        print("data: " + (String(data: data, encoding: .utf8) ?? ""))

                        switch response.statusCode {
                        case 200 ..< 300:
                            observer(.success(true))
                        default: // Error
                            observer(.error(FileUploaderError.serverSideError(filePath, response)))
                        }
                    } else {
                        observer(.error(FileUploaderError.invalidResponse(filePath)))
                    }
                }
                uploadTask.resume()
                return Disposables.create { uploadTask.cancel() }
            } catch {
                observer(.error(error))
            }
            return Disposables.create {}
        }
    }

    // MARK: - Private

    private func uploadRequest(url: URL, fileSize: UInt64, data: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
        request.setValue(String(fileSize), forHTTPHeaderField: "Content-Length")
        request.setValue("zip", forHTTPHeaderField: "Content-Encoding")
        request.httpBody = data
        return request
    }

    private func fileSize(path: String) throws -> UInt64 {
        let attr = try fileManager.attributesOfItem(atPath: path)
        guard let size = attr[FileAttributeKey.size] as? UInt64 else { throw FileUploaderError.unreachableFileSize(path) }
        return size
    }
}
