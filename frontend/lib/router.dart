import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openwhen/screens/auth/login_screen.dart';
import 'package:openwhen/screens/capsule/capsule_detail_screen.dart';
import 'package:openwhen/screens/capsule/new_capsule_screen.dart';
import 'package:openwhen/screens/home/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoginRoute = state.matchedLocation == '/login';
    if (!loggedIn && !isLoginRoute) return '/login';
    if (loggedIn && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/capsule/new', builder: (_, __) => const NewCapsuleScreen()),
    GoRoute(
      path: '/capsule/:id',
      builder: (_, state) => CapsuleDetailScreen(capsuleId: state.pathParameters['id']!),
    ),
  ],
);
