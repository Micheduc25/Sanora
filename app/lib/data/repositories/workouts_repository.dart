import 'package:uuid/uuid.dart';

import '../../core/storage/local_store.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout.dart';
import '../sync/sync_service.dart';

class WorkoutsRepository {
  WorkoutsRepository(this._sync);

  final SyncService _sync;

  List<Workout> all() =>
      LocalStore.readAll(LocalStore.workoutsBox, Workout.fromJson)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Workout> completedBetween(DateTime from, DateTime to) => all()
      .where((w) =>
          w.completed &&
          w.completedAt != null &&
          w.completedAt!.isAfter(from) &&
          w.completedAt!.isBefore(to))
      .toList();

  Future<void> save(Workout workout) async {
    await LocalStore.put(LocalStore.workoutsBox, workout.id, workout.toJson());
    await _sync.enqueue('workouts', 'upsert', workout.toJson());
  }

  Future<void> markCompleted(Workout workout) => save(
      workout.copyWith(completed: true, completedAt: DateTime.now()));

  Future<void> remove(String id) async {
    await LocalStore.delete(LocalStore.workoutsBox, id);
    await _sync.enqueue('workouts', 'delete', {'id': id});
  }

  /// Curated fallback library, available offline and used as the base the AI
  /// generator personalizes from.
  static List<Workout> templates() {
    Workout build(String name, WorkoutCategory category, String difficulty,
        int minutes, int kcal, List<WorkoutExercise> exercises) {
      return Workout(
        id: const Uuid().v4(),
        name: name,
        category: category,
        difficulty: difficulty,
        durationMinutes: minutes,
        estimatedCalories: kcal,
        exercises: exercises,
        createdAt: DateTime.now(),
      );
    }

    return [
      build('Full-Body Starter', WorkoutCategory.home, 'Beginner', 20, 140, const [
        WorkoutExercise(
            name: 'Bodyweight squat',
            instructions:
                'Feet shoulder-width apart, chest up. Sit back and down until thighs are parallel to the floor, then drive up through your heels.',
            sets: 3,
            repsOrDuration: '12 reps',
            restSeconds: 45),
        WorkoutExercise(
            name: 'Incline push-up',
            instructions:
                'Hands on a table or wall, body in a straight line. Lower your chest to the edge and press back up. Move to the floor as you get stronger.',
            sets: 3,
            repsOrDuration: '10 reps',
            restSeconds: 45),
        WorkoutExercise(
            name: 'Glute bridge',
            instructions:
                'Lie on your back, knees bent. Squeeze your glutes and lift your hips until your body forms a straight line from knees to shoulders.',
            sets: 3,
            repsOrDuration: '15 reps',
            restSeconds: 45),
        WorkoutExercise(
            name: 'Plank',
            instructions:
                'Forearms on the floor, body straight, glutes tight. Breathe steadily — do not let your hips sag.',
            sets: 3,
            repsOrDuration: '30 seconds',
            restSeconds: 45),
      ]),
      build('Desk Reset', WorkoutCategory.office, 'Beginner', 8, 40, const [
        WorkoutExercise(
            name: 'Neck rolls',
            instructions:
                'Slowly circle your head in each direction. Stop at tight spots and breathe.',
            sets: 1,
            repsOrDuration: '30 seconds each way',
            restSeconds: 0),
        WorkoutExercise(
            name: 'Chair squat',
            instructions:
                'Stand up from your chair without using your hands, sit back down with control. Repeat.',
            sets: 2,
            repsOrDuration: '10 reps',
            restSeconds: 30),
        WorkoutExercise(
            name: 'Desk push-up',
            instructions:
                'Hands on the desk edge, walk your feet back, lower chest to the desk and press away.',
            sets: 2,
            repsOrDuration: '12 reps',
            restSeconds: 30),
        WorkoutExercise(
            name: 'Chest opener stretch',
            instructions:
                'Clasp hands behind your back, lift gently and open your chest. Undoes hours of sitting.',
            sets: 1,
            repsOrDuration: '40 seconds',
            restSeconds: 0),
      ]),
      build('20-Minute Fat Burner', WorkoutCategory.hiit, 'Intermediate', 20, 220, const [
        WorkoutExercise(
            name: 'Jumping jacks',
            instructions: 'Jump feet wide while raising arms overhead; return. Keep a steady rhythm.',
            sets: 4,
            repsOrDuration: '40 seconds',
            restSeconds: 20),
        WorkoutExercise(
            name: 'Squat to press (bodyweight)',
            instructions:
                'Squat down, and as you stand drive your arms overhead. Move fast but with control.',
            sets: 4,
            repsOrDuration: '40 seconds',
            restSeconds: 20),
        WorkoutExercise(
            name: 'Mountain climbers',
            instructions:
                'From a push-up position, drive knees toward your chest alternately. Keep hips level.',
            sets: 4,
            repsOrDuration: '30 seconds',
            restSeconds: 30),
        WorkoutExercise(
            name: 'Burpee (step-back option)',
            instructions:
                'Squat, place hands down, step or jump back to plank, return and stand tall. Step back instead of jumping to lower impact.',
            sets: 4,
            repsOrDuration: '10 reps',
            restSeconds: 40),
      ]),
      build('Strength Foundations', WorkoutCategory.gym, 'Intermediate', 45, 300, const [
        WorkoutExercise(
            name: 'Goblet squat',
            instructions:
                'Hold a dumbbell at your chest. Squat deep keeping your chest tall, elbows inside knees at the bottom.',
            sets: 4,
            repsOrDuration: '8–10 reps',
            restSeconds: 90),
        WorkoutExercise(
            name: 'Dumbbell bench press',
            instructions:
                'Lower the dumbbells to chest level with elbows at ~45°, press up until arms are straight.',
            sets: 4,
            repsOrDuration: '8–10 reps',
            restSeconds: 90),
        WorkoutExercise(
            name: 'Single-arm dumbbell row',
            instructions:
                'One hand on a bench, flat back. Pull the dumbbell to your hip, squeeze your shoulder blade, lower slowly.',
            sets: 4,
            repsOrDuration: '10 reps each side',
            restSeconds: 90),
        WorkoutExercise(
            name: 'Romanian deadlift',
            instructions:
                'Soft knees, hinge at the hips pushing them back, dumbbells sliding down your thighs. Stand tall by squeezing glutes.',
            sets: 3,
            repsOrDuration: '10 reps',
            restSeconds: 90),
        WorkoutExercise(
            name: 'Farmer carry',
            instructions:
                'Heavy dumbbells at your sides, shoulders back, walk tall. Grip, core and posture in one move.',
            sets: 3,
            repsOrDuration: '30 metres',
            restSeconds: 60),
      ]),
      build('Evening Unwind Yoga', WorkoutCategory.yoga, 'Beginner', 15, 60, const [
        WorkoutExercise(
            name: 'Cat–cow',
            instructions:
                'On all fours, alternate arching and rounding your spine with your breath.',
            sets: 1,
            repsOrDuration: '1 minute',
            restSeconds: 0),
        WorkoutExercise(
            name: 'Downward dog',
            instructions:
                'Hands and feet on the floor, hips high. Pedal your heels and relax your neck.',
            sets: 1,
            repsOrDuration: '1 minute',
            restSeconds: 0),
        WorkoutExercise(
            name: 'Low lunge stretch',
            instructions:
                'Step one foot forward, back knee down, sink hips forward. Opens hip flexors shortened by sitting.',
            sets: 1,
            repsOrDuration: '45 seconds each side',
            restSeconds: 0),
        WorkoutExercise(
            name: 'Child\'s pose',
            instructions:
                'Knees wide, hips to heels, arms long. Slow breaths out longer than in.',
            sets: 1,
            repsOrDuration: '2 minutes',
            restSeconds: 0),
      ]),
      build('Brisk Walk Intervals', WorkoutCategory.walking, 'Beginner', 30, 150, const [
        WorkoutExercise(
            name: 'Warm-up walk',
            instructions: 'Easy pace, relaxed shoulders, look ahead.',
            sets: 1,
            repsOrDuration: '5 minutes',
            restSeconds: 0),
        WorkoutExercise(
            name: 'Brisk intervals',
            instructions:
                'Alternate 2 minutes brisk (you can talk but not sing) with 1 minute easy.',
            sets: 7,
            repsOrDuration: '3 minutes per round',
            restSeconds: 0),
        WorkoutExercise(
            name: 'Cool-down walk',
            instructions: 'Ease the pace down and let your breathing settle.',
            sets: 1,
            repsOrDuration: '4 minutes',
            restSeconds: 0),
      ]),
    ];
  }
}
