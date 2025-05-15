import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/http_client.dart';
import 'home_page.dart';

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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('username') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      } else {
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

  Future<void> _saveConnectionPreference(bool useLocal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connectionType', useLocal ? 'Yerel Bağlantı' : 'Statik Bağlantı');
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    // Önce yerel bağlantıyı dene
    bool useLocalConnection = true;

    try {
      final client = createSelfSignedClient();
      final response = await client.post(
        Uri.parse('http://192.168.1.213:8887$_loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 3), onTimeout: () {
        useLocalConnection = false;
        throw TimeoutException('Yerel bağlantı zaman aşımına uğradı');
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await _saveConnectionPreference(useLocalConnection);
        setState(() {
          _isLoading = false;
          _errorMessage = 'Giriş başarılı!';
        });
        _saveCredentials();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              user: data['user'],
            ),
          ),
        );
        return;
      }
    } catch (e) {
      useLocalConnection = false;
    }

    // Yerel bağlantı başarısız olduysa veya hata verdiyse, statik bağlantıyı dene
    if (!useLocalConnection) {
      try {
        final client = createSelfSignedClient();
        final response = await client.post(
          Uri.parse('$_fallbackUrl$_loginEndpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        ).timeout(Duration(seconds: 5));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          await _saveConnectionPreference(false);
          setState(() {
            _isLoading = false;
            _errorMessage = 'Giriş başarılı!';
          });
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
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Giriş başarısız!';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bağlantı hatası! Lütfen internet bağlantınızı kontrol edin.';
        });
      }
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
                              _usernameController.clear();
                              _passwordController.clear();
                            }
                          });
                        },
                      ),
                      Text('Beni Hatırla'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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