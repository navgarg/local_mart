import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your custom theme
import 'package:projects/modules/login/theme/theme.dart';

// your screens
import 'package:projects/modules/login/screens/address_details_screen.dart';
import 'package:projects/modules/login/screens/buisness_details_screen.dart';
import 'package:projects/modules/login/screens/map_location_picker_screen.dart';
import 'package:projects/modules/login/screens/role_selection.dart';
import 'firebase_options.dart';

import 'package:projects/modules/login/screens/login_screen.dart';
import 'package:projects/modules/login/screens/signup_screen.dart';
import 'package:projects/modules/login/screens/otp_verification_screen.dart';
import 'package:projects/modules/login/screens/forgot_password_screen.dart';
import 'package:projects/modules/login/screens/verify_reset_otp_screen.dart';
import 'package:projects/modules/login/screens/reset_password_screen.dart';
import 'package:projects/modules/login/screens/password_updated_screen.dart';
import 'package:projects/modules/login/screens/home_screen.dart';
import 'package:projects/modules/login/screens/gender_question_screen.dart';
import 'package:projects/modules/login/screens/age_question_screen.dart';
import 'package:projects/modules/login/screens/mobile_details_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env BEFORE Firebase
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalMart',

      //  Apply your global theme here
      theme: themeData,

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify': (context) => const OtpVerificationScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/forgot-verify': (context) => const VerifyResetOtpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/password-updated': (context) => const PasswordUpdatedScreen(),
        '/home': (context) => const HomeScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/mobile-details': (context) => const MobileDetailsScreen(),
        '/gender-question': (context) => const GenderQuestionScreen(),
        '/age-question': (context) => const AgeQuestionScreen(),
        '/map-location': (context) => const MapLocationPickerScreen(),
        '/address-details': (context) => const AddressDetailsScreen(),
        '/business-details': (context) => const BusinessDetailsScreen(),
      },
    );
  }
}
