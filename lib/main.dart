import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/create_screen.dart';
import 'screens/new_survey.dart';
import 'screens/login_page.dart';
import 'screens/profile_page.dart';
import 'screens/verify_email_screen.dart';
import 'screens/settings_page.dart';
import 'screens/filled_surveys_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // If using FlutterFire CLI, uncomment the following:
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Removed const because some screens require runtime data.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Opinion Rewards',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/verify-email': (context) => VerifyEmailScreen(),
        '/profile': (context) => ProfilePage(),
        '/home': (context) => HomeScreen(),
        '/create-screen': (context) => CreateScreen(),
        '/new-survey': (context) => NewSurvey(),
        '/settings': (context) => SettingsPage(),
        '/filled-surveys': (context) => FilledSurveysScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return HomeScreen();
        }
        return LoginPage();
      },
    );
  }
}