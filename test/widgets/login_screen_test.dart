import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:instarecipe/screens/login_screen.dart';
import 'package:instarecipe/services/auth_service.dart';

class MockAuthService extends AuthService {
  bool _isSignedIn = false;
  
  @override
  bool get isSignedIn => _isSignedIn;
  
  @override
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    if (email == 'test@example.com' && password == 'password123') {
      _isSignedIn = true;
      return AuthResult.success(null);
    } else {
      return AuthResult.error('Invalid email or password');
    }
  }
  
  @override
  Future<AuthResult> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (email.contains('@')) {
      return AuthResult.success(null);
    } else {
      return AuthResult.error('Invalid email format');
    }
  }
}

Widget createTestWidget(AuthService authService) {
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: MaterialApp(
      home: const LoginScreen(),
      routes: {
        '/register': (context) => const Scaffold(body: Text('Register Screen')),
        '/home': (context) => const Scaffold(body: Text('Home Screen')),
      },
    ),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('LoginScreen displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Check for main elements
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
      
      // Check for form fields
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      
      // Check for buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
      
      // Check for password visibility toggle
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Email validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Find email field and enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      
      // Try to submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Password validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Enter valid email but no password
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, '123'); // Too short
      
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show password validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Find password field
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');
      
      // Initially password should be obscured
      final textField = tester.widget<TextFormField>(passwordField);
      expect(textField.obscureText, true);
      
      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      
      // Password should now be visible
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('Successful login navigates to home', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Enter valid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      
      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      
      // Show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for login to complete
      await tester.pump(const Duration(milliseconds: 200));
      
      // Should navigate to home screen
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Failed login shows error message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Enter invalid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'wrong@example.com');
      await tester.enterText(passwordField, 'wrongpassword');
      
      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      
      // Wait for login to complete
      await tester.pump(const Duration(milliseconds: 200));
      
      // Should show error message
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('Forgot password dialog works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Tap forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      // Should show forgot password dialog
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email address and we\'ll send you a link to reset your password.'), 
             findsOneWidget);
      
      // Enter email and submit
      final dialogEmailField = find.byType(TextFormField).last;
      await tester.enterText(dialogEmailField, 'test@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      
      // Wait for request to complete
      await tester.pump(const Duration(milliseconds: 200));
      
      // Should show success message
      expect(find.text('Password reset email sent successfully!'), findsOneWidget);
    });

    testWidgets('Navigate to register screen works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Tap sign up link
      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      // Should navigate to register screen
      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('Form submission disabled with empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Try to submit with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Loading state prevents multiple submissions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Enter valid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      
      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      
      // Try to submit again while loading
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      
      // Should only have one loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('App logo and branding are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockAuthService));

      // Check for app branding elements
      expect(find.text('InstaRecipe'), findsAtLeastNWidgets(1));
      
      // Check for any image/icon that represents the logo
      final logoFinders = [
        find.byType(Image),
        find.byIcon(Icons.restaurant),
        find.byIcon(Icons.food_bank),
      ];
      
      bool hasLogo = logoFinders.any((finder) => finder.evaluate().isNotEmpty);
      expect(hasLogo, true, reason: 'App should have some form of logo or branding icon');
    });
  });
} 