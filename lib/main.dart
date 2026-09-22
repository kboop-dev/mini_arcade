import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/narrator_service.dart';
import 'services/music_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_arcade_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KeylaIanArcadeApp());
}

/// Quita la barra de scroll visible en toda la app (web/desktop), tal como
/// se pidió: que no se vea la barra aunque el contenido sea más largo que
/// la pantalla. El scroll sigue funcionando igual, solo no se dibuja la barrita.
class NoScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // no dibuja ninguna barra de scroll
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class KeylaIanArcadeApp extends StatefulWidget {
  const KeylaIanArcadeApp({super.key});

  @override
  State<KeylaIanArcadeApp> createState() => _KeylaIanArcadeAppState();
}

class _KeylaIanArcadeAppState extends State<KeylaIanArcadeApp> {
  // Se crea UNA sola vez para toda la vida de la app (no por pantalla),
  // así la música no se reinicia al navegar de login -> home -> juegos.
  final MusicService _music = MusicService();

  @override
  void initState() {
    super.initState();
    // Primer intento de reproducir. Puede fallar silenciosamente si el
    // navegador bloqueó el autoplay; por eso también hay un GestureDetector
    // más abajo que reintenta en el primer toque del jugador.
    _music.start();
  }

  @override
  void dispose() {
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NarratorService>(create: (_) => NarratorService()),
        ChangeNotifierProvider<MusicService>.value(value: _music),
      ],
      child: MaterialApp(
        title: 'Arcade Keyla & Ian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        scrollBehavior: NoScrollbarBehavior(),
        home: const AuthGate(),
        // El builder envuelve CUALQUIER pantalla (login, registro, home,
        // cada minijuego) con un detector de toque invisible que reintenta
        // reproducir la música si el navegador bloqueó el autoplay — sin
        // mostrar ningún botón ni ícono encima de las pantallas.
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _music.resumeIfBlocked(),
            child: child,
          );
        },
      ),
    );
  }
}

/// Decide qué pantalla mostrar según si hay sesión activa o no.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const HomeArcadeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
