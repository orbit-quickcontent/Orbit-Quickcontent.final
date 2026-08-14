import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050505),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try { await Firebase.initializeApp(); } catch (_) {}

  runApp(const ProviderScope(child: OrbitPartnerApp()));
}

class OrbitPartnerApp extends ConsumerWidget {
  const OrbitPartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(partnerRouterProvider);
    return MaterialApp.router(
      title: 'ORBIT Partner',
      debugShowCheckedModeBanner: false,
      theme: OrbitPartnerTheme.theme,
      routerConfig: router,
    );
  }
}
