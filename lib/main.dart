import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int themeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);
  }

  void _toggleThemeMode() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
      _saveThemeMode(_themeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: _themeMode == ThemeMode.light ? _buildLightTheme() : _buildDarkTheme(),
      duration: Duration(milliseconds: 500),
      child: MaterialApp(
        title: 'Cek Khodam',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _themeMode,
        home: KhodamPage(toggleThemeMode: _toggleThemeMode),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      textTheme: GoogleFonts.latoTextTheme(
        Theme.of(context).textTheme,
      ),
      brightness: Brightness.light,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      textTheme: GoogleFonts.latoTextTheme(
        Theme.of(context).textTheme,
      ),
      brightness: Brightness.dark,
    );
  }
}

class KhodamPage extends StatefulWidget {
  final VoidCallback toggleThemeMode;

  KhodamPage({required this.toggleThemeMode});

  @override
  _KhodamPageState createState() => _KhodamPageState();
}

class _KhodamPageState extends State<KhodamPage> {
  TextEditingController _nameController = TextEditingController();
  String? _khodamName;
  String? _khodamMeaning;
  bool _isLoading = false;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? khodamList = prefs.getString('khodamList');
    if (khodamList != null) {
      setState(() {
        _history = List<Map<String, String>>.from(json.decode(khodamList));
      });
    }
  }

  Future<void> _saveKhodam(String name, String khodamName, String khodamMeaning) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> khodamData = {
      'name': name,
      'khodamName': khodamName,
      'khodamMeaning': khodamMeaning,
    };
    _history.insert(0, khodamData);
    await prefs.setString('khodamList', json.encode(_history));
    setState(() {});
  }

  Future<void> _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('khodamList');
    setState(() {
      _history = [];
    });
  }

  Future<void> _showConfirmationDialog() async {
    bool confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Penghapusan'),
          content: Text('Apakah Anda yakin ingin menghapus riwayat?'),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      await _clearHistory();
      _showSuccessDialog();
    }
  }

  Future<void> _showSuccessDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Berhasil'),
          content: Text('Riwayat berhasil dihapus.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _cekKhodam() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama tidak boleh kosong!')),
      );
      return;
    }

    String inputName = _nameController.text;
    var existingKhodam = _history.firstWhere(
      (element) => element['name'] == inputName,
      orElse: () => {},
    );

    if (existingKhodam.isNotEmpty) {
      setState(() {
        _khodamName = existingKhodam['khodamName'];
        _khodamMeaning = existingKhodam['khodamMeaning'];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Timer(Duration(seconds: 1), () {
      final khodams = [
        {
          'name': 'Harimau Putih',
          'meaning': 'Kamu kuat dan berani seperti harimau, karena pendahulumu mewariskan kekuatan besar padamu.',
        },
        {
          'name': 'Harimau Kuning',
          'meaning': 'Kamu memiliki kecerdasan dan keberanian luar biasa, mewarisi kekuatan yang hebat.',
        },
        {
          'name': 'Elang Biru',
          'meaning': 'Kamu memiliki pandangan jauh ke depan dan keberanian seperti elang, mewarisi kemampuan besar.',
        },
        {
          'name': 'Naga Merah',
          'meaning': 'Kamu penuh dengan energi dan keberanian, mewarisi kekuatan besar dari leluhurmu.',
        },
      ];
      final khodam = khodams[DateTime.now().millisecondsSinceEpoch % khodams.length];
      setState(() {
        _khodamName = khodam['name'];
        _khodamMeaning = khodam['meaning'];
        _isLoading = false;
      });
      _saveKhodam(_nameController.text, khodam['name']!, khodam['meaning']!);
    });
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _khodamName = null;
      _khodamMeaning = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cek Khodam'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Masukkan nama untuk mengetahui khodam',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? SpinKitFadingCircle(
                    color: Colors.indigo,
                    size: 50.0,
                  )
                : Column(
                    children: [
                      _khodamName != null
                          ? Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Khodam: $_khodamName',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      _khodamMeaning!,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                      SizedBox(height:
20),
ElevatedButton(
onPressed: _cekKhodam,
child: Text('Cek Khodam'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.indigo,
padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
textStyle: TextStyle(fontSize: 16, color: Colors.black),
foregroundColor: Colors.black, // Text color
),
),
],
),
SizedBox(height: 20),
ElevatedButton(
onPressed: _resetForm,
child: Text('Cek Lagi'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
textStyle: TextStyle(fontSize: 16, color: Colors.black),
foregroundColor: Colors.black, // Text color
),
),
SizedBox(height: 20),
Expanded(
child: _history.isEmpty
? Center(child: Text('Belum ada riwayat khodam'))
: ListView.builder(
itemCount: _history.length,
itemBuilder: (context, index) {
final item = _history[index];
return Card(
elevation: 2,
margin: EdgeInsets.symmetric(vertical: 5),
child: ListTile(
title: Text(item['name']!),
subtitle: Text('${item['khodamName']} - ${item['khodamMeaning']}'),
),
);
},
),
),
],
),
),
bottomNavigationBar: BottomNavigationBar(
items: [
BottomNavigationBarItem(
icon: Icon(Icons.delete),
label: 'Hapus Riwayat',
),
BottomNavigationBarItem(
icon: Icon(Icons.brightness_6),
label: 'Toggle Theme',
),
],
onTap: (index) {
if (index == 0) {
_showConfirmationDialog();
} else if (index == 1) {
widget.toggleThemeMode();
}
},
),
);
}
}