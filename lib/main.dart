import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:projects/screens/address_details_screen.dart' ;
import 'package:projects/screens/buisness_details_screen.dart';
import 'package:projects/screens/map_location_picker_screen.dart';
import 'package:projects/screens/role_selection.dart';
import 'firebase_options.dart';



// your screens
import 'package:projects/screens/login_screen.dart';
import 'package:projects/screens/signup_screen.dart';
import 'package:projects/screens/otp_verification_screen.dart';
import 'package:projects/screens/forgot_password_screen.dart';
import 'package:projects/screens/verify_reset_otp_screen.dart';
import 'package:projects/screens/reset_password_screen.dart';
import 'package:projects/screens/password_updated_screen.dart';
import 'package:projects/screens/home_screen.dart';
import 'package:projects/screens/gender_question_screen.dart';
import 'package:projects/screens/age_question_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(
        useMaterial3: true,
      ),

      // 👇 Login screen shows first
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
        '/gender-question': (context) => const GenderQuestionScreen(),
        '/age-question': (context) => const AgeQuestionScreen(),
        '/map-location': (context) => const MapLocationPickerScreen(),
        '/address-details': (context) => const AddressDetailsScreen(),
        '/business-details': (context) => const BusinessDetailsScreen(),
      },
    );
  }
}


