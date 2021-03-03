// Copyright © 2018 Piknotech. All rights reserved.

/// A promise is a value that is not yet available, but will be soon - it describes the result of an asynchronous operation.
/// Promises can either yield a result, or fail with an (unspecified) error.
/// You can install multiple success and error handlers, if you want to.
/// A promise must never block the thread on which it is created - it always runs in the background.

/// HOW TO CREATE A PROMISE
/// Create the promise explicitly:
///
/// let promise = Promise<Int>()
/// ... (synchronous code)
/// promise.finished(with: .error) // Signal completion
///
/// When performing a small amount of work synchronously, you can also create and return a promise in a single line:
/// return .success(value: 25) or
/// return .error().

public final class Promise<Result> {
    /// Possible outcomes.
    public indirect enum Outcome {
        case result(Result)
        case error
    }

    // MARK: Initializers

    /// Create an empty promise.
    /// Call "finished(with:)" to signal when the promise has finished.
    public init() {
    }

    /// Create a new, successful promise with a result.
    public static func success<T>(value: T) -> Promise<T> {
        let promise = Promise<T>()
        promise.finished(with: .result(value))
        return promise
    }

    /// Create a new, erroneous promise.
    public static func error<T>() -> Promise<T> {
        let promise = Promise<T>()
        promise.finished(with: .error)
        return promise
    }

    // MARK: Properties

    /// Result and error events.
    private var resultEvent = Event<Result>()
    private var errorEvent = Event<Void>()

    /// The outcome of the promise, when finished.
    public private(set) var outcome: Outcome?

    // MARK: Methods: Finishing

    /// Call when the promise has finished either with a result or with an error.
    /// The callback is executed on the same thread.
    public func finished(with outcome: Outcome) {
        if self.outcome != nil { fatalError("Promise has already been finished") }
        self.outcome = outcome

        // Call the correct handler
        switch outcome {
        case .result(let result):
            resultEvent.trigger(with: result)

        case .error:
            errorEvent.trigger()
        }
    }

    // MARK: Handlers

    /// Add a result handler. The handler may be called on any thread.
    /// If this is called when the promise already has an outcome, the handler is executed immediately.
    /// Returns this promise, so "onError" can be chained immediately.
    @discardableResult
    public func onResult(_ handler: @escaping (Result) -> Void) -> Promise<Result> {
        resultEvent += handler

        // Call success handler if required
        if case .some(.result(let result)) = outcome {
            handler(result)
        }

        return self
    }

    /// Add an error handler. The handler may be called on any thread.
    /// If this is called when the promise already has an outcome, the handler is executed immediately.
    /// Returns this promise, so "onResult" can be chained immediately.
    @discardableResult
    public func onError(_ handler: @escaping () -> Void) -> Promise<Result> {
        errorEvent += handler

        // Call error handler if required
        if case .some(.error) = outcome {
            handler()
        }

        return self
    }

    // MARK: Inter-Promise Actions

    /// Transform the promise so it yields a transformed result.
    /// The new promse can still fail with an error (the transform may fail), even if this promise succeeds.
    /// To indicate that the transform failed, return nil.
    public func transform<OutResult>(by transform: @escaping (Result) -> OutResult?) -> Promise<OutResult> {
        let newPromise = Promise<OutResult>()

        self.onResult {
            if let newResult = transform($0) { // Transform the value of this promise, and notify the new promise
                newPromise.finished(with: .result(newResult))
            } else {
                newPromise.finished(with: .error)
            }
        }

        self.onError {
            newPromise.finished(with: .error)
        }

        return newPromise
    }

    /// Link this promise to another promise, such that, when the other promise finishes, this promise will also finish with the same outcome.
    /// Attention: The other promise will call the "finished" method on this promise. You may not do this yourself – this would yield the promise to finishing multiple times, which results in a fatalError.
    public func replicate(_ other: Promise<Result>) {
        other.onResult { self.finished(with: .result($0)) }
        other.onError { self.finished(with: .error) }
    }
}

// MARK: Success Methods for Promise<Void>

extension Promise where Result == Void {
    /// Convenience method to create a new, successful promise with a void result.
    public static func success() -> Promise<Void> {
        return .success(value: ())
    }
}
