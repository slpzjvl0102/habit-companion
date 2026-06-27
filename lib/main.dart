import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/child_screen.dart';
import 'screens/parent_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.boot();
  runApp(HabitCompanionApp(state: state));
}

class HabitCompanionApp extends StatelessWidget {
  final AppState state;
  const HabitCompanionApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        title: 'Habit Companion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _parentUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // FIX (eng HIGH-2): re-run day rollover on resume; Flutter does not
    // re-run main()/boot() when the app returns from background.
    if (lifecycle == AppLifecycleState.resumed) {
      context.read<AppState>().refresh();
    }
  }

  void _select(int i) {
    setState(() {
      _index = i;
      if (i != 1) _parentUnlocked = false; // re-lock parent tab on leave
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const ChildScreen(),
          ParentScreen(
            unlocked: _parentUnlocked,
            onUnlocked: () => setState(() => _parentUnlocked = true),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: '아이'),
          NavigationDestination(
              icon: Icon(Icons.shield_outlined), label: '부모'),
        ],
      ),
    );
  }
}
