import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiService {
  final String base = 'http://localhost:8787/api/v1';
  Future<Map<String,dynamic>> health() async {
    final res = await http.get(Uri.parse('$base/../health'));
    return jsonDecode(res.body);
  }
}
