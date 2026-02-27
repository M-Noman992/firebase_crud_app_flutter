import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _usersUrl = 'https://jsonplaceholder.typicode.com/users';
  final String _cachedUsersKey = 'cached_users';

  Future<List<User>> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse(_usersUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<User> users = body.map((dynamic item) => User.fromJson(item)).toList();
        
        await prefs.setString(_cachedUsersKey, response.body);
        return users;
      } else {
        return loadUsersFromCache(prefs);
      }
    } catch (e) {
      print('Error fetching users: $e');
      return loadUsersFromCache(prefs);
    }
  }

  Future<List<User>> loadUsersFromCache(SharedPreferences prefs) async {
    final String? cachedData = prefs.getString(_cachedUsersKey);
    if (cachedData != null) {
      List<dynamic> body = jsonDecode(cachedData);
      return body.map((dynamic item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load users and no cache available');
    }
  }
}