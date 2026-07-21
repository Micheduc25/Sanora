import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        Text(title, style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        ...children,
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Row(
        children: [
          Text(text, style: theme.textTheme.titleSmall),
          if (optional) ...[
            const SizedBox(width: 6),
            Text(
              L.of(context).onboardingOptional,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Big-value slider — the primary numeric input in onboarding, so users
/// never have to type numbers.
class ValueSlider extends StatelessWidget {
  const ValueSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.unit,
    this.decimals = 0,
    this.step,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String unit;
  final int decimals;
  final double? step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divisions = step == null ? null : ((max - min) / step!).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toStringAsFixed(decimals),
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(unit, style: theme.textTheme.titleMedium),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ChoiceCardGroup<T> extends StatelessWidget {
  const ChoiceCardGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.titleOf,
    this.subtitleOf,
    this.emojiOf,
  });

  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) titleOf;
  final String Function(T)? subtitleOf;
  final String Function(T)? emojiOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: option == selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                onTap: () => onSelected(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: option == selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: option == selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (emojiOf != null) ...[
                        Text(
                          emojiOf!(option),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleOf(option),
                              style: theme.textTheme.titleMedium,
                            ),
                            if (subtitleOf != null)
                              Text(
                                subtitleOf!(option),
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (option == selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Preset chips plus a free-text field; used for conditions, allergies,
/// favorite foods and similar open lists.
class TagEditor extends StatefulWidget {
  const TagEditor({
    super.key,
    required this.values,
    required this.onChanged,
    this.presets = const [],
    this.hint,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final List<String> presets;

  /// Localized by the caller; null simply leaves the field without a hint.
  final String? hint;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(String value) {
    final next = List<String>.from(widget.values);
    next.contains(value) ? next.remove(value) : next.add(value);
    widget.onChanged(next);
  }

  void _addFreeText(String text) {
    final value = text.trim();
    if (value.isEmpty || widget.values.contains(value)) return;
    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.values
        .where((v) => !widget.presets.contains(v))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in widget.presets)
              FilterChip(
                label: Text(preset),
                selected: widget.values.contains(preset),
                onSelected: (_) => _toggle(preset),
                showCheckmark: false,
              ),
            for (final value in custom)
              // No onPressed: a custom tag is already selected, so the only
              // meaningful interaction is removing it via the delete icon.
              InputChip(
                label: Text(value),
                selected: true,
                showCheckmark: false,
                onDeleted: () => _toggle(value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addFreeText(_controller.text),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: _addFreeText,
        ),
      ],
    );
  }
}
