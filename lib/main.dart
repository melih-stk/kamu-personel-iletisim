import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

/* ---------------- APP ---------------- */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

/* ---------------- HOME ---------------- */

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildImageButton({
    required BuildContext context,
    required String imagePath,
    required String title,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          child: Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Image.asset(
                    imagePath,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE4E7EB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              Image.asset(
                'assets/mobit.png',
                height: 90,
              ),

              const SizedBox(height: 16),

              const Text(
                'Kurumsal Personel İletişim Paneli',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  letterSpacing: 0.4,
                ),
              ),

              const Spacer(),

              Column(
                children: [
                  _buildImageButton(
                    context: context,
                    imagePath: 'assets/jandarma.png',
                    title: 'Jandarma Genel Komutanlığı',
                    page: const JandarmaPage(),
                  ),
                  const SizedBox(height: 24),
                  _buildImageButton(
                    context: context,
                    imagePath: 'assets/egm.png',
                    title: 'Emniyet Genel Müdürlüğü',
                    page: const EgmPage(),
                  ),
                  const SizedBox(height: 24),

                  _buildImageButton(
                    context: context,
                    imagePath: 'assets/kizilay.png',
                    title: 'Türk Kızılayı',
                    page: const KizilayPage(),
                  ),

                ],
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  children: const [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        '© 2026 MOBİT',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'v1.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

void sharePhone(String name, String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  Share.share(
    '$name\nTelefon: $digits',
  );
}

/* ---------------- JANDARMA ---------------- */

class JandarmaPage extends StatefulWidget {
  const JandarmaPage({super.key});

  @override
  State<JandarmaPage> createState() => _JandarmaPageState();
}

class _JandarmaPageState extends State<JandarmaPage> {
  List<Map<String, String>> personelList = [];

  static const int pageSize = 7;
  int currentPage = 0;

  final isimController = TextEditingController();
  final dahiliyeController = TextEditingController();
  final telefonController = TextEditingController();

  String? selectedRutbe;

  final List<String> rutbeler = [
    'Bilinmiyor',
    'Çavuş',
    'Başçavuş',
    'Astsubay',
    'Subay',
    'Asteğmen',
    'Teğmen',
    'Üsteğmen',
    'Yüzbaşı',
    'Binbaşı',
    'Yarbay',
    'Albay',
  ];

  List<List<Map<String, String>>> get pagedList {
    List<List<Map<String, String>>> pages = [];
    for (int i = 0; i < personelList.length; i += pageSize) {
      pages.add(
        personelList.sublist(
          i,
          (i + pageSize > personelList.length)
              ? personelList.length
              : i + pageSize,
        ),
      );
    }
    return pages;
  }

  Future<void> _openDialer(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    final Uri uri = Uri.parse('tel:$digits');

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  final telefonMask = MaskTextInputFormatter(
    mask: '0 (5##) ### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('personelList');

    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        personelList =
            decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('personelList', jsonEncode(personelList));
  }

  void _showForm({Map<String, String>? personel, int? index}) {
    if (personel != null) {
      isimController.text = personel['isim'] ?? '';
      dahiliyeController.text = personel['dahiliye'] ?? '';
      telefonController.text = personel['telefon'] ?? '';
      selectedRutbe = personel['rutbe'];
    } else {
      isimController.clear();
      dahiliyeController.clear();
      telefonController.clear();
      selectedRutbe = 'Bilinmiyor';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(personel == null ? 'Jandarma Personeli Ekle' : 'Personel Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: isimController,
                decoration: const InputDecoration(labelText: 'İsim'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRutbe,
                decoration: const InputDecoration(labelText: 'Rütbe'),
                items: rutbeler
                    .map(
                      (r) => DropdownMenuItem(
                    value: r,
                    child: Text(r),
                  ),
                )
                    .toList(),
                onChanged: (val) => selectedRutbe = val,
              ),
              TextField(
                controller: dahiliyeController,
                decoration: const InputDecoration(
                  labelText: 'Dahiliye No',
                  hintText: 'Zorunlu değil',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              TextField(
                controller: telefonController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '0 (5__) ___ ____',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [telefonMask],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final phoneDigits = telefonController.text
                  .replaceAll(RegExp(r'\D'), '');

              if (isimController.text.isEmpty ||
                  phoneDigits.length != 11 ||
                  selectedRutbe == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları eksiksiz doldurun'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                final data = {
                  'isim': isimController.text,
                  'rutbe': selectedRutbe!,
                  'dahiliye': dahiliyeController.text,
                  'telefon': telefonController.text,
                };

                if (index == null) {
                  personelList.add(data);
                } else {
                  personelList[index] = data;
                }
              });

              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deletePersonel(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: const Text('Bu personeli silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                personelList.removeAt(index);
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Evet', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Jandarma Genel K.',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Image.asset(
              'assets/jandarma.png',
              height: 34,
              width: 34,
            ),
          ),
        ],
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1B5E20),
        onPressed: () => _showForm(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: pagedList.isEmpty ? 1 : pagedList.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final pageItems =
              pagedList.isEmpty ? [] : pagedList[pageIndex];

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final p = pageItems[index];

                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        p['isim'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Rütbe: ${p['rutbe']} | Dahiliye: ${p['dahiliye']}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (p['telefon'] ?? '')
                                      .replaceFirst('0 (', '0('),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.green),
                                onPressed: () => sharePhone(
                                  p['isim'] ?? '',
                                  p['telefon'] ?? '',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () => _openDialer(p['telefon'] ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showForm(personel: p, index:
                                    pageIndex * pageSize + index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deletePersonel(pageIndex * pageSize + index),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pagedList.isEmpty ? 1 : currentPage + 1}/${pagedList.isEmpty ? 1 : pagedList.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- EGM ---------------- */

class EgmPage extends StatefulWidget {
  const EgmPage({super.key});

  @override
  State<EgmPage> createState() => _EgmPageState();
}

class _EgmPageState extends State<EgmPage> {
  List<Map<String, String>> personelList = [];

  static const int pageSize = 7;
  int currentPage = 0;

  final isimController = TextEditingController();
  final dahiliyeController = TextEditingController();
  final telefonController = TextEditingController();

  String? selectedRutbe;

  final List<String> rutbeler = [
    'Bilinmiyor',
    'Polis Memuru',
    'Komiser Yardımcısı',
    'Komiser',
    'Başkomiser',
    'Emniyet Amiri',
  ];

  List<List<Map<String, String>>> get pagedList {
    List<List<Map<String, String>>> pages = [];
    for (int i = 0; i < personelList.length; i += pageSize) {
      pages.add(
        personelList.sublist(
          i,
          (i + pageSize > personelList.length)
              ? personelList.length
              : i + pageSize,
        ),
      );
    }
    return pages;
  }

  final telefonMask = MaskTextInputFormatter(
    mask: '0 (5##) ### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _openDialer(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final Uri uri = Uri.parse('tel:$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('egmPersonelList');

    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        personelList =
            decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('egmPersonelList', jsonEncode(personelList));
  }

  void _showForm({Map<String, String>? personel, int? index}) {
    if (personel != null) {
      isimController.text = personel['isim'] ?? '';
      dahiliyeController.text = personel['dahiliye'] ?? '';
      telefonController.text = personel['telefon'] ?? '';
      selectedRutbe = personel['rutbe'];
    } else {
      isimController.clear();
      dahiliyeController.clear();
      telefonController.clear();
      selectedRutbe = rutbeler.first;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(personel == null
            ? 'Polis Personeli Ekle'
            : 'Polis Personeli Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: isimController,
                decoration: const InputDecoration(labelText: 'İsim'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRutbe,
                decoration: const InputDecoration(labelText: 'Rütbe'),
                items: rutbeler
                    .map(
                      (r) => DropdownMenuItem(
                    value: r,
                    child: Text(r),
                  ),
                )
                    .toList(),
                onChanged: (val) => selectedRutbe = val,
              ),
              TextField(
                controller: dahiliyeController,
                decoration: const InputDecoration(
                  labelText: 'Dahiliye No',
                  hintText: 'Zorunlu değil',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              TextField(
                controller: telefonController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '0 (5__) ___ ____',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [telefonMask],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final phoneDigits =
              telefonController.text.replaceAll(RegExp(r'\D'), '');

              if (isimController.text.isEmpty ||
                  phoneDigits.length != 11 ||
                  selectedRutbe == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları eksiksiz doldurun'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                final data = {
                  'isim': isimController.text,
                  'rutbe': selectedRutbe!,
                  'dahiliye': dahiliyeController.text,
                  'telefon': telefonController.text,
                };

                if (index == null) {
                  personelList.add(data);
                } else {
                  personelList[index] = data;
                }
              });

              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deletePersonel(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: const Text('Bu personeli silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                personelList.removeAt(index);
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Evet', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Emniyet Genel M.',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.blue[800],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(
              'assets/egm.png',
              height: 36,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: pagedList.isEmpty ? 1 : pagedList.length,
            onPageChanged: (index) {
              setState(() => currentPage = index);
            },
            itemBuilder: (context, pageIndex) {
              final pageItems =
              pagedList.isEmpty ? [] : pagedList[pageIndex];

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final p = pageItems[index];

                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        p['isim'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Rütbe: ${p['rutbe']} | Dahiliye: ${p['dahiliye']}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(child: Text(p['telefon'] ?? '')),
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.green),
                                onPressed: () => sharePhone(
                                  p['isim'] ?? '',
                                  p['telefon'] ?? '',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone,
                                    color: Colors.green),
                                onPressed: () =>
                                    _openDialer(p['telefon'] ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showForm(
                                  personel: p,
                                  index:
                                  pageIndex * pageSize + index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deletePersonel(
                                    pageIndex * pageSize + index),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pagedList.isEmpty ? 1 : currentPage + 1}/${pagedList.isEmpty ? 1 : pagedList.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
/* ---------------- KIZILAY ---------------- */

class KizilayPage extends StatefulWidget {
  const KizilayPage({super.key});

  @override
  State<KizilayPage> createState() => _KizilayPageState();
}

class _KizilayPageState extends State<KizilayPage> {
  List<Map<String, String>> personelList = [];

  static const int pageSize = 7;
  int currentPage = 0;

  final isimController = TextEditingController();
  final dahiliyeController = TextEditingController();
  final telefonController = TextEditingController();

  final telefonMask = MaskTextInputFormatter(
    mask: '0 (5##) ### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  List<List<Map<String, String>>> get pagedList {
    List<List<Map<String, String>>> pages = [];
    for (int i = 0; i < personelList.length; i += pageSize) {
      pages.add(
        personelList.sublist(
          i,
          (i + pageSize > personelList.length)
              ? personelList.length
              : i + pageSize,
        ),
      );
    }
    return pages;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('kizilayPersonelList');

    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        personelList =
            decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('kizilayPersonelList', jsonEncode(personelList));
  }

  Future<void> _openDialer(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    final Uri uri = Uri.parse('tel:$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showForm({Map<String, String>? personel, int? index}) {
    if (personel != null) {
      isimController.text = personel['isim'] ?? '';
      dahiliyeController.text = personel['dahiliye'] ?? '';
      telefonController.text = personel['telefon'] ?? '';
    } else {
      isimController.clear();
      dahiliyeController.clear();
      telefonController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(personel == null
            ? 'Kızılay Personeli Ekle'
            : 'Kızılay Personeli Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: isimController,
                decoration: const InputDecoration(labelText: 'İsim'),
              ),
              TextField(
                controller: dahiliyeController,
                decoration: const InputDecoration(
                  labelText: 'Dahiliye No',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            TextField(
              controller: telefonController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '0 (5__) ___ ____',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [telefonMask],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isimController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İsim alanı zorunludur'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                final data = {
                  'isim': isimController.text,
                  'dahiliye': dahiliyeController.text,
                  'telefon': telefonController.text,
                };

                if (index == null) {
                  personelList.add(data);
                } else {
                  personelList[index] = data;
                }
              });

              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deletePersonel(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: const Text('Bu personeli silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                personelList.removeAt(index);
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Evet', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Türk Kızılayı',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(
              'assets/kizilay.png',
              height: 36,
            ),
          ),
        ],
        backgroundColor: Colors.red[700],
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: pagedList.isEmpty ? 1 : pagedList.length,
            onPageChanged: (index) {
              setState(() => currentPage = index);
            },
            itemBuilder: (context, pageIndex) {
              final pageItems =
              pagedList.isEmpty ? [] : pagedList[pageIndex];

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final p = pageItems[index];

                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        p['isim'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Dahiliye: ${p['dahiliye']}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(p['telefon'] ?? ''),
                              ),
                              if ((p['telefon'] ?? '').isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.green),
                                  onPressed: () => sharePhone(
                                    p['isim'] ?? '',
                                    p['telefon'] ?? '',
                                  ),
                                ),
                              if ((p['telefon'] ?? '').isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.phone,
                                      color: Colors.green),
                                  onPressed: () =>
                                      _openDialer(p['telefon'] ?? ''),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showForm(
                                  personel: p,
                                  index:
                                  pageIndex * pageSize + index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deletePersonel(
                                    pageIndex * pageSize + index),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pagedList.isEmpty ? 1 : currentPage + 1}/${pagedList.isEmpty ? 1 : pagedList.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}