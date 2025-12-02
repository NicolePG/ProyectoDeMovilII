import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AvailableBooksPage extends StatefulWidget {
  const AvailableBooksPage({super.key});

  @override
  State<AvailableBooksPage> createState() => _AvailableBooksPageState();
}

class _AvailableBooksPageState extends State<AvailableBooksPage> {
  bool _loading = false;
  String _errorMessage = '';
  String _search = '';

  List<Map<String, dynamic>> _allBooks = [];
  List<Map<String, dynamic>> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final user = supabase.auth.currentUser;

      final booksResponse = await supabase
          .from('books')
          .select('id, title, author, category, status, user_id')
          .eq('status', 'disponible');

      final books = (booksResponse as List)
          .where((b) => b['user_id'] != user?.id)
          .cast<Map<String, dynamic>>()
          .toList();

      final userIds = books.map((b) => b['user_id'] as String).toSet().toList();

      Map<String, String> ownersById = {};

      if (userIds.isNotEmpty) {
        final ownersResponse = await supabase
            .from('users')
            .select('id, name')
            .inFilter('id', userIds);

        for (final row in ownersResponse as List) {
          ownersById[row['id'] as String] =
              (row['name'] ?? 'Sin nombre') as String;
        }
      }

      final booksWithOwner = books
          .map((b) => {
                ...b,
                'owner_name': ownersById[b['user_id']] ?? 'Sin nombre',
              })
          .toList();

      setState(() {
        _allBooks = booksWithOwner;
        _applyFilter();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar libros: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter() {
    final query = _search.toLowerCase();

    _filteredBooks =
        query.isEmpty
            ? List<Map<String, dynamic>>.from(_allBooks)
            : _allBooks.where((book) {
                final title = (book['title'] ?? '').toLowerCase();
                final author = (book['author'] ?? '').toLowerCase();
                return title.contains(query) || author.contains(query);
              }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Libros disponibles'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por título o autor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? const Center(child: Text('No hay libros disponibles.'))
                    : ListView.builder(
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];

                          return ListTile(
                            title: Text(book['title'] ?? ''),
                            subtitle: Text(
                              '${book['author'] ?? ''} • Dueño: ${book['owner_name'] ?? ''}',
                            ),
                            trailing: Text(
                              (book['status'] ?? '').toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookDetailPage(book: book),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ==========================
// DETALLE DE LIBRO + SOLICITUD
// ==========================

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> book;

  const BookDetailPage({super.key, required this.book});

  Future<void> _sendRequest(BuildContext context) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para solicitar.')),
      );
      return;
    }

    if (book['user_id'] == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes solicitar un libro que es tuyo.'),
        ),
      );
      return;
    }

    try {
      await supabase.from('requests').insert({
        'book_id': book['id'],
        'owner_id': book['user_id'],
        'requester_id': user.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar solicitud: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Detalle del libro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Autor: ${book['author'] ?? ''}'),
                const SizedBox(height: 4),
                Text('Categoría: ${book['category'] ?? ''}'),
                const SizedBox(height: 4),
                Text('Dueño: ${book['owner_name'] ?? ''}'),
                const SizedBox(height: 4),
                Text('Estado: ${(book['status'] ?? '').toString().toUpperCase()}'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendRequest(context),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Enviar solicitud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
