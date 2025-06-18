import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class BottomNavigation extends StatelessWidget {
  final String currentRoute;

  const BottomNavigation({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFf3eae7),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          color: const Color(0xFFfcf9f8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                route: '/home',
                isActive: currentRoute == '/home',
              ),
              _buildNavItem(
                context,
                icon: Icons.shopping_basket_outlined,
                activeIcon: Icons.shopping_basket,
                label: 'Ingredients',
                route: '/search',
                isActive: currentRoute == '/search',
              ),
              _buildNavItem(
                context,
                icon: Icons.bookmark_border,
                activeIcon: Icons.bookmark,
                label: 'Saved',
                route: '/saved',
                isActive: currentRoute == '/saved',
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                route: '/profile',
                isActive: currentRoute == '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive 
                    ? const Color(0xFF1b110d) 
                    : const Color(0xFF9a5e4c),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isActive 
                    ? const Color(0xFF1b110d) 
                    : const Color(0xFF9a5e4c),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.015,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 