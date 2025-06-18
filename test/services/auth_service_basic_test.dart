import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instarecipe/services/auth_service.dart';

void main() {
  group('AuthService Basic Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('AuthService is a singleton', () {
      final instance1 = AuthService();
      final instance2 = AuthService();
      expect(identical(instance1, instance2), true);
    });

    test('AuthService extends ChangeNotifier', () {
      expect(authService, isA<ChangeNotifier>());
    });

    test('isSignedIn getter returns boolean', () {
      final isSignedIn = authService.isSignedIn;
      expect(isSignedIn, isA<bool>());
    });

    test('currentUser getter returns User or null', () {
      final user = authService.currentUser;
      expect(user, anyOf(isNull, isA<User>()));
    });

    test('userEmail getter returns String or null', () {
      final email = authService.userEmail;
      expect(email, anyOf(isNull, isA<String>()));
    });

    test('userName getter returns String or null', () {
      final name = authService.userName;
      expect(name, anyOf(isNull, isA<String>()));
    });

    test('userId getter returns String or null', () {
      final id = authService.userId;
      expect(id, anyOf(isNull, isA<String>()));
    });

    test('signOut method exists and can be called', () {
      expect(() => authService.signOut(), returnsNormally);
    });

    test('signUpWithEmailAndPassword method exists', () {
      expect(authService.signUpWithEmailAndPassword, isA<Function>());
    });

    test('signInWithEmailAndPassword method exists', () {
      expect(authService.signInWithEmailAndPassword, isA<Function>());
    });

    test('resetPassword method exists', () {
      expect(authService.resetPassword, isA<Function>());
    });

    test('updateUserProfile method exists', () {
      expect(authService.updateUserProfile, isA<Function>());
    });

    test('deleteAccount method exists', () {
      expect(authService.deleteAccount, isA<Function>());
    });

    test('showErrorDialog static method exists', () {
      expect(AuthService.showErrorDialog, isA<Function>());
    });

    test('showSuccessDialog static method exists', () {
      expect(AuthService.showSuccessDialog, isA<Function>());
    });

    test('notifyListeners can be called', () {
      var listenerCalled = false;
      authService.addListener(() {
        listenerCalled = true;
      });

      authService.notifyListeners();
      expect(listenerCalled, true);
    });
  });
} 