import 'package:flutter/material.dart';

class MainPanel extends StatelessWidget {
  final Map<String, dynamic> user;
  const MainPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Center(
              child: Image.asset('assets/images/umay_logo.png', height: 120),
            ),
            SizedBox(height: 24),
            Text(
              'UMAY Tech Depo Yönetim Sistemi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Bu uygulama, şirket çalışanlarının yetkilerine göre depo işlemlerini kolayca yönetebilmesini sağlar. Kullanıcılar stoktan çıkış yapabilir, stokları düzenleyebilir, kritik uyarı seviyelerini belirleyebilir ve saha bildiriminde bulunabilir. Yetkileriniz doğrultusunda menüler ve işlevler dinamik olarak açılacaktır.',
              style: TextStyle(fontSize: 15, color: Colors.blueGrey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, color: Colors.blueGrey[700]),
                        SizedBox(width: 8),
                        Text('Hoş geldiniz, ${user['full_name'] ?? ''}!', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Yetkiniz: ${user['title'] ?? ''}', style: TextStyle(color: Colors.blueGrey[600])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Gelişim aşamasında olan bu uygulama, şirketinizin dijitalleşme sürecine katkı sağlar.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 