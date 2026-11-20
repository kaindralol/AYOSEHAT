import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Menyediakan [AppState] ke seluruh widget tanpa package tambahan.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Dipakai di build(): widget ikut diperbarui saat data berubah.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Dipakai di callback (onPressed dsb.).
  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget
              as AppScope)
          .notifier!;
}
