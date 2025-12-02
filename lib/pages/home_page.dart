import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'profile_page.dart';
import 'add_book_page.dart';
import 'my_books_page.dart';
import 'available_books_page.dart';
import 'requests_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookSwap Local'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $email',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // ===== PERFIL =====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('Mi perfil'),
            ),

            const SizedBox(height: 12),

            // ===== AGREGAR LIBRO - MIS LIBROS =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddBookPage()),
                      );
                    },
                    icon: const Icon(Icons.library_add),
                    label: const Text('Agregar libro'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBooksPage()),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Mis libros'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===== LIBROS DISPONIBLES =====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AvailableBooksPage(),
                  ),
                );
              },
              icon: const Icon(Icons.library_books),
              label: const Text('Ver libros disponibles'),
            ),

            const SizedBox(height: 12),

            // ===== SOLICITUDES RECIBIDAS =====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.inbox),
              label: const Text('Solicitudes recibidas'),
            ),

            const SizedBox(height: 24),

            const Text(
              'Tu biblioteca (usa los botones para gestionarla)',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            const Text(
              'Más adelante aquí podremos mostrar libros como en la web que enviaste (portadas, carruseles, etc.)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
