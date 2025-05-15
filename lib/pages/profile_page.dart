import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;
  const ProfilePage({required this.user});

  @override
  Widget build(BuildContext context) {
    final String adSoyad = user['username'] ?? '';
    final String title = user['title'] ?? '';
    final permissionsRaw = user['permissions'];
    final List<String> permissions = permissionsRaw is Map
        ? permissionsRaw.keys.map((e) => e.toString()).toList()
        : (permissionsRaw is List ? permissionsRaw.map((e) => e.toString()).toList() : []);
    final allPermissionsRaw = user['all_permissions'];
    final List<String> allPermissions = allPermissionsRaw is List
        ? allPermissionsRaw.map((e) => e.toString()).toList()
        : [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 48, color: Colors.blueGrey[700]),
            ),
            SizedBox(height: 16),
            Text(adSoyad, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(title, style: TextStyle(fontSize: 15, color: Colors.blueGrey[600])),
            SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Sahip Olduğunuz İzinler:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            SizedBox(height: 8),
            if (permissions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: permissions.map((perm) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '- $perm',
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey[800]),
                  ),
                )).toList(),
              ),
            if (permissions.isEmpty)
              Text('Herhangi bir izniniz bulunmamaktadır.', style: TextStyle(color: Colors.blueGrey[400])),
            SizedBox(height: 16),
            if (allPermissions.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tüm Yetkileriniz:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            if (allPermissions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: allPermissions.map((perm) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '- $perm',
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey[600]),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
} 