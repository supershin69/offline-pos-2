import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/auth/data/auth_bloc.dart';
import 'package:offline_pos/features/auth/repositories/auth_service.dart';
import 'package:offline_pos/features/auth/views/login_screen.dart';
import 'package:offline_pos/features/categories/data/category_bloc.dart';
import 'package:offline_pos/features/categories/repositories/category_repository.dart';
import 'package:offline_pos/features/products/data/product_bloc.dart';
import 'package:offline_pos/features/products/repositories/product_repository.dart';
import 'package:offline_pos/features/users/repositories/user_service.dart';
import 'package:offline_pos/main_wrapper.dart';

// Late final variables
late final AppDatabase db;
late final UserService userService;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Database နှင့် UserService ကို main() ထဲတွင်မှ စတင် Initialize ပြုလုပ်ခြင်း
  db = AppDatabase();
  userService = UserService(db);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: db),
        RepositoryProvider<ProductRepository>(
          create: (context) => ProductRepository(db),
        ),
        RepositoryProvider<AuthService>(
          create: (context) => AuthService(db),
        ),
        RepositoryProvider<CategoryRepository>(
          create: (context) => CategoryRepository(db),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc()..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) =>
                ProductBloc(context.read<ProductRepository>())
                  ..add(MonitorProductStarted()),
          ),
          BlocProvider(
            create: (context) =>
                CategoryBloc(context.read<CategoryRepository>())
                  ..add(MonitorCategoriesStarted()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
        // Syntax error ပြင်ဆင်ထားသည် (ColorScheme.fromSeed)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return MainWrapper(user: state.user);
          }

          if (state is Unauthenticated) {
            return LoginScreen(db: db);
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class TestDataTableScreen extends StatelessWidget {
  const TestDataTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Local DB test")),
      body: StreamBuilder<List<User>>(
        stream: db.select(db.users).watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Users in the Table"));
          }

          final userList = snapshot.data!;

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(user.name),
                subtitle: Text('${user.email} (${user.role})'),
                trailing: Text(user.id.length >= 5 ? user.id.substring(0, 5) : user.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await userService.registerUser(
            name: "Khun Thet Paing",
            email: "khunthetpaing06@gmail.com",
            password: "rounded@10",
            role: "ADMIN",
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // Syntax error ပြင်ဆင်ထားသည် (MainAxisAlignment.center)
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
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
      ),
    );
  }
}