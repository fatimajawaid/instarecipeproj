import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_recipes_screen.dart';
import 'screens/create_recipe_screen.dart';
import 'screens/meal_selection_screen.dart';
import 'screens/grocery_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/offline_search_screen.dart';
import 'services/recipe_data_service.dart';
import 'services/auth_service.dart';
import 'services/auth_guard.dart';
import 'services/offline_cache_service.dart';
import 'models/recipe_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase service
  await FirebaseService().initialize();
  
  // Initialize connectivity monitoring
  ConnectivityService().initialize();
  
  // Initialize offline cache service
  await OfflineCacheService().initialize();
  
  // Initialize recipe data service
  await RecipeDataService().initializeData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InstaRecipe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFef6a42), // Primary orange color from design
        ),
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans',
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Router configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: AuthGuard.redirect,
  routes: [
    GoRoute(
      path: '/',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/meal-plan',
      name: 'meal-plan',
      builder: (context, state) => const MealPlanScreen(),
    ),
    GoRoute(
      path: '/recipe-detail',
      name: 'recipe-detail',
      builder: (context, state) {
        final from = state.uri.queryParameters['from'] ?? 'recipes';
        final extra = state.extra as Map<String, dynamic>?;
        final recipe = extra?['recipe'] as Recipe?;
        return RecipeDetailScreen(from: from, recipe: recipe);
      },
    ),
    GoRoute(
      path: '/recipes',
      name: 'recipes',
      builder: (context, state) => const RecipesScreen(),
    ),
    GoRoute(
      path: '/saved',
      name: 'saved',
      builder: (context, state) => const SavedScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/my-recipes',
      name: 'my-recipes',
      builder: (context, state) => const MyRecipesScreen(),
    ),
    GoRoute(
      path: '/create-recipe',
      name: 'create-recipe',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final recipe = extra?['recipe'] as Recipe?;
        return CreateRecipeScreen(recipe: recipe);
      },
    ),
    GoRoute(
      path: '/meal-selection',
      name: 'meal-selection',
      builder: (context, state) {
        final dateParam = state.uri.queryParameters['date'];
        final mealType = state.uri.queryParameters['mealType'] ?? 'breakfast';
        final date = dateParam != null 
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(dateParam))
            : DateTime.now();
        return MealSelectionScreen(date: date, mealType: mealType);
      },
    ),
    GoRoute(
      path: '/grocery-list',
      name: 'grocery-list',
      builder: (context, state) => const GroceryListScreen(),
    ),
    GoRoute(
      path: '/offline-search',
      name: 'offline-search',
      builder: (context, state) => const OfflineSearchScreen(),
    ),
  ],
);

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
