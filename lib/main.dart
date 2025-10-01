import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/register_page.dart';
import 'views/login_page.dart';
import 'views/dashboard_page.dart';
import 'views/credit_cards_page.dart';
import 'firebase_options.dart';
import 'views/transactions_screen.dart';
import 'views/credit_cards_screen.dart';
import 'views/realtime_check_screen.dart';
import 'views/fraud_alert_screen.dart';
import 'views/profile_screen.dart';
import 'views/generate_report_page.dart';
import 'services/fcm_service.dart';
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Handle notification taps globally
  FCMService.handleNotificationTap((alertId, txnId) {
    // Use navigatorKey for global navigation
    navigatorKey.currentState?.pushNamed('/fraudalerts', arguments: {'alertId': alertId, 'txnId': txnId});
  });
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Firebase MVC Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(
              onRegister: () => Navigator.pushReplacementNamed(context, '/register'),
            ),
        '/register': (context) => RegisterPage(
              onBackToLogin: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
        '/dashboard': (context) => const DashboardPage(),
        '/addcards': (context) => const CreditCardsPage(),
        '/freezeunfreeze': (context) => const FreezeUnfreezeScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/realtimecheck': (context) => const RealtimeCheckScreen(),
        '/fraudalerts': (context) => const FraudAlertScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/generate_report': (context) => const GenerateReportPage(),
      },
    );
  }
}
