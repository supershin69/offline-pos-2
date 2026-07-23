import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:offline_pos/core/database/database.dart';
import 'package:offline_pos/features/users/repositories/user_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late final AppDatabase _db;
  late final UserService _userService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _db = AppDatabase.instance;
    _userService = UserService(_db);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Delete user ──────────────────────────────────────────────
  Future<void> _deleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await (_db.delete(_db.users)..where((tbl) => tbl.id.equals(user.id))).go();
        if (mounted) _showSnackBar(context, 'User deleted successfully');
      } catch (e) {
        if (mounted) _showSnackBar(context, 'Error deleting user: $e', isError: true);
      }
    }
  }

  // ─── Edit user ────────────────────────────────────────────────────
  Future<void> _editUser(BuildContext context, User user) async {
    final updatedData = await showDialog<User>(
      context: context,
      builder: (ctx) => _EditUserDialog(user: user),
    );

    if (updatedData != null && mounted) {
      try {
        await _db.update(_db.users).replace(updatedData);
        if (mounted) {
          _showSnackBar(context, 'User updated successfully');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(context, 'Error updating user: $e', isError: true);
        }
      }
    }
  }

  // ─── Add user dialog ──────────────────────────────────────────────
  Future<void> _showAddUserDialog(BuildContext context) async {
    final newUserMap = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _AddUserDialog(),
    );

    if (newUserMap != null && mounted) {
      final result = await _userService.registerUser(
        name: newUserMap['name']!,
        email: newUserMap['email']!,
        password: newUserMap['password']!,
        role: 'USER',
      );

      if (result.success && mounted) {
        _showSnackBar(context, 'User added successfully');
      } else if (mounted) {
        _showSnackBar(context, result.errorMessage ?? 'Registration failed', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF5945CB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Search Bar ─────────────────
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5945CB)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // ─── User List View ──────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<User>>(
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final allUsers = snapshot.data!;
                final query = _searchQuery.trim();

                List<User> filteredUsers;
                if (query.isEmpty) {
                  filteredUsers = allUsers;
                } else {
                  final startsWithQuery = allUsers.where((user) {
                    final name = user.name.toLowerCase();
                    final email = user.email.toLowerCase();
                    return name.startsWith(query) || email.startsWith(query);
                  }).toList();

                  final containsQuery = allUsers.where((user) {
                    final name = user.name.toLowerCase();
                    final email = user.email.toLowerCase();
                    final matchesContains = name.contains(query) || email.contains(query);
                    final alreadyAdded = name.startsWith(query) || email.startsWith(query);
                    return matchesContains && !alreadyAdded;
                  }).toList();

                  filteredUsers = [...startsWithQuery, ...containsQuery];
                }

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No matching users found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: filteredUsers.length,
                  itemBuilder: (ctx, index) {
                    final user = filteredUsers[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF5945CB),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${user.email} · ${user.role}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              onPressed: () => _editUser(ctx, user),
                              tooltip: 'Edit user',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'user_screen_fab',
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: const Color(0xFF5945CB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Separate Edit User Dialog Widget (Safe Lifecycle Management) ───────────
class _EditUserDialog extends StatefulWidget {
  final User user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password (optional)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newName = _nameController.text.trim();
            final newEmail = _emailController.text.trim();
            final newPassword = _passwordController.text.trim();

            if (newName.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name must be at least 2 characters'), backgroundColor: Colors.red),
              );
              return;
            }

            if (newEmail.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email is required'), backgroundColor: Colors.red),
              );
              return;
            }

            if (newPassword.isNotEmpty && newPassword.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
              );
              return;
            }

            User resultUser = widget.user.copyWith(
              name: newName,
              email: newEmail.toLowerCase(),
              updatedAt: DateTime.now(),
            );

            if (newPassword.isNotEmpty) {
              final bytes = utf8.encode(newPassword);
              final hashed = sha256.convert(bytes).toString();
              resultUser = resultUser.copyWith(password: hashed);
            }

            Navigator.of(context).pop(resultUser);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5945CB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

// ─── Separate Add User Dialog Widget ─────────────────────────────────────────
class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final email = _emailController.text.trim();
            final password = _passwordController.text.trim();

            if (name.length < 2 || email.isEmpty || password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in all fields correctly'), backgroundColor: Colors.red),
              );
              return;
            }

            Navigator.of(context).pop({
              'name': name,
              'email': email,
              'password': password,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5945CB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add User'),
        ),
      ],
    );
  }
}