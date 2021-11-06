Support for detecting and being notified when an object is mutated.

There are two kinds of change notifiers:
- ```AsyncChangeNotifier```: be notified of a continuous stream of events over time.
- ```ChangeNotifier```: be notified at the moment of a change. This is a direct extraction of ```ChangeNotifier``` in Flutter Core.

Some suggested uses for this library:

* Observe objects for changes, and log when a change occurs
* Optimize for observable collections in your own APIs and libraries instead of diffing
* Implement simple data-binding by listening to streams

### Usage

There are two general ways to detect changes:

* Listen to `ChangeNotifier.changes` and be notified when an object changes
* Use `Differ.diff` to determine changes between two objects
