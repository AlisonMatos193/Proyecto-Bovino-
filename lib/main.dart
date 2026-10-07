import 'package:flutter/material.dart';

import 'db/app_database.dart';
import 'services/sync_service.dart';
import 'ui/advisor_page.dart';
import 'ui/catalog_page.dart';
import 'ui/my_ranch_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database; // abre/crea SQLite local
  SyncService.instance.start(); // escucha la red y sincroniza cuando haya
  runApp(const CatalogoApp());
}

class CatalogoApp extends StatelessWidget {
  const CatalogoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Catálogo Bovino Tizimín',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  // Cada pestaña se recrea al abrirla, así siempre muestra los datos más recientes de SQLite.
  static final _paginas = <Widget Function()>[
    () => const CatalogPage(),
    () => const MyRanchPage(),
    () => const AdvisorPage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _paginas[_i](),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Vitrina'),
            NavigationDestination(icon: Icon(Icons.agriculture_outlined), label: 'Mi rancho'),
            NavigationDestination(icon: Icon(Icons.account_tree_outlined), label: 'Asesor genético'),
          ],
        ),
      );
}
