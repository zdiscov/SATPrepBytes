// ErrorHandler.swift – Centralised error logging and display

import Foundation
import SwiftUI
import Combine

// MARK: - App Error

enum AppError: LocalizedError {
    case questionLoadFailed(String)
    case jsonDecodingFailed(String)
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .questionLoadFailed(let reason):
            return "Failed to load questions: \(reason)"
        case .jsonDecodingFailed(let reason):
            return "Data error: \(reason)"
        case .networkUnavailable:
            return "No network connection available."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - ErrorHandler

final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: AppError?
    @Published var isPresenting: Bool = false

    private init() {}

    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else {
                self.currentError = .unknown(error)
            }
            self.isPresenting = true
#if DEBUG
            print("[ErrorHandler] \(self.currentError?.localizedDescription ?? error.localizedDescription)")
#endif
        }
    }

    func handle(_ appError: AppError) {
        DispatchQueue.main.async {
            self.currentError = appError
            self.isPresenting = true
#if DEBUG
            print("[ErrorHandler] \(appError.localizedDescription ?? "")")
#endif
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            self.isPresenting = false
            self.currentError = nil
        }
    }
}
