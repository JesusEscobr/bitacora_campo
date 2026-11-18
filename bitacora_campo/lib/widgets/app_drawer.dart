import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Drawer personalizado con foto de perfil, header y navegación.
///
/// Recibe [currentRoute] para resaltar la opción activa y evitar apilar
/// la misma pantalla varias veces.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  /// Se ejecuta al volver de una pantalla abierta desde el Drawer
  /// (p. ej. para que HomeScreen recargue su lista).
  final VoidCallback? onReturn;

  const AppDrawer({super.key, required this.currentRoute, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Header con foto de perfil ----
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colors.primary),
            accountName: const Text(
              'Mi Bitácora',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Registra tus momentos del día'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colors.onPrimary,
              // Si el asset no existe, se muestra el icono (child).
              foregroundImage: const AssetImage('assets/images/profile.png'),
              onForegroundImageError: (_, __) {},
              child: Icon(Icons.person, size: 40, color: colors.primary),
            ),
          ),

          // ---- Enlaces de navegación ----
          _DrawerItem(
            icon: Icons.list_alt,
            label: 'Inicio / Lista',
            selected: currentRoute == AppRoutes.home,
            onTap: () => _go(context, AppRoutes.home),
          ),
          _DrawerItem(
            icon: Icons.edit_note,
            label: 'Nueva entrada',
            selected: currentRoute == AppRoutes.form,
            onTap: () => _go(context, AppRoutes.form),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings,
            label: 'Configuración',
            selected: currentRoute == AppRoutes.settings,
            onTap: () => _go(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  /// Cierra el Drawer y navega a [route].
  void _go(BuildContext context, String route) {
    // Se captura el navigator ANTES de cerrar el Drawer, porque el
    // contexto del Drawer deja de ser válido después.
    final navigator = Navigator.of(context);
    navigator.pop(); // Cierra el Drawer.
    if (route == currentRoute) return; // Ya estamos aquí.

    if (route == AppRoutes.home) {
      // Volver al inicio limpiando la pila.
      navigator.pushNamedAndRemoveUntil(route, (r) => false);
    } else {
      navigator.pushNamed(route).then((_) => onReturn?.call());
    }
  }
}

/// Elemento reutilizable del Drawer.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
