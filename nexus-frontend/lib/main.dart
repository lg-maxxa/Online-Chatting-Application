import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/socket_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexusChatApp());
}

class NexusChatApp extends StatelessWidget {
  const NexusChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: MaterialApp(
        title: 'NexusChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // ── Routes ──────────────────────────────────────────────────────
        initialRoute: '/',
        routes: {
          '/': (ctx) => const _Splash(),
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          RegisterScreen.routeName: (ctx) => const RegisterScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
          ProfileScreen.routeName: (ctx) => const ProfileScreen(),
        },
      ),
    );
  }
}

/// Splash screen that decides where to route on startup.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final auth = context.read<AuthService>();
    bool loggedIn = false;
    try {
      loggedIn = await auth.tryAutoLogin();
    } catch (_) {
      loggedIn = false;
    }

    if (!mounted) return;
    if (loggedIn) {
      // Connect socket on auto-login
      final socket = context.read<SocketService>();
      socket.connect(auth.currentUser!.id, auth.token!);
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'NexusChat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with anyone, anywhere.',
              style: TextStyle(
                  color: Colors.white.withAlpha(204), fontSize: 15),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
