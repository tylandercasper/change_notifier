// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:change_notifier/change_notifier.dart';
import 'package:test/test.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

void main() => listChangeTests();

// TODO(jmesserly): port or write array fuzzer tests
void listChangeTests() {
  StreamSubscription<Object>? sub;
  ObservableList<int>? model;

  tearDown(() {
    sub?.cancel();
    model = null;
  });

  ListChangeRecord<E> _delta<E>(int i, List<E> r, int a,
          {ObservableList<E>? typedModel}) =>
      ListChangeRecord((typedModel ?? model!) as List<E>, i,
          removed: r, addedCount: a);

  test('sequential adds', () {
    final model = ObservableList<int>()..add(0);

    List<ListChangeRecord<Object>>? summary;
    sub = model.listChanges.listen((r) => summary = r);

    model
      ..add(1)
      ..add(2);

    expect(summary, null);
    return Future(() {
      expect(summary, [_delta<int>(1, [], 2, typedModel: model)]);
      expect(summary![0].added, [1, 2]);
      expect(summary![0].removed, <Object>[]);
    });
  });

  test('List Splice Truncate And Expand With Length', () async {
    final model =
        ObservableList<String?>.from(<String>['a', 'b', 'c', 'd', 'e']);

    List<ListChangeRecord<String?>>? summary;
    sub = model.listChanges.listen((r) => summary = r);

    model.length = 2;

    await model.listChanges.first;

    expect(summary, [
      _delta(2, ['c', 'd', 'e'], 0, typedModel: model)
    ]);
    expect(summary![0].added, <Object>[]);
    expect(summary![0].removed, ['c', 'd', 'e']);
    summary = null;
    model.length = 5;

    await model.listChanges.first;

    expect(summary, [_delta<String?>(2, [], 3, typedModel: model)]);
    expect(summary![0].added, [null, null, null]);
    expect(summary![0].removed, <Object>[]);
  });

  group('List deltas can be applied', () {
    void applyAndCheckDeltas<E>(ObservableList<E> model, List<E> copy,
            Future<List<ListChangeRecord<E>>> changes) =>
        changes.then((summary) {
          // apply deltas to the copy
          for (ListChangeRecord<E> delta in summary) {
            delta.apply(copy);
          }

          expect('$copy', '$model', reason: 'summary $summary');
        });

    test('Contained', () {
      final model = toObservable(['a', 'b']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeAt(1)
        ..insertAll(0, ['c', 'd', 'e'])
        ..removeRange(1, 3)
        ..insert(1, 'f');

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Delete Empty', () {
      final model = toObservable(<Object>[1]) as ObservableList<Object>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeAt(0)
        ..insertAll(0, ['a', 'b', 'c']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Non Overlap', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeRange(0, 1)
        ..insert(0, 'e')
        ..removeRange(2, 3)
        ..insertAll(2, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Non Overlap', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeRange(3, 4)
        ..insertAll(3, ['f', 'g'])
        ..removeRange(0, 1)
        ..insert(0, 'e');

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Adjacent', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeRange(1, 2)
        ..insert(3, 'e')
        ..removeRange(2, 3)
        ..insertAll(0, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Adjacent', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeRange(2, 4)
        ..insert(2, 'e')
        ..removeAt(1)
        ..insertAll(1, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Right Overlap', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeAt(1)
        ..insert(1, 'e')
        ..removeAt(1)
        ..insertAll(1, ['f', 'g']);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Left Overlap', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeAt(2)
        ..insertAll(2, ['e', 'f', 'g'])
        // a b [e f g] d
        ..removeRange(1, 3)
        ..insertAll(1, ['h', 'i', 'j']);
      // a [h i j] f g d

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Prefix And Suffix One In', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..insert(0, 'z')
        ..add('z');

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Remove First', () {
      final model = toObservable([16, 15, 15]) as ObservableList<int>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model.removeAt(0);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Update Remove', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model
        ..removeAt(2)
        ..insertAll(2, ['e', 'f', 'g']); // a b [e f g] d
      model[0] = 'h';
      model.removeAt(1);

      return applyAndCheckDeltas(model, copy, changes);
    });

    test('Remove Mid List', () {
      final model =
          toObservable(['a', 'b', 'c', 'd']) as ObservableList<String>;
      final copy = model.toList();
      final changes = model.listChanges.first;

      model.removeAt(2);

      return applyAndCheckDeltas(model, copy, changes);
    });
  });

  group('edit distance', () {
    void assertEditDistance<E>(ObservableList<E> orig,
            Future<List<ListChangeRecord<E>>> changes, E expectedDist) =>
        changes.then((summary) {
          var actualDistance = 0;

          for (final delta in summary) {
            actualDistance += delta.addedCount + delta.removed.length;
          }

          expect(actualDistance, expectedDist);
        });

    test('add items', () {
      final model = toObservable(<int>[]) as ObservableList<int>;
      final changes = model.listChanges.first;
      model.addAll([1, 2, 3]);
      return assertEditDistance(model, changes, 3);
    });

    test('trunacte and add, sharing a contiguous block', () {
      final model = toObservable(['x', 'x', 'x', 'x', '1', '2', '3'])
          as ObservableList<String>;
      final changes = model.listChanges.first;
      model
        ..length = 0
        ..addAll(['1', '2', '3', 'y', 'y', 'y', 'y']);
      return assertEditDistance(model, changes, 8);
    });

    test('truncate and add, sharing a discontiguous block', () {
      final model =
          toObservable(['1', '2', '3', '4', '5']) as ObservableList<String>;
      final changes = model.listChanges.first;
      model
        ..length = 0
        ..addAll(['a', '2', 'y', 'y', '4', '5', 'z', 'z']);
      return assertEditDistance(model, changes, 7);
    });

    test('insert at beginning and end', () {
      final model = toObservable([2, 3, 4]) as ObservableList<int>;
      final changes = model.listChanges.first;
      model.insert(0, 5);
      model[2] = 6;
      model.add(7);
      return assertEditDistance(model, changes, 4);
    });
  });
}
