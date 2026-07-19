import 'package:flutter/material.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/users/repositories/user_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class UserScreen extends StatefulWidget {
  UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final AppDatabase _db = AppDatabase();
  late final UserService _userService = UserService(_db);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ─── Delete user ──────────────────────────────────────────────
  Future<void> _deleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await (_db.delete(_db.users)..where((tbl) => tbl.id.equals(user.id))).go();
        _showSnackBar(context, 'User deleted successfully');
      } catch (e) {
        _showSnackBar(context, 'Error deleting user: $e', isError: true);
      }
    }
  }

  // ─── Edit user ────────────────────────────────────────────────────
  Future<void> _editUser(BuildContext context, User user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password (leave empty to keep current)',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newPassword = passwordController.text.trim();

              if (newName.isEmpty || newEmail.isEmpty) {
                _showSnackBar(ctx, 'Name and Email are required', isError: true);
                return;
              }

              try {
                User updatedUser = user.copyWith(
                  name: newName,
                  email: newEmail.toLowerCase(),
                );

                if (newPassword.isNotEmpty) {
                  if (newPassword.length < 6) {
                    _showSnackBar(ctx, 'Password must be at least 6 characters', isError: true);
                    return;
                  }
                  final bytes = utf8.encode(newPassword);
                  final hashed = sha256.convert(bytes).toString();
                  updatedUser = updatedUser.copyWith(password: hashed);
                }

                await _db.update(_db.users).replace(updatedUser);
                _showSnackBar(ctx, 'User updated successfully');
                Navigator.of(ctx).pop();
              } catch (e) {
                _showSnackBar(ctx, 'Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5945CB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ─── Add user dialog ──────────────────────────────────────────────
  Future<void> _showAddUserDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text.trim();

              if (name.isEmpty || email.isEmpty || password.isEmpty) {
                _showSnackBar(ctx, 'Please fill in all fields', isError: true);
                return;
              }

              final result = await _userService.registerUser(
                name: name,
                email: email,
                password: password,
                role: 'USER',
              );

              if (result.success) {
                _showSnackBar(ctx, 'User added successfully');
                Navigator.of(ctx).pop();
              } else {
                _showSnackBar(ctx, result.errorMessage ?? 'Registration failed', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5945CB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      // ─── AppBar with search bar ───────────────────────────────────
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<User>>(
        stream: _db.select(_db.users).watch().map(
          (users) => users.where((u) => u.role != 'ADMIN').toList(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final allUsers = snapshot.data!;
          final query = _searchQuery.trim();

          // ─── Smart Filtering: Begin Letter & Default Search ──────────────────
          List<User> filteredUsers;
          if (query.isEmpty) {
            filteredUsers = allUsers;
          } else {
            // (၁) စာလုံးအစဖြင့် ကိုက်ညီသော User များ (Starts With)
            final startsWithQuery = allUsers.where((user) {
              final name = user.name.toLowerCase();
              final email = user.email.toLowerCase();
              return name.startsWith(query) || email.startsWith(query);
            }).toList();

            // (၂) စာလုံးအလယ်/တခြားနေရာတွင် ကိုက်ညီသော User များ (Contains)
            final containsQuery = allUsers.where((user) {
              final name = user.name.toLowerCase();
              final email = user.email.toLowerCase();
              
              // Starts with ထဲမှာ ပါပြီးသားလူတွေကို ထပ်မထည့်မိစေရန် စစ်ဆေးခြင်း
              final matchesContains = name.contains(query) || email.contains(query);
              final alreadyAdded = name.startsWith(query) || email.startsWith(query);
              return matchesContains && !alreadyAdded;
            }).toList();

            // နှစ်ခုစလုံးကို ပေါင်းလိုက်သည် (စစချင်းတူသူများကို အပေါ်ဆုံးမှာ ဦးစားပေးပြသမည်)
            filteredUsers = [...startsWithQuery, ...containsQuery];
          }

          if (filteredUsers.isEmpty) {
            return const Center(child: Text('No matching users'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (ctx, index) {
              final user = filteredUsers[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF5945CB),
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${user.email} · ${user.role}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(ctx, user),
                        tooltip: 'Edit user',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteUser(ctx, user),
                        tooltip: 'Delete user',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: const Color(0xFF5945CB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}