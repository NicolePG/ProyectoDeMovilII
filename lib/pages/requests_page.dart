import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  bool _loading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('requests')
          .select('''
            id,
            status,
            created_at,
            book_id,
            owner_id,
            requester_id,
            books:fk_requests_book ( title ),
            requester:fk_requests_requester ( name )
          ''')
          .eq('owner_id', user!.id)
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int requestId, String newStatus, int bookId) async {
    try {
      await supabase
          .from('requests')
          .update({'status': newStatus})
          .eq('id', requestId);

      if (newStatus == 'aceptado') {
        await supabase
            .from('books')
            .update({'status': 'prestado'})
            .eq('id', bookId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud $newStatus')),
      );

      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes recibidas"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text("No tienes solicitudes"))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];

                    final requesterName =
                        req['requester']?['name'] ?? 'Desconocido';

                    final bookTitle =
                        req['books']?['title'] ?? 'Libro desconocido';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Solicitante: $requesterName"),
                            Text("Estado: ${req['status']}"),
                            const SizedBox(height: 10),

                            if (req['status'] == 'pendiente')
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(
                                      req['id'],
                                      'aceptado',
                                      req['book_id'],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text("Aceptar"),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(
                                      req['id'],
                                      'rechazado',
                                      req['book_id'],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text("Rechazar"),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
