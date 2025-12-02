import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBooksPage extends StatefulWidget {
  const MyBooksPage({super.key});

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  String? _errorMessage;
  List<dynamic> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'No hay usuario autenticado.';
        _loading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('books')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _books = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando libros: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis libros'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _books.isEmpty
                  ? const Center(child: Text('No has registrado libros aún.'))
                  : ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return ListTile(
                          title: Text(book['title'] ?? ''),
                          subtitle: Text(
                            '${book['author'] ?? ''} • ${book['category'] ?? ''}',
                          ),
                          trailing: Text(
                            (book['status'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
    );
  }
}
