import 'package:sanora/core/widgets/sanora_card.dart';
import 'package:sanora/core/widgets/empty_state.dart';
import 'package:sanora/core/widgets/progress_ring.dart';
import 'package:sanora/core/widgets/stat_tile.dart';
import 'package:sanora/features/onboarding/widgets/onboarding_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('SanoraCard renders child and reacts to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(SanoraCard(onTap: () => tapped = true, child: const Text('hello'))),
    );
    await tester.tap(find.text('hello'));
    expect(tapped, isTrue);
  });

  testWidgets('ProgressRing shows center child and animates', (tester) async {
    await tester.pumpWidget(
      host(const ProgressRing(progress: 0.6, size: 100, child: Text('60'))),
    );
    expect(find.text('60'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('StatTile shows value, label and progress bar', (tester) async {
    await tester.pumpWidget(
      host(
        const StatTile(
          icon: Icons.directions_walk,
          color: Colors.green,
          value: '7,500',
          label: 'steps',
          progress: 0.75,
        ),
      ),
    );
    expect(find.text('7,500'), findsOneWidget);
    expect(find.text('steps'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('EmptyState wires action button', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      host(
        EmptyState(
          icon: Icons.info,
          title: 'Nothing yet',
          message: 'Start now',
          actionLabel: 'Go',
          onAction: () => pressed = true,
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    expect(pressed, isTrue);
  });

  testWidgets('ValueSlider reports changes and shows value', (tester) async {
    double? received;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => ValueSlider(
            value: 70,
            min: 0,
            max: 100,
            unit: 'kg',
            onChanged: (v) => setState(() => received = v),
          ),
        ),
      ),
    );
    expect(find.text('70'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(80, 0));
    expect(received, isNotNull);
  });

  testWidgets('ChoiceCardGroup selects an option', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => ChoiceCardGroup<String>(
            options: const ['One', 'Two'],
            selected: selected,
            onSelected: (v) => setState(() => selected = v),
            titleOf: (v) => v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(selected, 'Two');
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('TagEditor toggles presets and adds free text', (tester) async {
    var values = <String>[];
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: TagEditor(
              values: values,
              presets: const ['Peanuts', 'Eggs'],
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Peanuts'));
    await tester.pump();
    expect(values, ['Peanuts']);

    await tester.enterText(find.byType(TextField), 'Cassava');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(values, ['Peanuts', 'Cassava']);
  });
}
