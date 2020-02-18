//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// Event describes an event that can occur at any time, an arbitrary number of times.
/// Events can have an arbitrary number of subscribers.
/// Each subscriber is associated with an object to allow removing the suscriber lateron.
/// When the event is triggered, all (currently) registered callbacks are executed (synchronously on the same thread).
/// Events are not "retained", i.e. if an event is fired while having no subscribers, the event is lost.
public final class Event<T> {
    public typealias Subscriber = (reference: AnyObject, callback: (T) -> Void)

    /// All subscribers of the event.
    private var subscribers = [Subscriber]()

    /// Default initializer.
    public init() {
    }

    /// Subscribe to the event with a given reference object.
    /// Each time the event is fired, the callback is called – on the same thread from which the event has been triggered. DO NOT block this thread!
    public func subscribe(_ subscriber: Subscriber) {
        subscribers.append(subscriber)
    }

    /// Subscribe to the event, using a default reference object.
    /// Each time the event is fired, the callback is called – on the same thread from which the event has been triggered. DO NOT block this thread!
    public func subscribe(_ callback: @escaping (T) -> Void) {
        subscribe(self • callback)
    }

    /// Unsubscribe all subscribers with the given reference object.
    public func unsubscribe(_ reference: AnyObject) {
        subscribers.removeAll {
            $0.reference === reference
        }
    }

    /// Remove all subscribers.
    public func unsubscribeAll() {
        subscribers.removeAll()
    }

    /// Syntactic sugar for subscribing to an event with a given reference object.
    public static func += (lhs: Event, rhs: Subscriber) {
        lhs.subscribe(rhs)
    }

    /// Syntactic sugar for subscribing to an event using a default reference object.
    public static func += (lhs: Event, rhs: @escaping (T) -> Void) {
        lhs.subscribe(rhs)
    }

    /// Trigger the event with a value.
    public func trigger(with value: T) {
        for subscriber in subscribers {
            subscriber.callback(value)
        }
    }
}

extension Event where T == Void {
    /// Convenience method to trigger the event.
    public func trigger() {
        trigger(with: ())
    }
}

// MARK: Operator
infix operator • : EventSubscriberOperatorPrecedence

precedencegroup EventSubscriberOperatorPrecedence {
    higherThan: AssignmentPrecedence
}

/// Subscribe to an event by calling `event += self • { ... callback }`, for example.
public func •<T>(reference: AnyObject, callback: @escaping (T) -> Void) -> Event<T>.Subscriber {
    return (reference, callback)
}
