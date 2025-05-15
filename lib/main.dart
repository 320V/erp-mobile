import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_native_splash/flutter_native_splash.dart';

//SERVER IP: 192.168.1.213

IOClient createSelfSignedClient() {
  final HttpClient httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      return host == "192.168.1.213"; // Sertifikana sadece bu IP için güven
    };
  return IOClient(httpClient);
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Uygulama başlatma işlemleri burada yapılabilir
  await Future.delayed(const Duration(seconds: 2));
  
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umay Takip',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  String _baseUrl = 'http://192.168.1.213:8887';
  final String _fallbackUrl = 'http://212.156.147.234:8887';
  final String _loginEndpoint = '/accounts/api/login/'; 
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedConnectionType = 'Yerel Bağlantı';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadConnectionType();
  }

  Future<void> _loadConnectionType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedConnectionType = prefs.getString('connectionType') ?? 'Yerel Bağlantı';
      _baseUrl = _selectedConnectionType == 'Yerel Bağlantı' ? 'http://192.168.1.213:8887' : _fallbackUrl;
    });
  }

  Future<void> _saveConnectionType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connectionType', _selectedConnectionType);
    setState(() {
      _baseUrl = _selectedConnectionType == 'Yerel Bağlantı' ? 'http://192.168.1.213:8887' : _fallbackUrl;
    });
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('username') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      } else {
        // Clear any existing text if remember me is false
        _usernameController.clear();
        _passwordController.clear();
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      final client = createSelfSignedClient();
      final response = await client.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Bağlantı zaman aşımına uğradı');
      });

      setState(() {
        _isLoading = false;
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          _errorMessage = 'Giriş başarılı!';
          _saveCredentials();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                user: data['user'],
              ),
            ),
          );
        } else {
          _errorMessage = data['message'] ?? 'Giriş başarısız!';
          debugPrint('Login Error: ' + response.body);
        }
      });
    } catch (e, stack) {
      setState(() {
        _isLoading = false;
        if (e is TimeoutException || 
            e.toString().contains('Connection refused') || 
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException')) {
          if (_selectedConnectionType == 'Yerel Bağlantı') {
            _errorMessage = 'Yerel Bağlantı sağlanamadı!\nLütfen Statik Bağlantıyı tercih edin.';
          } else {
            _errorMessage = 'Bağlantı hatası!\nLütfen internet bağlantınızı kontrol edin.';
          }
        } else {
          _errorMessage = 'Bir hata oluştu: $e';
        }
      });
      debugPrint('Login Exception: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giriş Yap'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  Image.asset('assets/images/umay_logo.png', height: 200),
                  SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            _rememberMe = value ?? false;
                            if (!_rememberMe) {
                              // If remember me is unchecked, clear the fields
                              _usernameController.clear();
                              _passwordController.clear();
                            }
                          });
                        },
                      ),
                      Text('Beni Hatırla'),
                    ],
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedConnectionType,
                        isExpanded: true,
                        underline: SizedBox(),
                        items: ['Yerel Bağlantı', 'Statik Bağlantı'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedConnectionType = newValue;
                            });
                            _saveConnectionType();
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[50],
                        foregroundColor: Colors.blueGrey[800],
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blueGrey[200]!),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey[700]!),
                              ),
                            )
                          : Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: SelectableText(
                        _errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      StockCikisPage(),
      ProfilePage(user: widget.user),
      StockTrackingPage(),
      StockGirisPage(),
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

class StockCikisPage extends StatefulWidget {
  @override
  State<StockCikisPage> createState() => _StockPageState();
}

class StockTrackingPage extends StatefulWidget {
  @override
  _StockTrackingPageState createState() => _StockTrackingPageState();
}

class _StockTrackingPageState extends State<StockTrackingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchCriteria = 'Ürün Adı';
  String _selectedFilter = 'Tüm Ürünler';
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  double _warningPercentage = 20.0;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _baseUrl = 'http://192.168.1.213:8887';
  final String _fallbackUrl = 'http://212.156.147.234:8887';

  @override
  void initState() {
    super.initState();
    _loadConnectionType();
    _fetchProducts();
  }

  Future<void> _loadConnectionType() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionType = prefs.getString('connectionType') ?? 'Yerel Bağlantı';
    setState(() {
      _baseUrl = connectionType == 'Yerel Bağlantı' ? 'http://192.168.1.213:8887' : _fallbackUrl;
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = createSelfSignedClient();
      final response = await client.get(
        Uri.parse('$_baseUrl/stok/urun-listesi/'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['urunler']);
          _warningPercentage = (data['uyari_yuzdesi'] ?? 0.2) * 100;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Ürün listesi alınamadı.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException')) {
          _errorMessage = 'Server Bağlantısı Başarısız!\nLütfen Tekrar Deneyin';
          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          _errorMessage = 'Bir hata oluştu: $e';
        }
      });
    }
  }

  List<String> _searchCriteria = [
    'Ürün Adı',
    'Ürün Kodu',
    'Muhasebe Kodu',
    'Tedarikçi Kodu',
    'Marka',
    'Raf',
    'Adet',
    'Asgari'
  ];

  List<String> _filters = [
    'Tüm Ürünler',
    'Öncü Uyarılar',
    'Kritik Seviye'
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) {
        final searchTerm = _searchController.text.toLowerCase();
        switch (_selectedSearchCriteria) {
          case 'Ürün Adı':
            return product['urun_adi'].toString().toLowerCase().contains(searchTerm);
          case 'Ürün Kodu':
            return product['urun_kodu'].toString().toLowerCase().contains(searchTerm);
          case 'Muhasebe Kodu':
            return product['muhasebe_kodu']?.toString().toLowerCase().contains(searchTerm) ?? false;
          case 'Tedarikçi Kodu':
            return product['tedarikci_kodu']?.toString().toLowerCase().contains(searchTerm) ?? false;
          case 'Marka':
            return product['marka']?.toString().toLowerCase().contains(searchTerm) ?? false;
          case 'Raf':
            return product['raf']?.toString().toLowerCase().contains(searchTerm) ?? false;
          case 'Adet':
            return product['adet'].toString().contains(searchTerm);
          case 'Asgari':
            return product['asgari'].toString().contains(searchTerm);
          default:
            return true;
        }
      }).toList();
    }

    // Apply stock level filter
    switch (_selectedFilter) {
      case 'Öncü Uyarılar':
        filtered = filtered.where((product) {
          final adet = product['adet'] as int? ?? 0;
          final asgari = product['asgari'] as int? ?? 0;
          return adet < asgari * (1 + _warningPercentage / 100) && adet > 0;
        }).toList();
        break;
      case 'Kritik Seviye':
        filtered = filtered.where((product) {
          final adet = product['adet'] as int? ?? 0;
          final asgari = product['asgari'] as int? ?? 0;
          return adet <= asgari;
        }).toList();
        break;
    }

    return filtered;
  }

  List<Map<String, dynamic>> get _paginatedProducts {
    final startIndex = _currentPage * _itemsPerPage;
    return _filteredProducts.skip(startIndex).take(_itemsPerPage).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stok Takip'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        child: Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Ara...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                            SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedSearchCriteria,
                              items: _searchCriteria.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSearchCriteria = newValue;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: _filters.map((filter) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: FilterChip(
                                  label: Text(filter),
                                  selected: _selectedFilter == filter,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      _selectedFilter = filter;
                                      _currentPage = 0;
                                    });
                                  },
                                  backgroundColor: _selectedFilter == filter
                                      ? (filter == 'Öncü Uyarılar'
                                          ? Colors.amber.withOpacity(0.3)
                                          : filter == 'Kritik Seviye'
                                              ? Colors.red.withOpacity(0.3)
                                              : Colors.blue.withOpacity(0.3))
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Ürün Adı')),
                              DataColumn(label: Text('Ürün Kodu')),
                              DataColumn(label: Text('Muhasebe Kodu')),
                              DataColumn(label: Text('Tedarikçi Kodu')),
                              DataColumn(label: Text('Marka')),
                              DataColumn(label: Text('Raf')),
                              DataColumn(label: Text('Adet')),
                              DataColumn(label: Text('Asgari')),
                            ],
                            rows: _paginatedProducts.map((product) {
                              final adet = product['adet'] as int? ?? 0;
                              final asgari = product['asgari'] as int? ?? 0;
                              final bool isCritical = adet <= asgari;
                              final bool isWarning = adet > asgari && 
                                  adet < (asgari * (1 + _warningPercentage / 100));
                              return DataRow(
                                color: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    if (isCritical) {
                                      return Colors.red.withOpacity(0.1);
                                    } else if (isWarning) {
                                      return Colors.amber.withOpacity(0.1);
                                    }
                                    return null;
                                  },
                                ),
                                cells: [
                                  DataCell(Text(product['urun_adi'] ?? '-')),
                                  DataCell(Text(product['urun_kodu'] ?? '-')),
                                  DataCell(Text(product['muhasebe_kodu']?.toString() ?? '-')),
                                  DataCell(Text(product['tedarikci_kodu']?.toString() ?? '-')),
                                  DataCell(Text(product['marka']?.toString() ?? '-')),
                                  DataCell(Text(product['raf']?.toString() ?? '-')),
                                  DataCell(Text(
                                    '${product['adet']} ${product['birim'] ?? ''}',
                                    style: TextStyle(
                                      color: isCritical ? Colors.red : isWarning ? Colors.amber[700] : null,
                                      fontWeight: isCritical || isWarning ? FontWeight.bold : null,
                                    ),
                                  )),
                                  DataCell(Text('${product['asgari']} ${product['birim'] ?? ''}')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blueGrey[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.blueGrey[700]),
                                  SizedBox(width: 8),
                                  Text(
                                    'Öncü Uyarı Sınırı: %${_warningPercentage.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.blueGrey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                            ),
                            Text('Sayfa ${_currentPage + 1}'),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: (_currentPage + 1) * _itemsPerPage < _filteredProducts.length
                                  ? () => setState(() => _currentPage++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

class _StockPageState extends State<StockCikisPage> {
  List<TextEditingController> _idControllers = [TextEditingController()];
  List<TextEditingController> _adetControllers = [TextEditingController()];
  List<FocusNode> _adetFocusNodes = [FocusNode()];
  List<String> _currentStockInfo = ['-'];
  bool _showQR = false;
  int _qrIndex = 0;
  String? _qrError;
  bool _isLoading = false;
  String _baseUrl = 'http://192.168.1.213:8887';
  final String _fallbackUrl = 'http://212.156.147.234:8887';

  @override
  void initState() {
    super.initState();
    _loadConnectionType();
    // Add listener to the first focus node
    _adetFocusNodes[0].addListener(() => _onAdetFocusChanged(0));
    // Add listener to the first ID controller
    _idControllers[0].addListener(() => _onIdChanged(0));
  }

  Future<void> _loadConnectionType() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionType = prefs.getString('connectionType') ?? 'Yerel Bağlantı';
    setState(() {
      _baseUrl = connectionType == 'Yerel Bağlantı' ? 'http://192.168.1.213:8887' : _fallbackUrl;
    });
  }

  void _onIdChanged(int index) {
    setState(() {
      _currentStockInfo[index] = '-';
    });
  }

  Future<void> _fetchCurrentStock(int index) async {
    final urunId = _idControllers[index].text;
    if (urunId.isEmpty) {
      setState(() {
        _currentStockInfo[index] = '-';
      });
      return;
    }

    try {
      final client = createSelfSignedClient();
      final response = await client.get(
        Uri.parse('$_baseUrl/stok/$urunId/adet/'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      setState(() {
        if (data['success'] == true) {
          final urun = data['urun'];
          _currentStockInfo[index] = '${urun['adet']} adet (${urun['isim']})';
        } else {
          _currentStockInfo[index] = '(Ürün Bulunamadı)';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException')) {
          _currentStockInfo[index] = '(Bağlantı Hatası)';
          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          _currentStockInfo[index] = '(Bağlantı Hatası)';
        }
      });
    }
  }

  void _onAdetFocusChanged(int index) {
    if (_adetFocusNodes[index].hasFocus) {
      _fetchCurrentStock(index);
    }
  }

  Future<void> _confirmStockExit() async {
    // Validate all fields are filled
    for (int i = 0; i < _idControllers.length; i++) {
      if (_idControllers[i].text.isEmpty || _adetControllers[i].text.isEmpty) {
        _showErrorDialog('Hata', 'Lütfen tüm ürün bilgilerini doldurun.');
        return;
      }

      // Validate quantity is positive
      int quantity = int.tryParse(_adetControllers[i].text) ?? 0;
      if (quantity <= 0) {
        _showErrorDialog('Hata', 'Adet değeri pozitif bir sayı olmalıdır.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare request data
      final List<Map<String, dynamic>> urunler = [];
      for (int i = 0; i < _idControllers.length; i++) {
        urunler.add({
          'urun_kodu': _idControllers[i].text,
          'adet': int.parse(_adetControllers[i].text),
        });
      }

      final client = createSelfSignedClient();
      final response = await client.post(
        Uri.parse('$_baseUrl/stok/stok-dus/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'urunler': urunler}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Success - clear the form
        setState(() {
          _idControllers = [TextEditingController()];
          _adetControllers = [TextEditingController()];
        });
        _showSuccessDialog('Başarılı', data['message'] ?? 'Stok çıkışı başarıyla gerçekleştirildi.');
      } else {
        // Error handling
        _showErrorDialog('Hata', data['error'] ?? 'Bir hata oluştu.');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showErrorDialog('Hata', 'Bir hata oluştu: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _removeProduct(int index) {
    if (index > 0 && index < _idControllers.length) {
      setState(() {
        _idControllers[index].dispose();
        _adetControllers[index].dispose();
        _adetFocusNodes[index].dispose();
        _idControllers.removeAt(index);
        _adetControllers.removeAt(index);
        _adetFocusNodes.removeAt(index);
        _currentStockInfo.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomePageState>();
    final List<String> allPermissions = homeState?.widget.user['all_permissions'] is List
        ? (homeState!.widget.user['all_permissions'] as List).map((e) => e.toString()).toList()
        : [];
    final bool hasStokMobile = allPermissions.contains('stok.stok_mobil');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasStokMobile) ...[
              Text('Stok Çıkış', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _idControllers.length,
                itemBuilder: (context, index) {
                  // Ensure we have enough focus nodes and stock info
                  while (_adetFocusNodes.length <= index) {
                    final node = FocusNode();
                    node.addListener(() => _onAdetFocusChanged(index));
                    _adetFocusNodes.add(node);
                    _currentStockInfo.add('-');
                  }

                  // Ensure we have a listener for this ID controller
                  if (!_idControllers[index].hasListeners) {
                    _idControllers[index].addListener(() => _onIdChanged(index));
                  }

                  return Card(
                    margin: EdgeInsets.only(bottom: 18),
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.qr_code_scanner, size: 32, color: Colors.blueGrey[700]),
                                    onPressed: () async {
                                      _qrError = null;
                                      var status = await Permission.camera.status;
                                      if (!status.isGranted) {
                                        status = await Permission.camera.request();
                                      }
                                      if (status.isGranted) {
                                        setState(() {
                                          _showQR = true;
                                          _qrIndex = index;
                                        });
                                      } else {
                                        setState(() {
                                          _showQR = false;
                                          _qrError = 'Kamera izni gereklidir. Lütfen uygulamaya kamera izni verin.';
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 40.0),
                                      child: TextField(
                                        controller: _idControllers[index],
                                        textCapitalization: TextCapitalization.characters,
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Ürün ID',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          // Convert to uppercase
                                          if (value != value.toUpperCase()) {
                                            _idControllers[index].text = value.toUpperCase();
                                            _idControllers[index].selection = TextSelection.fromPosition(
                                              TextPosition(offset: _idControllers[index].text.length),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text('Mevcut Adet: ${_currentStockInfo[index]}', 
                                style: TextStyle(
                                  color: _currentStockInfo[index] == '(Ürün Bulunamadı)' || 
                                         _currentStockInfo[index] == '(Bağlantı Hatası)'
                                    ? Colors.red
                                    : Colors.blueGrey[600]
                                )
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _adetControllers[index],
                                focusNode: _adetFocusNodes[index],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Alınan Adet',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeProduct(index),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (_qrError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_qrError!, style: TextStyle(color: Colors.red)),
                ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final newIndex = _idControllers.length;
                      setState(() {
                        _idControllers.add(TextEditingController());
                        _adetControllers.add(TextEditingController());
                        final node = FocusNode();
                        node.addListener(() => _onAdetFocusChanged(newIndex));
                        _adetFocusNodes.add(node);
                        _currentStockInfo.add('-');
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Yeni Ürün'),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmStockExit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Çıkış Onayla', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
            if (!hasStokMobile)
              Center(
                child: Text('Stok işlemleri için yetkiniz bulunmamaktadır.', style: TextStyle(color: Colors.blueGrey)),
              ),
            if (_showQR)
              Dialog(
                child: Container(
                  width: 350,
                  height: 400,
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                            setState(() {
                              _idControllers[_qrIndex].text = barcodes.first.rawValue!;
                              _showQR = false;
                              // Fetch stock info after QR scan
                              _fetchCurrentStock(_qrIndex);
                            });
                          } else {
                            setState(() {
                              _qrError = 'Geçersiz QR kod!';
                            });
                          }
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _showQR = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StockGirisPage extends StatefulWidget {
  @override
  State<StockGirisPage> createState() => _StockGirisPageState();
}

class _StockGirisPageState extends State<StockGirisPage> {
  List<TextEditingController> _idControllers = [TextEditingController()];
  List<TextEditingController> _adetControllers = [TextEditingController()];
  List<FocusNode> _adetFocusNodes = [FocusNode()];
  List<String> _currentStockInfo = ['-'];
  bool _showQR = false;
  int _qrIndex = 0;
  String? _qrError;
  bool _isLoading = false;
  String _baseUrl = 'http://192.168.1.213:8887';
  final String _fallbackUrl = 'http://212.156.147.234:8887';

  @override
  void initState() {
    super.initState();
    _loadConnectionType();
    // Add listener to the first focus node
    _adetFocusNodes[0].addListener(() => _onAdetFocusChanged(0));
    // Add listener to the first ID controller
    _idControllers[0].addListener(() => _onIdChanged(0));
  }

  Future<void> _loadConnectionType() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionType = prefs.getString('connectionType') ?? 'Yerel Bağlantı';
    setState(() {
      _baseUrl = connectionType == 'Yerel Bağlantı' ? 'http://192.168.1.213:8887' : _fallbackUrl;
    });
  }

  void _onIdChanged(int index) {
    setState(() {
      _currentStockInfo[index] = '-';
    });
  }

  Future<void> _fetchCurrentStock(int index) async {
    final urunId = _idControllers[index].text;
    if (urunId.isEmpty) {
      setState(() {
        _currentStockInfo[index] = '-';
      });
      return;
    }

    try {
      final client = createSelfSignedClient();
      final response = await client.get(
        Uri.parse('$_baseUrl/stok/$urunId/adet/'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      setState(() {
        if (data['success'] == true) {
          final urun = data['urun'];
          _currentStockInfo[index] = '${urun['adet']} adet (${urun['isim']})';
        } else {
          _currentStockInfo[index] = '(Ürün Bulunamadı)';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException')) {
          _currentStockInfo[index] = '(Bağlantı Hatası)';
          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          _currentStockInfo[index] = '(Bağlantı Hatası)';
        }
      });
    }
  }

  void _onAdetFocusChanged(int index) {
    if (_adetFocusNodes[index].hasFocus) {
      _fetchCurrentStock(index);
    }
  }

  Future<void> _confirmStockEntry() async {
    // Validate all fields are filled
    for (int i = 0; i < _idControllers.length; i++) {
      if (_idControllers[i].text.isEmpty || _adetControllers[i].text.isEmpty) {
        _showErrorDialog('Hata', 'Lütfen tüm ürün bilgilerini doldurun.');
        return;
      }

      // Validate quantity is positive
      int quantity = int.tryParse(_adetControllers[i].text) ?? 0;
      if (quantity <= 0) {
        _showErrorDialog('Hata', 'Adet değeri pozitif bir sayı olmalıdır.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare request data
      final List<Map<String, dynamic>> urunler = [];
      for (int i = 0; i < _idControllers.length; i++) {
        urunler.add({
          'urun_kodu': _idControllers[i].text,
          'adet': int.parse(_adetControllers[i].text),
        });
      }

      final client = createSelfSignedClient();
      final response = await client.post(
        Uri.parse('$_baseUrl/stok/stok-artis/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'urunler': urunler}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Success - clear the form
        setState(() {
          _idControllers = [TextEditingController()];
          _adetControllers = [TextEditingController()];
        });
        _showSuccessDialog('Başarılı', data['message'] ?? 'Stok girişi başarıyla gerçekleştirildi.');
      } else {
        // Error handling
        _showErrorDialog('Hata', data['error'] ?? 'Bir hata oluştu.');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showErrorDialog('Hata', 'Bir hata oluştu: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _removeProduct(int index) {
    if (index > 0 && index < _idControllers.length) {
      setState(() {
        _idControllers[index].dispose();
        _adetControllers[index].dispose();
        _adetFocusNodes[index].dispose();
        _idControllers.removeAt(index);
        _adetControllers.removeAt(index);
        _adetFocusNodes.removeAt(index);
        _currentStockInfo.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomePageState>();
    final List<String> allPermissions = homeState?.widget.user['all_permissions'] is List
        ? (homeState!.widget.user['all_permissions'] as List).map((e) => e.toString()).toList()
        : [];
    final bool hasStokAdd = allPermissions.contains('stok.add_product');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasStokAdd) ...[
              Text('Stok Giriş', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _idControllers.length,
                itemBuilder: (context, index) {
                  // Ensure we have enough focus nodes and stock info
                  while (_adetFocusNodes.length <= index) {
                    final node = FocusNode();
                    node.addListener(() => _onAdetFocusChanged(index));
                    _adetFocusNodes.add(node);
                    _currentStockInfo.add('-');
                  }

                  // Ensure we have a listener for this ID controller
                  if (!_idControllers[index].hasListeners) {
                    _idControllers[index].addListener(() => _onIdChanged(index));
                  }

                  return Card(
                    margin: EdgeInsets.only(bottom: 18),
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.qr_code_scanner, size: 32, color: Colors.blueGrey[700]),
                                    onPressed: () async {
                                      _qrError = null;
                                      var status = await Permission.camera.status;
                                      if (!status.isGranted) {
                                        status = await Permission.camera.request();
                                      }
                                      if (status.isGranted) {
                                        setState(() {
                                          _showQR = true;
                                          _qrIndex = index;
                                        });
                                      } else {
                                        setState(() {
                                          _showQR = false;
                                          _qrError = 'Kamera izni gereklidir. Lütfen uygulamaya kamera izni verin.';
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 40.0),
                                      child: TextField(
                                        controller: _idControllers[index],
                                        textCapitalization: TextCapitalization.characters,
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Ürün ID',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          // Convert to uppercase
                                          if (value != value.toUpperCase()) {
                                            _idControllers[index].text = value.toUpperCase();
                                            _idControllers[index].selection = TextSelection.fromPosition(
                                              TextPosition(offset: _idControllers[index].text.length),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text('Mevcut Adet: ${_currentStockInfo[index]}', 
                                style: TextStyle(
                                  color: _currentStockInfo[index] == '(Ürün Bulunamadı)' || 
                                         _currentStockInfo[index] == '(Bağlantı Hatası)'
                                    ? Colors.red
                                    : Colors.blueGrey[600]
                                )
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _adetControllers[index],
                                focusNode: _adetFocusNodes[index],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Alınan Adet',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeProduct(index),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (_qrError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_qrError!, style: TextStyle(color: Colors.red)),
                ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final newIndex = _idControllers.length;
                      setState(() {
                        _idControllers.add(TextEditingController());
                        _adetControllers.add(TextEditingController());
                        final node = FocusNode();
                        node.addListener(() => _onAdetFocusChanged(newIndex));
                        _adetFocusNodes.add(node);
                        _currentStockInfo.add('-');
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Yeni Ürün'),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmStockEntry,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Giriş Onayla', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
            if (!hasStokAdd)
              Center(
                child: Text('Stok girişi için yetkiniz bulunmamaktadır.', style: TextStyle(color: Colors.blueGrey)),
              ),
            if (_showQR)
              Dialog(
                child: Container(
                  width: 350,
                  height: 400,
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                            setState(() {
                              _idControllers[_qrIndex].text = barcodes.first.rawValue!;
                              _showQR = false;
                              // Fetch stock info after QR scan
                              _fetchCurrentStock(_qrIndex);
                            });
                          } else {
                            setState(() {
                              _qrError = 'Geçersiz QR kod!';
                            });
                          }
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _showQR = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
