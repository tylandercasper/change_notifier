// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library change_notifier.test.observable_test_utils;

import 'package:change_notifier/change_notifier.dart';
import 'package:test/test.dart';

/// A small method to help readability. Used to cause the next "then" in a chain
/// to happen in the next microtask:
///
///     future.then(newMicrotask).then(...)
Future<Object?> newMicrotask(Object? _) => Future<Object?>.value();

void expectChanges(List<ChangeRecord> actual, List<ChangeRecord> expected,
    {String? reason}) {
  expect(actual, _EqualsMatcher(expected), reason: reason);
}

void expectNotChanges(List<ChangeRecord> actual, ChangeRecords expectedNot,
    {String? reason}) {
  expect(actual, isNot(_EqualsMatcher(expectedNot)), reason: reason);
}

List<ListChangeRecord<E>> getListChangeRecords<E>(
        List<ListChangeRecord<E>> changes, int index) =>
    List.from(changes.where((ListChangeRecord<E> c) => c.indexChanged(index)));

List<PropertyChangeRecord<Object?, Symbol>> getPropertyChangeRecords(
    List<ChangeRecord> changes, Symbol property) {
  return List.from(changes
      .whereType<PropertyChangeRecord<Object?, Symbol>>()
      .where((PropertyChangeRecord<Object?, Symbol> c) => c.name == property));
}

List<Matcher> changeMatchers(List<ChangeRecord> changes) => changes
    .map((r) => r is PropertyChangeRecord
        ? _PropertyChangeMatcher(r as PropertyChangeRecord<Object?, Symbol>)
        : equals(r))
    .toList();

// Custom equality matcher is required, otherwise expect() infers ChangeRecords
// to be an iterable and does a deep comparison rather than use the == operator.
class _EqualsMatcher<ValueType> extends Matcher {
  final ValueType _expected;

  _EqualsMatcher(this._expected);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      item is ChangeRecords && _expected == item;
}

class _PropertyChangeMatcher<ValueType, K> extends Matcher {
  final PropertyChangeRecord<ValueType, K> _expected;

  _PropertyChangeMatcher(this._expected);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  bool matches(dynamic other, Map<dynamic, dynamic> matchState) =>
      identical(_expected, other) ||
      other is PropertyChangeRecord &&
          _expected.runtimeType == other.runtimeType &&
          _expected.name == other.name &&
          _expected.oldValue == other.oldValue &&
          _expected.newValue == other.newValue;
}
