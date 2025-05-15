import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'stock_tracking_page.dart';
import 'stock_entry_page.dart';
import 'stock_exit_page.dart';
import 'profile_page.dart';
import 'main_panel.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  HomePage({required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Always start with Ana Sayfa
    _selectedIndex = 0;
  }

  void _onItemTapped(int index) {
    final List<String> allPermissions = widget.user['all_permissions'] is List
        ? (widget.user['all_permissions'] as List).map((e) => e.toString()).toList()
        : [];
    
    // Stok butonuna basınca yetkiye göre sayfa değiştir
    if (index == 1) {
      if (allPermissions.contains('stok.stok_mobil') && allPermissions.contains('stok.view_product')) {
        setState(() {
          _selectedIndex = 3; // Stok Takip
        });
      } else if (allPermissions.contains('stok.stok_mobil')) {
        setState(() {
          _selectedIndex = 1; // Stok Çıkış
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _logout() async {
    // Clear saved credentials
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.setBool('rememberMe', false);

    // Navigate to login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    final String adSoyad = widget.user['username'] ?? '';
    final String title = widget.user['title'] ?? '';
    final List<String> allPermissions = widget.user['all_permissions'] is List
        ? (widget.user['all_permissions'] as List).map((e) => e.toString()).toList()
        : [];

    List<Widget> _pages = [
      MainPanel(user: widget.user),
      StockExitPage(),
      ProfilePage(user: widget.user),
      StockTrackingPage(),
      StockEntryPage(),
    ];

    // Sol menüde gösterilecek butonlar
    List<Widget> drawerButtons = [
      ListTile(
        leading: Icon(Icons.home),
        title: Text('Ana Sayfa'),
        onTap: () {
          Navigator.pop(context);
          setState(() { _selectedIndex = 0; });
        },
      ),
    ];
    if (allPermissions.contains('stok.stok_mobil')) {
      drawerButtons.add(ListTile(
        leading: Icon(Icons.exit_to_app),
        title: Text('Stok Çıkış'),
        onTap: () {
          Navigator.pop(context);
          setState(() { _selectedIndex = 1; });
        },
      ));
    }
    if (allPermissions.contains('stok.add_product')) {
      drawerButtons.add(ListTile(
        leading: Icon(Icons.add_box),
        title: Text('Stok Giriş'),
        onTap: () {
          Navigator.pop(context);
          setState(() { _selectedIndex = 4; });
        },
      ));
    }
    if (allPermissions.contains('stok.stok_mobil') && allPermissions.contains('stok.view_product')) {
      drawerButtons.add(ListTile(
        leading: Icon(Icons.list_alt),
        title: Text('Stok Takip'),
        onTap: () {
          Navigator.pop(context);
          setState(() { _selectedIndex = 3; });
        },
      ));
    }
    drawerButtons.add(ListTile(
      leading: Icon(Icons.person),
      title: Text('Profil'),
      onTap: () {
        Navigator.pop(context);
        setState(() { _selectedIndex = 2; });
      },
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('UMAY Tech'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.asset('assets/images/umay_logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Divider(thickness: 1.2),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: drawerButtons,
                  ),
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.blueGrey[700]),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adSoyad,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            title,
                            style: TextStyle(fontSize: 13, color: Colors.blueGrey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 4),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _logout(); // Perform logout
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 3 || _selectedIndex == 4 ? 1 : _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
} 