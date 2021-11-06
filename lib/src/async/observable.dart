// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library change_notifier.src.observable;

import 'package:meta/meta.dart';

import 'change_notifier.dart';
import 'records.dart';

/// Represents an object with observable state or properties.
///
/// The interface does not require any specific technique to implement
/// observability. You may implement it in the following ways:
/// - Extend or mixin [AsyncChangeNotifier]
/// - Implement the interface yourself and provide your own implementation
abstract class Observable<C extends ChangeRecord> {
  /// Changes should produced in order, if significant.
  Stream<List<C>> get changes;

  /// May override to be notified when [changes] is first observed.
  @protected
  void observed();

  /// May override to be notified when [changes] is no longer observed.
  @protected
  void unobserved();

  /// True if this object has any observers.
  bool get hasObservers;

  /// If [hasObservers], synchronously emits [changes] that have been queued.
  ///
  /// Returns `true` if changes were emitted.
  bool deliverChanges();

  /// Schedules [change] to be delivered.
  ///
  /// If [change] is omitted then [ChangeRecord.ANY] will be sent.
  ///
  /// If there are no listeners to [changes], this method does nothing.
  void notifyChange([C? change]);
}
