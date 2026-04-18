import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProcessingProgressState {
  final int current;
  final int total;
  final bool active;

  const ProcessingProgressState({
    required this.current,
    required this.total,
    required this.active,
  });

  ProcessingProgressState copyWith({int? current, int? total, bool? active}) =>
      ProcessingProgressState(
        current: current ?? this.current,
        total: total ?? this.total,
        active: active ?? this.active,
      );

  double get fraction => total > 0 ? current / total : 0.0;
}

class ProcessingProgressNotifier
    extends StateNotifier<ProcessingProgressState> {
  ProcessingProgressNotifier()
      : super(
            const ProcessingProgressState(current: 0, total: 0, active: false));

  void start(int total) =>
      state = ProcessingProgressState(current: 0, total: total, active: true);

  void advance() =>
      state = state.copyWith(current: (state.current + 1).clamp(0, state.total));

  void finish() => state = state.copyWith(active: false);
}

final processingProgressProvider =
    StateNotifierProvider<ProcessingProgressNotifier, ProcessingProgressState>(
  (ref) => ProcessingProgressNotifier(),
);
