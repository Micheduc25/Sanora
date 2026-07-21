import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against "multiple heroes share the same tag within a subtree".
///
/// The tab shell is a `StatefulShellRoute.indexedStack`, so every visited
/// tab's Scaffold stays mounted in one route subtree. Two FloatingActionButtons
/// without an explicit tag both claim `<default FloatingActionButton tag>`, and
/// the next push throws — at navigation time, pointing at whichever screen
/// happened to be pushing, not the one that caused it. A widget test would have
/// to rebuild the whole shell with every branch visited to catch that, so this
/// checks the source instead.

/// Source spans of `widget(...)` constructor calls, named constructors included.
Iterable<String> _constructorBodies(String source, String widget) sync* {
  final name = RegExp('(?<![A-Za-z0-9_])$widget(\\.[a-zA-Z0-9_]+)?\\s*\\(');
  for (final match in name.allMatches(source)) {
    var depth = 0;
    for (var i = match.end - 1; i < source.length; i++) {
      final char = source[i];
      if (char == '(') depth++;
      if (char == ')') {
        depth--;
        if (depth == 0) {
          yield source.substring(match.end, i);
          break;
        }
      }
    }
  }
}

void main() {
  final sources = {
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')))
      file.path: file.readAsStringSync(),
  };

  // Anything that puts a Hero in the tree needs a tag that is unique across
  // every screen that can be mounted at once.
  for (final (widget, parameter) in [
    ('FloatingActionButton', 'heroTag'),
    ('Hero', 'tag'),
  ]) {
    test('every $widget declares a unique $parameter', () {
      final owners = <String, String>{};
      final untagged = <String>[];
      var found = 0;

      sources.forEach((path, source) {
        for (final body in _constructorBodies(source, widget)) {
          found++;
          final tag = RegExp(
            "$parameter:\\s*'([^']+)'",
          ).firstMatch(body)?.group(1);
          if (tag == null) {
            untagged.add(path);
            continue;
          }
          expect(
            owners.containsKey(tag),
            isFalse,
            reason: "'$tag' is claimed by both ${owners[tag]} and $path",
          );
          owners[tag] = path;
        }
      });

      expect(untagged, isEmpty, reason: '$widget without a literal $parameter');
      // The scan is textual, so it has to prove it still sees what it counts:
      // a silently-zero match would pass every assertion above.
      final mentions = sources.values
          .map((s) => RegExp('(?<![A-Za-z0-9_])$widget\\b').allMatches(s).length)
          .fold(0, (sum, n) => sum + n);
      expect(
        found,
        mentions,
        reason: 'parsed $found of $mentions $widget references — scanner stale',
      );
    });
  }
}
