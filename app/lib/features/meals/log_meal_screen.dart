import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/error/failures.dart';
import '../../core/widgets/bodi_card.dart';
import '../../domain/models/food_item.dart';
import '../../l10n/app_localizations.dart';
import 'meal_detail_sheet.dart';
import 'meals_controller.dart';

class LogMealScreen extends HookConsumerWidget {
  const LogMealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(0);
    final analyzing = useState(false);
    final theme = Theme.of(context);
    final l = L.of(context);

    Future<void> analyze(Future<dynamic> Function() run) async {
      analyzing.value = true;
      try {
        final meal = await run();
        if (context.mounted && meal != null) {
          await showMealDetailSheet(context, meal, editable: true);
        }
      } on Failure catch (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(f.message)));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.mealsAnalyzeError)));
        }
      } finally {
        analyzing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.mealsLogTitle)),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: Text(l.mealsTabPhoto),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: const Icon(Icons.edit_note_rounded),
                      label: Text(l.mealsTabDescribe),
                    ),
                    ButtonSegment(
                      value: 2,
                      icon: const Icon(Icons.search_rounded),
                      label: Text(l.mealsTabSearch),
                    ),
                  ],
                  selected: {tab.value},
                  onSelectionChanged: (s) => tab.value = s.first,
                ),
              ),
              Expanded(
                child: switch (tab.value) {
                  0 => _PhotoTab(
                    onPick: (file) => analyze(
                      () => ref
                          .read(mealsControllerProvider)
                          .analyzePhoto(file, l),
                    ),
                  ),
                  1 => _DescribeTab(
                    onSubmit: (text) => analyze(
                      () => ref
                          .read(mealsControllerProvider)
                          .analyzeDescription(text, l),
                    ),
                  ),
                  _ => const _SearchTab(),
                },
              ),
            ],
          ),
          if (analyzing.value)
            Container(
              color: theme.colorScheme.scrim.withValues(alpha: 0.35),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 18),
                        Text(
                          l.mealsAnalyzing,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({required this.onPick});

  final void Function(File) onPick;

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (file != null) onPick(File(file.path));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.mealsPhotoIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        BodiCard(
          onTap: () => _pick(ImageSource.camera),
          child: Row(
            children: [
              Icon(
                Icons.photo_camera_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l.mealsTakePhoto,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BodiCard(
          onTap: () => _pick(ImageSource.gallery),
          child: Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l.mealsChooseFromGallery,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _DescribeTab extends HookWidget {
  const _DescribeTab({required this.onSubmit});

  final void Function(String) onSubmit;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final speech = useMemoized(SpeechToText.new);
    final listening = useState(false);
    final theme = Theme.of(context);
    final l = L.of(context);

    Future<void> toggleListening() async {
      if (listening.value) {
        await speech.stop();
        listening.value = false;
        return;
      }
      final available = await speech.initialize();
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.mealsVoiceUnavailable)));
        }
        return;
      }
      listening.value = true;
      await speech.listen(
        onResult: (result) {
          controller.text = result.recognizedWords;
          if (result.finalResult) listening.value = false;
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.mealsDescribeIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l.mealsDescribeHint,
            suffixIcon: IconButton(
              icon: Icon(
                listening.value ? Icons.stop_rounded : Icons.mic_rounded,
                color: listening.value ? theme.colorScheme.error : null,
              ),
              onPressed: toggleListening,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(l.mealsEstimateNutrition),
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) onSubmit(text);
          },
        ),
      ],
    );
  }
}

class _SearchTab extends HookConsumerWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState('');
    final results = ref.watch(foodSearchProvider(query.value));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: L.of(context).mealsSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (v) => query.value = v,
          ),
        ),
        Expanded(
          child: results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(messageFor(e))),
            data: (foods) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return _FoodRow(food: food);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodRow extends ConsumerWidget {
  const _FoodRow({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final servingKcal =
        food.nutritionPer100g.calories * food.typicalServingG / 100;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(food.name),
      subtitle: Text(
        L
            .of(context)
            .mealsFoodSubtitle(
              food.region,
              food.servingLabel.isEmpty
                  ? '${food.typicalServingG.round()}g'
                  : food.servingLabel,
              servingKcal.round(),
            ),
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.add_circle_outline_rounded),
      onTap: () {
        final meal = ref.read(mealsControllerProvider).draftFromFood(food);
        showMealDetailSheet(context, meal, editable: true);
      },
    );
  }
}
