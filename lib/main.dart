import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/pro_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/workouts_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(AyoSehatApp(state: state));
}

class AyoSehatApp extends StatelessWidget {
  const AyoSehatApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'AYOSEHAT',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final pages = [
      HomeScreen(onOpenPro: () => setState(() => _index = 3)),
      const ScheduleScreen(),
      const WorkoutsScreen(),
      const ProScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: st.conflicts.isNotEmpty,
              label: Text('${st.conflicts.length}'),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            selectedIcon: const Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          const NavigationDestination(
              icon: Icon(Icons.ondemand_video_outlined),
              selectedIcon: Icon(Icons.ondemand_video),
              label: 'Latihan'),
          const NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium),
              label: 'Pro'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}
