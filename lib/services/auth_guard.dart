import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final bool isLoggedIn = AuthService().isSignedIn;
    final bool isLoginRoute = state.uri.path == '/' || state.uri.path == '/register';

    // If user is not logged in and not on login/register page, redirect to login
    if (!isLoggedIn && !isLoginRoute) {
      return '/';
    }

    // If user is logged in and on login/register page, redirect to home
    if (isLoggedIn && isLoginRoute) {
      return '/home';
    }

    // No redirect needed
    return null;
  }
}