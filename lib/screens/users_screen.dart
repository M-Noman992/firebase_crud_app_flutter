import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => UsersScreenState();
}

class UsersScreenState extends State<UsersScreen> {
  final ApiService apiService = ApiService();
  Future<List<User>>? usersFuture;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    usersFuture = apiService.fetchUsers();

    try {
      await usersFuture;
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users (API)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : fetchUsers,
          ),
        ],
      ),
      body: Center(
        child: isLoading && usersFuture == null
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<User>>(
                    future: usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && isLoading) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError && errorMessage == null) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load users: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final users = snapshot.data!;
                        return RefreshIndicator(
                          onRefresh: fetchUsers,
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                                  ),
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  trailing: Text(
                                    user.phone.split(' ').first,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                        return const Center(child: Text('No users found.'));
                      }
                      return const Center(child: Text('Pull to refresh or tap the refresh button.'));
                    },
                  ),
      ),
    );
  }
}