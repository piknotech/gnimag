import GameKit

let a = PolyTracker(degree: 2)
a.add(value: 1, at: 0)
a.add(value: 2, at: 1)
a.add(value: 1, at: 2)
print(a.regression)
