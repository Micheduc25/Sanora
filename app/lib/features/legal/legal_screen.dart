import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/widgets/bodi_card.dart';
import 'legal_content.dart';

/// The documents in docs/legal/, as reachable from inside the app.
///
/// Android's `ViewPermissionUsageActivity` alias and both app stores need the
/// privacy policy to be openable without a signed-in account, so these screens
/// depend on nothing but their own text.
enum LegalDocument {
  privacy('Privacy policy', LegalContent.privacyPolicy),
  terms('Terms of service', LegalContent.termsOfService),
  disclaimer('Health disclaimer', LegalContent.healthDisclaimer);

  const LegalDocument(this.title, this.markdown);

  final String title;
  final String markdown;
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: _render(context, document.markdown),
      ),
    );
  }
}

enum _BlockKind { heading, subheading, paragraph, bullet, numbered }

class _Block {
  const _Block(this.kind, this.text, this.marker);

  final _BlockKind kind;
  final String text;
  final String marker;
}

/// Parses the Markdown subset the legal documents are written in.
///
/// The sources are hard-wrapped at ~78 columns for review in a diff, so a
/// paragraph arrives as several lines; joining them here is what lets the text
/// rewrap to the phone's width instead of breaking mid-sentence.
List<_Block> _parse(String source) {
  final blocks = <_Block>[];
  final buffer = StringBuffer();
  var kind = _BlockKind.paragraph;
  var marker = '';

  void flush() {
    final text = buffer.toString().trim();
    buffer.clear();
    final closing = kind;
    final closingMarker = marker;
    kind = _BlockKind.paragraph;
    marker = '';
    if (text.isEmpty) return;
    blocks.add(_Block(closing, text, closingMarker));
  }

  for (final line in const LineSplitter().convert(source)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flush();
      continue;
    }
    if (trimmed.startsWith('### ')) {
      flush();
      kind = _BlockKind.subheading;
      buffer.write(trimmed.substring(4));
      flush();
      continue;
    }
    if (trimmed.startsWith('## ')) {
      flush();
      kind = _BlockKind.heading;
      buffer.write(trimmed.substring(3));
      flush();
      continue;
    }
    // The document's `#` title is already the app bar title.
    if (trimmed.startsWith('# ')) {
      flush();
      continue;
    }
    if (trimmed.startsWith('- ')) {
      flush();
      kind = _BlockKind.bullet;
      marker = '•';
      buffer.write(trimmed.substring(2));
      continue;
    }
    final numbered = _numberedItem.firstMatch(trimmed);
    if (numbered != null) {
      flush();
      kind = _BlockKind.numbered;
      marker = '${numbered.group(1)}.';
      buffer.write(trimmed.substring(numbered.end));
      continue;
    }
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(trimmed);
  }
  flush();
  return blocks;
}

final _numberedItem = RegExp(r'^(\d+)\. ');
final _inlineSpan = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');

/// Groups the parsed blocks into one [BodiCard] per `##` section, matching how
/// the rest of the app stacks a [SectionHeader] above its content.
List<Widget> _render(BuildContext context, String source) {
  final widgets = <Widget>[];
  var section = <Widget>[];

  void closeSection() {
    if (section.isEmpty) return;
    widgets.add(
      BodiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: section,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 4));
    section = <Widget>[];
  }

  for (final block in _parse(source)) {
    switch (block.kind) {
      case _BlockKind.heading:
        closeSection();
        widgets.add(SectionHeader(block.text));
      case _BlockKind.subheading:
        if (section.isNotEmpty) section.add(const SizedBox(height: 16));
        section.add(_subheading(context, block.text));
        section.add(const SizedBox(height: 8));
      case _BlockKind.paragraph:
        if (section.isNotEmpty) section.add(const SizedBox(height: 10));
        section.add(_prose(context, block.text));
      case _BlockKind.bullet || _BlockKind.numbered:
        if (section.isNotEmpty) section.add(const SizedBox(height: 8));
        section.add(_listItem(context, block));
    }
  }
  closeSection();
  return widgets;
}

Widget _subheading(BuildContext context, String text) {
  final theme = Theme.of(context);
  return Text(text, style: theme.textTheme.titleMedium);
}

Widget _listItem(BuildContext context, _Block block) {
  final theme = Theme.of(context);
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 26,
        child: Text(
          block.marker,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      Expanded(child: _prose(context, block.text)),
    ],
  );
}

/// Renders one block of body text, resolving `**bold**` and backtick spans.
///
/// Unfilled placeholders are tinted so a draft that reaches a build still
/// announces itself rather than shipping a policy that quietly says "TODO".
Widget _prose(BuildContext context, String text) {
  final theme = Theme.of(context);
  final base = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
    height: 1.5,
    color: text.contains('TODO') ? theme.colorScheme.error : null,
  );

  final spans = <InlineSpan>[];
  var index = 0;
  for (final match in _inlineSpan.allMatches(text)) {
    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start)));
    }
    final bold = match.group(1);
    spans.add(
      bold != null
          ? TextSpan(
              text: bold,
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          : TextSpan(
              text: match.group(2),
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
    );
    index = match.end;
  }
  if (index < text.length) spans.add(TextSpan(text: text.substring(index)));

  return Text.rich(TextSpan(children: spans), style: base);
}
