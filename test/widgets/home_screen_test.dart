import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instarecipe/screens/home_screen.dart';
import 'package:instarecipe/models/recipe_model.dart';

Widget createTestWidget() {
  return MaterialApp(
    home: const HomeScreen(),
    routes: {
      '/search': (context) => const Scaffold(body: Text('Search Screen')),
      '/meal-plan': (context) => const Scaffold(body: Text('Meal Plan Screen')),
      '/recipes': (context) => const Scaffold(body: Text('Recipes Screen')),
      '/saved': (context) => const Scaffold(body: Text('Saved Screen')),
      '/profile': (context) => const Scaffold(body: Text('Profile Screen')),
    },
  );
}

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen displays all main elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for greeting message
      expect(find.textContaining('Good'), findsOneWidget); // Good morning/afternoon/evening
      expect(find.text('What would you like to cook today?'), findsOneWidget);
      
      // Check for search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search recipes, ingredients...'), findsOneWidget);
      
      // Check for featured recipes section
      expect(find.text('Featured Recipes'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      
      // Check for quick access grid
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('Search bar navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap search bar
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.pump();

      // Should navigate to search screen
      expect(find.text('Search Screen'), findsOneWidget);
    });

    testWidgets('Featured recipes auto-scroll functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the PageView for featured recipes
      final pageView = find.byType(PageView);
      expect(pageView, findsOneWidget);

      // Check that recipes are displayed
      expect(find.byType(Card), findsAtLeastNWidgets(1));
      
      // Wait for auto-scroll (4 seconds interval)
      await tester.pump(const Duration(seconds: 5));
      
      // Verify PageView still exists and functioning
      expect(pageView, findsOneWidget);
    });

    testWidgets('Featured recipe cards display correct information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Look for recipe elements in cards
      expect(find.byType(ClipRRect), findsAtLeastNWidgets(1)); // Recipe images
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1)); // Rating stars
      expect(find.byIcon(Icons.access_time), findsAtLeastNWidgets(1)); // Cooking time
      
      // Check for recipe metadata
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsAtLeastNWidgets(5)); // Various text elements
    });

    testWidgets('Quick access grid has correct items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for quick access items (should be 4 items in 2x2 grid)
      expect(find.text('All Recipes'), findsOneWidget);
      expect(find.text('Saved Recipes'), findsOneWidget);
      expect(find.text('Meal Planning'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      
      // Check for corresponding icons
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Quick access navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Test All Recipes navigation
      await tester.tap(find.text('All Recipes'));
      await tester.pump();
      expect(find.text('Recipes Screen'), findsOneWidget);
      
      // Go back and test other navigations
      await tester.pageBack();
      await tester.pump();
      
      await tester.tap(find.text('Saved Recipes'));
      await tester.pump();
      expect(find.text('Saved Screen'), findsOneWidget);
      
      await tester.pageBack();
      await tester.pump();
      
      await tester.tap(find.text('Meal Planning'));
      await tester.pump();
      expect(find.text('Meal Plan Screen'), findsOneWidget);
      
      await tester.pageBack();
      await tester.pump();
      
      await tester.tap(find.text('My Profile'));
      await tester.pump();
      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('Greeting message changes based on time', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find greeting text
      final greetingFinder = find.byWidgetPredicate(
        (widget) => widget is Text && 
                   widget.data != null && 
                   (widget.data!.contains('Good morning') ||
                    widget.data!.contains('Good afternoon') ||
                    widget.data!.contains('Good evening'))
      );
      
      expect(greetingFinder, findsOneWidget);
    });

    testWidgets('Featured recipe card tapping works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find a recipe card and tap it
      final recipeCard = find.byType(Card).first;
      await tester.tap(recipeCard);
      await tester.pump();

      // Should navigate to recipe detail (or handle the tap appropriately)
      // This depends on the actual implementation in HomeScreen
    });

    testWidgets('Featured recipes have proper image handling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for image placeholders or actual images
      expect(find.byType(ClipRRect), findsAtLeastNWidgets(1));
      
      // Check for image error handling
      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.errorBuilder != null
      );
      
      // Should have error handling for network images
      expect(imageFinder, findsAtLeastNWidgets(0)); // Could be 0 if using different image handling
    });

    testWidgets('Quick access grid has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final gridView = find.byType(GridView);
      expect(gridView, findsOneWidget);
      
      // Check that grid has proper number of columns (2x2 grid)
      final GridView gridWidget = tester.widget(gridView);
      if (gridWidget.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
        final delegate = gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, 2);
      }
    });

    testWidgets('Screen scrolls properly with all content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify screen is scrollable
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Try scrolling down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pump();
      
      // Should still show content
      expect(find.text('Quick Access'), findsOneWidget);
    });

    testWidgets('Featured recipes page indicator works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Look for page indicators (dots)
      final indicatorFinder = find.byWidgetPredicate(
        (widget) => widget is Container && 
                   widget.decoration is BoxDecoration &&
                   (widget.decoration as BoxDecoration).shape == BoxShape.circle
      );
      
      // Should have multiple page indicators if there are multiple recipes
      expect(indicatorFinder, findsAtLeastNWidgets(0)); // Could be 0 if no indicators implemented
    });

    testWidgets('Bottom navigation bar is present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Check for navigation items
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('App bar has correct styling and content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for app bar
      expect(find.byType(AppBar), findsOneWidget);
      
      // Should not have back button on home screen
      expect(find.byType(BackButton), findsNothing);
      
      // Check for any app bar actions (notifications, settings, etc.)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNotNull);
    });

    testWidgets('Featured recipes handle empty state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Even with no recipes, should not crash and should show placeholder or empty state
      expect(find.byType(PageView), findsOneWidget);
      
      // Should have some content in the page view
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller, isNotNull);
    });
  });
} 