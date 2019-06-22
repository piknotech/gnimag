//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Event describes an event that can occur at any time, an arbitrary number of times.
/// Events can have an arbitrary number of subscribers.
/// When the event is triggered, all (currently) registered callbacks are executed (synchronously on the same thread).
/// Events are not "retained", so, if an event is fired while having no subscribers, the event is lost.

/// The main difference between an Event<T> and a Promise<T> is that an event can be triggered multiple times with different values, while a promise can just be fullfilled once.

public final class Event<T> {
    public typealias Subscriber = (T) -> Void

    /// All subscribers of the event.
    private var subscribers = [Subscriber]()

    /// Subscribe to the event.
    /// Each time the event is fired, the callback is called – on the same thread from which the event has been triggered. DO NOT block this thread!
    public func subscribe(_ subscriber: @escaping Subscriber) {
        subscribers.append(subscriber)
    }

    /// Remove all subscribers.
    public func unsubscribeAll() {
        subscribers.removeAll()
    }

    /// Syntactic sugar for subscribing to an event.
    public static func += (lhs: Event, rhs: @escaping Subscriber) {
        lhs.subscribe(rhs)
    }

    /// Trigger the event with a value.
    public func trigger(with value: T) {
        for subscriber in subscribers {
            subscriber(value)
        }
    }
}

extension Event where T == Void {
    /// Convenience method to trigger the event.
    public func trigger() {
        trigger(with: ())
    }
}
