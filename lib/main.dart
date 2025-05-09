import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'viewmodels/player_viewmodel.dart';
import 'views/player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize background playback
    await JustAudioBackground.init(
      androidNotificationChannelId:
          'com.example.youtube_music_clone.channel.audio',
      androidNotificationChannelName: 'YouTube Music Clone',
      androidNotificationOngoing: true,
      androidNotificationIcon:
          'mipmap/ic_launcher', // Make sure this resource exists
      androidShowNotificationBadge: true,
      notificationColor: Colors.red,
    );

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(const MyApp());
  } catch (e) {
    print("Error initializing app: $e");
    // Still try to run the app even with initialization errors
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Wrap with ChangeNotifierProvider
      create: (context) => PlayerViewModel(),
      child: MaterialApp(
        title: 'YouTube Music Clone',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.black,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red, // YouTube Music uses red as an accent
            brightness: Brightness.dark,
          ).copyWith(surface: Colors.black),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          textTheme: Typography.whiteMountainView,
          useMaterial3: true,
        ),
        home: const PlayerScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
