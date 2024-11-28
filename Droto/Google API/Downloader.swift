//
//  Downloader.swift
//  Droto
//
//  Created by Kyle Satti on 15/07/2022.
//

import Foundation
import Combine

class Downloader<T>: Publisher {
    typealias Data = TwinDownloadStatus<T>
    typealias Output = DownloadStatus<[Data]>
    typealias Failure = Error
    private typealias Subject = CurrentValueSubject<Output, Failure>
    
    private let requests: [TwinDownloadTask<T>]
    private var subject: Subject?
    private var currentRequest = 0
    private var responses: [Data] = []
    private var observer: AnyCancellable?
    
    init(_ requests: [TwinDownloadTask<T>]) {
        self.requests = requests
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subject: Subject
        
        if let sub = self.subject {
            subject = sub
        } else {
            let sub = Subject(.progressMade(0))
            subject = sub
            nextDownload()
        }
        
        subject.subscribe(subscriber)
    }
    
    private func nextDownload() {
        guard currentRequest < requests.count else {
            subject?.send(.complete(responses))
            subject?.send(completion: .finished)
            return
        }
        
        let progressPerRequest: Double = 1 / Double(requests.count)
        let first = requests[currentRequest]
        
        observer = first.request.combineLatest(first.download)
            .map { [unowned self] response, downloadStatus -> DownloadStatus<Data> in
                switch downloadStatus {
                case .progressMade(let progress):
                    return .progressMade((progressPerRequest * Double(self.currentRequest)) + progress)
                case .complete(let url):
                    return .complete(TwinDownloadStatus(request: response, download: url))
                }
            }.sink { [unowned self] completion in
                self.currentRequest += 1
                switch completion {
                case .finished: self.nextDownload()
                case .failure(let error): self.handleError(error)
                }
            } receiveValue: { [unowned self] output in
                switch output {
                case .progressMade(let progress): self.subject?.send(.progressMade(progress))
                case .complete(let data): self.responses.append(data)
                }
            }
    }
    
    private func handleError(_ error: Error) {
        subject?.send(completion: .failure(error))
    }
}

struct TwinDownloadTask<T> {
    let request: AnyPublisher<T, Error>
    let download: AnyPublisher<DownloadStatus<URL>, Error>
}

struct TwinDownloadStatus<T> {
    let request: T
    let download: URL
}

enum DownloadStatus<Data> {
    case progressMade(Double)
    case complete(Data)
}

class DownloadResultPublisher: NSObject, Publisher, URLSessionDownloadDelegate {
    typealias Output = DownloadStatus<URL>
    typealias Failure = Error
    typealias Subject = CurrentValueSubject<Output, Failure>
    
    private let request: URLRequest
    
    private var subject: Subject?
    private var task: URLSessionDownloadTask?
    
    init(request: URLRequest) {
        self.request = request
    }
    
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subject: Subject
        
        if let sub = self.subject {
            subject = sub
        } else {
            let sub = Subject(.progressMade(0))
            startRequest()
            subject = sub
        }
        
        subject.subscribe(subscriber)
        self.subject = subject
    }
    
    private func startRequest() {
        let session = URLSession.init(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: request)
        task.resume()
        self.task = task
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let subject = subject else {
            fatalError("data recieved but no subject exists")
        }

        subject.send(.complete(location))
        subject.send(completion: .finished)
    }
    
    func urlSession(_ session: URLSession,
                downloadTask: URLSessionDownloadTask,
                didWriteData bytesWritten: Int64,
           totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let subject = subject else {
            fatalError("data recieved but no subject exists")
        }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        subject.send(.progressMade(progress))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        switch error {
        case .some(let error): subject?.send(completion: .failure(DownloadError.sessionError(error)))
        case .none: subject?.send(completion: .failure(DownloadError.unknown))
        }
    }
}

enum DownloadError: Error {
    case unknown
    case sessionError(Error)
    
}
