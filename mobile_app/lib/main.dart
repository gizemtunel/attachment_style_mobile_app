import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KusursuzKocApp());
}

// ==========================================
// 1. VERİ YAPILARI (MODELLER)
// ==========================================
class ChatMessage {
  final String role; 
  final String text;
  
  ChatMessage(this.role, this.text);
}

class ChatSession {
  final String id;
  String teshis;
  final List<ChatMessage> mesajlar;
  
  ChatSession(this.id, this.teshis, this.mesajlar);
}

class PostComment {
  final String author;
  final String text;
  
  PostComment(this.author, this.text);
}

class CommunityPost {
  final String id;
  final String author;
  final String content;
  int likes;
  bool isLiked;
  final List<PostComment> comments;

  CommunityPost(
    this.id, 
    this.author, 
    this.content, 
    this.likes, 
    this.isLiked, 
    this.comments
  );
}

// ==========================================
// 2. GLOBAL STATE YÖNETİMİ
// ==========================================
final ValueNotifier<int> globalPuan = ValueNotifier<int>(0);
final ValueNotifier<String> kullaniciAdi = ValueNotifier<String>("");
final ValueNotifier<String> kullaniciEmail = ValueNotifier<String>("");

final ValueNotifier<String> kullaniciStili = ValueNotifier<String>("Belirlenmedi"); 

final ValueNotifier<List<ChatSession>> analizGecmisi = ValueNotifier([]);
final ValueNotifier<List<CommunityPost>> toplulukGonderileri = ValueNotifier([]);

const String apiUrl = "http://10.186.159.94:8000";

class KusursuzKocApp extends StatelessWidget {
  const KusursuzKocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İlişki ve Gelişim Asistanı',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F6F9), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFFFF6584),
        ),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}

// ==========================================
// 3. ONBOARDING (KARŞILAMA EKRANLARI)
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "icon": "✨",
      "title": "İlişki Asistanına\nHoş Geldin",
      "desc": "Kendi bağlanma stilini keşfet, tetiklenmelerini yönet ve daha sağlıklı bir iletişim kur.",
      "color": "0xFF6C63FF"
    },
    {
      "icon": "📝",
      "title": "Bilimsel Test",
      "desc": "İlk adım olarak literatürdeki geçerli testleri çözerek bağlanma stilini nokta atışı belirle.",
      "color": "0xFF4CAF50"
    },
    {
      "icon": "🧠",
      "title": "Yapay Zeka Koçu",
      "desc": "Belirlenen stiline özel olarak eğitilmiş yapay zeka asistanınla dilediğin zaman dertleş.",
      "color": "0xFFFF6584"
    },
    {
      "icon": "🤝",
      "title": "Topluluk Desteği",
      "desc": "Seninle benzer hisleri paylaşan insanlarla bir araya gel, deneyimlerini anonim paylaş.",
      "color": "0xFF5C6BC0"
    }
  ];

  void _onayVeGec() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const AuthScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onayVeGec,
                child: const Text(
                  "Atla", 
                  style: TextStyle(
                    color: Colors.grey, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  )
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Color(int.parse(_onboardingData[index]["color"]!)).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _onboardingData[index]["icon"]!, 
                            style: const TextStyle(fontSize: 80)
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          _onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: Color(int.parse(_onboardingData[index]["color"]!)), 
                            height: 1.2
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16, 
                            color: Colors.grey, 
                            height: 1.5
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                            ? const Color(0xFF6C63FF) 
                            : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _onayVeGec();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400), 
                          curve: Curves.easeInOut
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? "Başla" : "Devam", 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      )
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. GİRİŞ VE KAYIT EKRANI (AUTH)
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true; 
  bool isLoading = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  Future<void> _authenticate() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
    
    setState(() {
      isLoading = true;
    });

    final endpoint = isLogin ? "/auth/giris" : "/auth/kayit";
    final url = Uri.parse('$apiUrl$endpoint'); 

    Map<String, dynamic> payload = {
      "email": emailCtrl.text.trim(),
      "password": passCtrl.text.trim(),
    };

    if (!isLogin) {
      payload["name"] = nameCtrl.text.trim();
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        kullaniciAdi.value = decoded['name'];
        kullaniciEmail.value = decoded['email'];
        
        final prefs = await SharedPreferences.getInstance();
        bool isTestedLocally = prefs.getBool('tested_${decoded['email']}') ?? false;
        String localStil = prefs.getString('stil_${decoded['email']}') ?? "Güvenli Bağlanma";
        
        bool hasTested = decoded['has_tested'] == 1 || decoded['has_tested'] == true || isTestedLocally;
        
        if (hasTested) {
          kullaniciStili.value = (decoded['attachment_style'] != null && decoded['attachment_style'] != "") 
              ? decoded['attachment_style'] 
              : localStil;
              
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const RootScreen())
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const AttachmentTestScreen())
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['detail']), 
            backgroundColor: Colors.redAccent
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sunucuya bağlanılamadı. Python sunucusunun çalıştığından emin ol."), 
          backgroundColor: Colors.redAccent
        )
      );
    }
    
    setState(() {
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.psychology_rounded, 
                  size: 100, 
                  color: Color(0xFF6C63FF)
                ),
                const SizedBox(height: 20),
                Text(
                  isLogin ? "Tekrar Hoş Geldin" : "Hesap Oluştur",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF2D3142)
                  ),
                ),
                const SizedBox(height: 40),
                
                if (!isLogin) ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "İsim Soyisim", 
                      prefixIcon: const Icon(Icons.person), 
                      filled: true, 
                      fillColor: const Color(0xFFF4F6F9), 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), 
                        borderSide: BorderSide.none
                      )
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: "E-posta", 
                    prefixIcon: const Icon(Icons.email), 
                    filled: true, 
                    fillColor: const Color(0xFFF4F6F9), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), 
                      borderSide: BorderSide.none
                    )
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre", 
                    prefixIcon: const Icon(Icons.lock), 
                    filled: true, 
                    fillColor: const Color(0xFFF4F6F9), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), 
                      borderSide: BorderSide.none
                    )
                  ),
                ),
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF), 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 18), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)
                    )
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : Text(
                        isLogin ? "Giriş Yap" : "Kayıt Ol", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                ),
                const SizedBox(height: 20),
                
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin 
                      ? "Hesabın yok mu? Kayıt Ol" 
                      : "Zaten hesabın var mı? Giriş Yap", 
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. BAĞLANMA STİLİ TESTİ (30 SORU - RSQ/YİYÖ)
// ==========================================
class AttachmentTestScreen extends StatefulWidget {
  const AttachmentTestScreen({super.key});

  @override
  State<AttachmentTestScreen> createState() => _AttachmentTestScreenState();
}

class _AttachmentTestScreenState extends State<AttachmentTestScreen> {
  int _soruIndex = 0;
  
  double _toplamKaygiPuan = 0;
  int _kaygiSoruSayisi = 0;
  
  double _toplamKacinmaPuan = 0;
  int _kacinmaSoruSayisi = 0;

  final List<Map<String, dynamic>> _testSorulari = [
    {"text": "Başkalarına güvenmekte/bağımlı olmakta zorlanıyorum.", "type": "KACINMA"},
    {"text": "Bağımsız hissetmek benim için çok önemlidir.", "type": "KACINMA"},
    {"text": "Başkalarıyla duygusal olarak yakınlaşmayı kolay bulurum.", "type": "GUVENLI"},
    {"text": "Başka bir kişiyle tamamen bütünleşmek/bir olmak istiyorum.", "type": "KAYGI"},
    {"text": "Başkalarına çok yakınlaşırsam incinmekten korkarım.", "type": "KACINMA"},
    {"text": "Yakın duygusal ilişkilerim olmadan da rahatım.", "type": "KACINMA"},
    {"text": "İhtiyacım olduğunda başkalarının yanımda olacağından emin değilim.", "type": "KAYGI"},
    {"text": "Başkalarıyla tamamen duygusal bir yakınlık kurmak istiyorum.", "type": "KAYGI"},
    {"text": "Yalnız kalmaktan korkuyorum.", "type": "KAYGI"},
    {"text": "Başkalarına güvenmek/dayanmak konusunda rahatım.", "type": "GUVENLI"},
    {"text": "Sık sık romantik partnerlerimin beni gerçekten sevmediğinden endişelenirim.", "type": "KAYGI"},
    {"text": "Başkalarına tamamen güvenmekte zorlanıyorum.", "type": "KACINMA"},
    {"text": "Başkalarının bana çok yaklaşmasından endişe duyarım.", "type": "KACINMA"},
    {"text": "Duygusal olarak yakın ilişkiler istiyorum.", "type": "KAYGI"},
    {"text": "Başkalarının bana güvenmesi/bağımlı olması konusunda rahatım.", "type": "GUVENLI"},
    {"text": "Başkalarının bana, benim onlara verdiğim kadar değer vermediğinden endişelenirim.", "type": "KAYGI"},
    {"text": "İhtiyacınız olduğunda insanlar asla yanınızda olmazlar.", "type": "KACINMA"},
    {"text": "Tamamen bütünleşme arzum bazen insanları korkutup kaçırıyor.", "type": "KAYGI"},
    {"text": "Kendi kendime yetebilmek benim için çok önemlidir.", "type": "KACINMA"},
    {"text": "Birisi bana çok yaklaştığında gerginleşirim.", "type": "KACINMA"},
    {"text": "Sık sık romantik partnerlerimin benimle kalmak istemeyeceğinden endişelenirim.", "type": "KAYGI"},
    {"text": "Başkalarının bana bağımlı/muhtaç olmamasını tercih ederim.", "type": "KACINMA"},
    {"text": "Terk edilmekten korkuyorum.", "type": "KAYGI"},
    {"text": "Başkalarına yakın olmak beni biraz rahatsız eder.", "type": "KACINMA"},
    {"text": "Başkalarının benim istediğim kadar yakınlaşmakta isteksiz olduğunu görüyorum.", "type": "KAYGI"},
    {"text": "Başkalarına güvenmemeyi/bağımlı olmamayı tercih ederim.", "type": "KACINMA"},
    {"text": "İhtiyacım olduğunda başkalarının yanımda olacağını biliyorum.", "type": "GUVENLI"},
    {"text": "Başkalarının beni kabul etmemesinden endişe duyarım.", "type": "KAYGI"},
    {"text": "Romantik partnerlerim genellikle benim rahat hissettiğimden daha yakın olmak isterler.", "type": "KACINMA"},
    {"text": "Başkalarıyla yakınlaşmayı nispeten kolay bulurum.", "type": "GUVENLI"},
  ];

  void _soruyuCevapla(int secilenPuan) async {
    final soruTipi = _testSorulari[_soruIndex]["type"];

    if (soruTipi == "KAYGI") {
      _toplamKaygiPuan += secilenPuan;
      _kaygiSoruSayisi++;
    } else if (soruTipi == "KACINMA") {
      _toplamKacinmaPuan += secilenPuan;
      _kacinmaSoruSayisi++;
    } else if (soruTipi == "GUVENLI") {
      _toplamKaygiPuan += (6 - secilenPuan);
      _toplamKacinmaPuan += (6 - secilenPuan);
      _kaygiSoruSayisi++;
      _kacinmaSoruSayisi++;
    }

    if (_soruIndex < _testSorulari.length - 1) {
      setState(() {
        _soruIndex++;
      });
    } else {
      _testiSonuclandir();
    }
  }

  void _testiSonuclandir() async {
    // Sadece ortalamaları hesapla
    double kaygiOrtalama = _toplamKaygiPuan / (_kaygiSoruSayisi > 0 ? _kaygiSoruSayisi : 1);
    double kacinmaOrtalama = _toplamKacinmaPuan / (_kacinmaSoruSayisi > 0 ? _kacinmaSoruSayisi : 1);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
      );
    }

    String belirlenenStil = "Güvenli Bağlanma"; // Hata olursa diye varsayılan

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/testi-analiz-et'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": kullaniciEmail.value,
          "kaygi_puani": kaygiOrtalama,
          "kacinma_puani": kacinmaOrtalama
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        belirlenenStil = decoded['sistem_karari']; 
      }
    } catch (e) {
      debugPrint("Sunucu hatası: $e");
    }

    if (mounted) {
      Navigator.pop(context); 
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tested_${kullaniciEmail.value}', true);
    await prefs.setString('stil_${kullaniciEmail.value}', belirlenenStil);

    kullaniciStili.value = belirlenenStil;
    globalPuan.value += 100; 

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(30),
            title: const Column(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF6C63FF), size: 70),
                SizedBox(height: 15),
                Text(
                  "Test Tamamlandı!", 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF2D3142))
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Verdiğin cevaplara göre bağlanma stilin:",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Text(
                    belirlenenStil,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF6C63FF)),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Artık yapay zeka asistanın seninle tamamen bu stile uygun, sana özel bir iletişim kuracak.",
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, fontSize: 14),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const RootScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  child: const Text("Tamam, Başlayalım", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          );
        }
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final mevcutSoru = _testSorulari[_soruIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      
      // YENİ EKLENEN ÜST BAR VE "SONRA YAP" BUTONU
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const RootScreen())
              );
            },
            child: const Text(
              "Sonra Yap", 
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_soruIndex + 1) / _testSorulari.length, 
                color: const Color(0xFF6C63FF), 
                backgroundColor: const Color(0xFFE8EAF6), 
                minHeight: 6
              ),
              const SizedBox(height: 40),
              
              Text(
                "Soru ${_soruIndex + 1} / ${_testSorulari.length}", 
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: Center(
                  child: Text(
                    mevcutSoru["text"], 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF2D3142), 
                      height: 1.4
                    )
                  ),
                ),
              ),
              
              Column(
                children: [
                  _buildLikertButton("Kesinlikle Katılıyorum (5)", 5, const Color(0xFF6C63FF)),
                  const SizedBox(height: 10),
                  _buildLikertButton("Katılıyorum (4)", 4, const Color(0xFF8A84FF)),
                  const SizedBox(height: 10),
                  _buildLikertButton("Kararsızım (3)", 3, Colors.grey),
                  const SizedBox(height: 10),
                  _buildLikertButton("Katılmıyorum (2)", 2, const Color(0xFFFF8A9E)),
                  const SizedBox(height: 10),
                  _buildLikertButton("Kesinlikle Katılmıyorum (1)", 1, const Color(0xFFFF6584)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikertButton(String text, int puan, Color color) {
    return SizedBox(
      width: double.infinity, 
      height: 55,
      child: ElevatedButton(
        onPressed: () => _soruyuCevapla(puan),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, 
          foregroundColor: color, 
          elevation: 0, 
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        child: Text(
          text, 
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}

// ==========================================
// 6. ANA YAPI: ALT MENÜ (ROOT SCREEN)
// ==========================================
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _seciliSekme = 0;
  
  final List<Widget> _sekmeler = [
    const HomeTab(),
    const CommunityTab(),
    const WeatherTab(),
    const MascotTab(),
    const ProfileTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sekmeler[_seciliSekme],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 20, 
              offset: const Offset(0, -5)
            )
          ]
        ),
        child: NavigationBar(
          selectedIndex: _seciliSekme,
          onDestinationSelected: (index) {
            setState(() {
              _seciliSekme = index;
            });
          },
          backgroundColor: Colors.white, 
          elevation: 0, 
          indicatorColor: const Color(0xFFE8EAF6), 
          height: 75, 
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined), 
              selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFF6C63FF)), 
              label: "Asistan"
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline), 
              selectedIcon: Icon(Icons.people, color: Color(0xFF4CAF50)), 
              label: "Topluluk"
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud_outlined), 
              selectedIcon: Icon(Icons.cloud, color: Color(0xFF42A5F5)), 
              label: "Hava"
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined), 
              selectedIcon: Icon(Icons.pets, color: Colors.orange), 
              label: "Maskot"
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline), 
              selectedIcon: Icon(Icons.person, color: Colors.deepOrange), 
              label: "Profil"
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. ASİSTAN EKRANI (TEST STİLİYLE SOHBET BAŞLATIR)
// ==========================================
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _input = TextEditingController();
  bool _gorevYapildi = false;

  final List<String> olumlamalar = [
    "Kendi değerim başkalarının onayına bağlı değil.", 
    "Sınırlarımı korumak beni kötü biri yapmaz.", 
    "Duygularım geçerli ve onları yaşamaya hakkım var.", 
    "Kendimi olduğum gibi kabul ediyor ve seviyorum.",
    "Bana verilen sevgiye layığım."
  ];
  
  final List<String> gorevler = [
    "Kendine 10 dakika şefkat molası ver.", 
    "Bugün seni tetikleyen bir duyguyu not al.", 
    "Sevdiğin birine kısa bir teşekkür mesajı at.", 
    "Aynada kendine gülümse ve derin bir nefes al.",
    "Kötü bir düşünceyi, iyi bir düşünceyle değiştir."
  ];

  void _sohbetBaslat() {
    if (kullaniciStili.value == "Belirlenmedi" || kullaniciStili.value.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFFFF6584), size: 50),
              SizedBox(height: 10),
              Text("Asistan Seni Bekliyor!", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142), fontSize: 20)),
            ],
          ),
          content: const Text(
            "Yapay zeka koçunun seni doğru anlayıp, sana özel şefkatli tavsiyeler verebilmesi için önce bağlanma stilini öğrenmemiz gerekiyor.", 
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4)
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("İptal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AttachmentTestScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF), 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text("Testi Çöz", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        )
      );
      return;
    }
    final String ilkMesaj = _input.text.trim();
    if (ilkMesaj.isEmpty) return;

    FocusScope.of(context).unfocus();
    _input.clear();

    final yeniOturum = ChatSession(
      DateTime.now().millisecondsSinceEpoch.toString(),
      kullaniciStili.value, 
      [ChatMessage("user", ilkMesaj)]
    );

    analizGecmisi.value = [yeniOturum, ...analizGecmisi.value];
    
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          session: yeniOturum, 
          isNewAnalysis: true
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    int gunIndeksi = DateTime.now().day % olumlamalar.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, 
            padding: const EdgeInsets.only(top: 80, left: 30, right: 30, bottom: 80), 
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight, 
                colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)]
              ), 
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40), 
                bottomRight: Radius.circular(40)
              )
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: kullaniciAdi,
              builder: (context, isim, child) {
                String kisaIsim = isim.split(' ').isNotEmpty ? isim.split(' ')[0] : isim;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Merhaba, $kisaIsim ✨", 
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                    ), 
                    const SizedBox(height: 8),
                    const Text(
                      "Asistanın seni dinlemeye hazır.", 
                      style: TextStyle(color: Colors.white70, fontSize: 16)
                    ),
                  ],
                );
              }
            ),
          ),
          
          Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  
                  // EĞER TEST ÇÖZÜLMEDİYSE GÖSTERİLECEK HATIRLATICI KART
                  ValueListenableBuilder<String>(
                    valueListenable: kullaniciStili,
                    builder: (context, stil, child) {
                      if (stil == "Belirlenmedi" || stil.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF6584), Color(0xFFFF8A9E)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFF6584).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                            ]
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_late_rounded, color: Colors.white, size: 40),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Bağlanma Stilin Belirsiz", 
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      "Yapay zekanın sana özel çalışması için testi çözmelisin.", 
                                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AttachmentTestScreen()));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFFFF6584),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                        ),
                                        child: const Text("Testi Başlat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink(); 
                    },
                  ),

                  // Eski Kartlar (Günün Olumlaması vs.)
                  Container(
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ], 
                      border: const Border(
                        left: BorderSide(color: Color(0xFF4CAF50), width: 5)
                      )
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny_rounded, 
                          color: Colors.amber, 
                          size: 28
                        ), 
                        const SizedBox(width: 15), 
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              const Text(
                                "Günün Olumlaması", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
                              ), 
                              const SizedBox(height: 5), 
                              Text(
                                '"${olumlamalar[gunIndeksi]}"', 
                                style: const TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.w600, 
                                  fontStyle: FontStyle.italic
                                )
                              )
                            ]
                          )
                        )
                      ]
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ]
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10), 
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F9), 
                                borderRadius: BorderRadius.circular(12)
                              ), 
                              child: const Icon(Icons.star_rounded, color: Colors.orange)
                            ), 
                            const SizedBox(width: 15), 
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  const Text(
                                    "Günlük Odak", 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ), 
                                  Text(
                                    gorevler[gunIndeksi], 
                                    style: const TextStyle(color: Colors.grey, fontSize: 14)
                                  )
                                ]
                              )
                            )
                          ]
                        ),
                        const SizedBox(height: 15),
                        
                        SizedBox(
                          width: double.infinity, 
                          height: 45, 
                          child: ElevatedButton(
                            onPressed: _gorevYapildi ? null : () { 
                              setState(() {
                                _gorevYapildi = true; 
                              });
                              globalPuan.value += 25; 
                            }, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8EAF6), 
                              foregroundColor: const Color(0xFF6C63FF), 
                              elevation: 0, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)
                              )
                            ), 
                            child: Text(
                              _gorevYapildi ? "Tamamlandı (+25 XP)" : "Görevi Tamamla", 
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            )
                          )
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Zihnini Boşalt", 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF2D3142))
                  ), 
                  const SizedBox(height: 15),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ]
                    ), 
                    child: TextField(
                      controller: _input, 
                      maxLines: 5, 
                      decoration: InputDecoration(
                        hintText: "Zihninden neler geçiyor? Çekinmeden yaz...", 
                        hintStyle: TextStyle(color: Colors.grey[400]), 
                        contentPadding: const EdgeInsets.all(25), 
                        border: InputBorder.none
                      )
                    )
                  ), 
                  const SizedBox(height: 25),
                  
                  SizedBox(
                    width: double.infinity, 
                    height: 60, 
                    child: ElevatedButton(
                      onPressed: _sohbetBaslat, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF), 
                        foregroundColor: Colors.white, 
                        elevation: 5, 
                        shadowColor: const Color(0xFF6C63FF).withOpacity(0.5), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ), 
                      child: const Text(
                        "Yapay Zeka Asistanı ile Sohbet Et", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      )
                    )
                  ), 
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. DETAYLI SOHBET EKRANI (TEST STİLİ İLE)
// ==========================================
class ChatScreen extends StatefulWidget {
  final ChatSession session;
  final bool isNewAnalysis;

  const ChatScreen({
    super.key, 
    required this.session, 
    this.isNewAnalysis = false
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatInput = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    if (widget.isNewAnalysis) {
      _apiIstegiAt(widget.session.mesajlar.first.text, isFirstMessage: true);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    });
  }

  Future<void> _apiIstegiAt(String userText, {bool isFirstMessage = false}) async {
    setState(() {
      _isTyping = true;
    });
    
    _scrollToBottom();

    try {
      List<Map<String, dynamic>> apiGecmisi = [];
      for (var msg in widget.session.mesajlar) {
        if (!isFirstMessage && msg == widget.session.mesajlar.last) continue; 
        
        if (msg.text != userText) {
          apiGecmisi.add({
            "role": msg.role, 
            "parts": [msg.text]
          });
        }
      }

      final response = await http.post(
        Uri.parse('$apiUrl/mesaj-gonder'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "kullanici_id": kullaniciAdi.value,
          "yeni_mesaj": userText,
          "mevcut_stil": kullaniciStili.value, 
          "gecmis_konusma": apiGecmisi
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        
        setState(() {
          if (isFirstMessage) {
            globalPuan.value += 15;
          }
          widget.session.mesajlar.add(ChatMessage("model", decodedData['asistan_cevabi']));
          _isTyping = false;
        });
        
        analizGecmisi.value = List.from(analizGecmisi.value);
        _scrollToBottom();
      } else {
        setState(() { 
          widget.session.mesajlar.add(
            ChatMessage("model", "Sunucuya bağlanılamadı. Hata Kodu: ${response.statusCode}")
          ); 
          _isTyping = false; 
        });
      }
    } catch (e) {
      setState(() { 
        widget.session.mesajlar.add(
          ChatMessage("model", "Bağlantı hatası. Lütfen Python sunucusunun çalıştığından emin ol.")
        ); 
        _isTyping = false; 
      });
    }
  }

  void _kullaniciMesajiGonder() {
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;
    
    setState(() { 
      widget.session.mesajlar.add(ChatMessage("user", text)); 
      _chatInput.clear(); 
    });
    
    _apiIstegiAt(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text(
              "Kusursuz Asistan", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ), 
            Text(
              widget.session.teshis, 
              style: const TextStyle(fontSize: 13, color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)
            )
          ]
        ), 
        backgroundColor: Colors.white, 
        elevation: 1, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, 
              padding: const EdgeInsets.all(20), 
              itemCount: widget.session.mesajlar.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.session.mesajlar.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft, 
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10), 
                      child: Row(
                        children: [
                          SizedBox(
                            width: 15, 
                            height: 15, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))
                          ), 
                          SizedBox(width: 10), 
                          Text(
                            "Asistan düşünüyor...", 
                            style: TextStyle(color: Colors.grey, fontSize: 13)
                          )
                        ]
                      )
                    )
                  );
                }
                
                final msg = widget.session.mesajlar[index]; 
                bool isMe = msg.role == "user";
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, 
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15), 
                    padding: const EdgeInsets.all(16), 
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75
                    ), 
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF6C63FF) : Colors.white, 
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20), 
                        topRight: const Radius.circular(20), 
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5), 
                        bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20)
                      ), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05), 
                          blurRadius: 10, 
                          offset: const Offset(0, 5)
                        )
                      ]
                    ), 
                    child: Text(
                      msg.text, 
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF2D3142), 
                        height: 1.4, 
                        fontSize: 15
                      )
                    )
                  )
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), 
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 15, 
                  offset: const Offset(0, -5)
                )
              ]
            ), 
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F9), 
                        borderRadius: BorderRadius.circular(25)
                      ), 
                      child: TextField(
                        controller: _chatInput, 
                        decoration: const InputDecoration(
                          hintText: "Asistana cevap ver...", 
                          border: InputBorder.none, 
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                        )
                      )
                    )
                  ), 
                  const SizedBox(width: 10), 
                  GestureDetector(
                    onTap: _isTyping ? null : _kullaniciMesajiGonder, 
                    child: Container(
                      padding: const EdgeInsets.all(15), 
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF), 
                        shape: BoxShape.circle
                      ), 
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)
                    )
                  )
                ]
              )
            )
          )
        ],
      ),
    );
  }
}

// ==========================================
// 9. TOPLULUK EKRANI (GÖRSEL KARTLAR VE ROZETLİ)
// ==========================================
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override 
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  bool isLoading = true;

  @override 
  void initState() { 
    super.initState(); 
    _gonderileriGetir(); 
  }

  Future<void> _gonderileriGetir() async {
    try {
      final res = await http.get(Uri.parse('$apiUrl/topluluk/gonderiler'));
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        
        toplulukGonderileri.value = data.map((e) {
          final commentsList = (e['comments'] as List)
            .map((c) => PostComment(c['author'], c['text']))
            .toList();
            
          return CommunityPost(
            e['id'], 
            e['author'], 
            e['content'], 
            e['likes'], 
            false, 
            commentsList
          );
        }).toList();
      }
    } catch (e) { 
      debugPrint("Gönderi çekme hatası: $e"); 
    }
    
    setState(() {
      isLoading = false;
    });
  }

  void _yeniGonderiEkle(BuildContext context) {
    final TextEditingController textCtrl = TextEditingController(); 
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30))
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, 
                left: 25, 
                right: 25, 
                top: 25
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Düşüncelerini Paylaş", 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF2D3142)
                    )
                  ), 
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: textCtrl, 
                    maxLines: 4, 
                    decoration: InputDecoration(
                      hintText: "Neler hissediyorsun?", 
                      filled: true, 
                      fillColor: const Color(0xFFF4F6F9), 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), 
                        borderSide: BorderSide.none
                      )
                    )
                  ), 
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Checkbox(
                        value: isAnonymous, 
                        activeColor: const Color(0xFF6C63FF), 
                        onChanged: (v) {
                          setModalState(() {
                            isAnonymous = v!;
                          });
                        }
                      ), 
                      const Text(
                        "Anonim olarak paylaş", 
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                      )
                    ]
                  ), 
                  const SizedBox(height: 15),
                  
                  SizedBox(
                    width: double.infinity, 
                    height: 55, 
                    child: ElevatedButton(
                      onPressed: () async {
                        if (textCtrl.text.trim().isEmpty) return; 
                        Navigator.pop(context);
                        
                        final author = isAnonymous ? "Anonim 🦊" : kullaniciAdi.value;
                        
                        await http.post(
                          Uri.parse('$apiUrl/topluluk/paylas'), 
                          headers: {"Content-Type": "application/json"}, 
                          body: jsonEncode({
                            "author": author, 
                            "content": textCtrl.text.trim()
                          })
                        ); 
                        
                        _gonderileriGetir(); 
                      }, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF), 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                        )
                      ), 
                      child: const Text(
                        "Paylaş", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      )
                    )
                  ), 
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _yorumlariAc(BuildContext context, CommunityPost post) {
    final TextEditingController yorumCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) { 
        return StatefulBuilder(
          builder: (context, setModalState) { 
            return Container(
              height: MediaQuery.of(context).size.height * 0.75, 
              decoration: const BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))
              ), 
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 15, bottom: 10), 
                    height: 5, 
                    width: 50, 
                    decoration: BoxDecoration(
                      color: Colors.grey[300], 
                      borderRadius: BorderRadius.circular(10)
                    )
                  ), 
                  const Text(
                    "Yorumlar", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ), 
                  const Divider(height: 30), 
                  
                  Expanded(
                    child: post.comments.isEmpty 
                      ? const Center(
                          child: Text(
                            "İlk yorumu sen yap!", 
                            style: TextStyle(color: Colors.grey)
                          )
                        ) 
                      : ListView.builder(
                          itemCount: post.comments.length, 
                          itemBuilder: (context, i) { 
                            final comment = post.comments[i]; 
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  CircleAvatar(
                                    radius: 16, 
                                    backgroundColor: const Color(0xFFE8EAF6), 
                                    child: Text(
                                      comment.author[0], 
                                      style: const TextStyle(
                                        color: Color(0xFF6C63FF), 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 14
                                      )
                                    )
                                  ), 
                                  const SizedBox(width: 12), 
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12), 
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F6F9), 
                                        borderRadius: BorderRadius.circular(15)
                                      ), 
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start, 
                                        children: [
                                          Text(
                                            comment.author, 
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 13, 
                                              color: Color(0xFF2D3142)
                                            )
                                          ), 
                                          const SizedBox(height: 4), 
                                          Text(
                                            comment.text, 
                                            style: const TextStyle(fontSize: 14)
                                          )
                                        ]
                                      )
                                    )
                                  )
                                ]
                              )
                            ); 
                          }
                        ),
                  ), 
                  
                  Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
                      left: 20, 
                      right: 20, 
                      top: 10
                    ), 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05), 
                          blurRadius: 10, 
                          offset: const Offset(0, -5)
                        )
                      ]
                    ), 
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F9), 
                                borderRadius: BorderRadius.circular(25)
                              ), 
                              child: TextField(
                                controller: yorumCtrl, 
                                decoration: const InputDecoration(
                                  hintText: "Desteğini göster...", 
                                  border: InputBorder.none, 
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                                )
                              )
                            )
                          ), 
                          const SizedBox(width: 10), 
                          GestureDetector(
                            onTap: () async { 
                              if (yorumCtrl.text.trim().isEmpty) return; 
                              final text = yorumCtrl.text.trim(); 
                              yorumCtrl.clear(); 
                              
                              setModalState(() {
                                post.comments.add(
                                  PostComment(kullaniciAdi.value, text)
                                );
                              });
                              
                              toplulukGonderileri.value = List.from(toplulukGonderileri.value); 
                              
                              await http.post(
                                Uri.parse('$apiUrl/topluluk/${post.id}/yorum'), 
                                headers: {"Content-Type": "application/json"}, 
                                body: jsonEncode({
                                  "author": kullaniciAdi.value, 
                                  "text": text
                                })
                              ); 
                            }, 
                            child: Container(
                              padding: const EdgeInsets.all(12), 
                              decoration: const BoxDecoration(
                                color: Color(0xFF6C63FF), 
                                shape: BoxShape.circle
                              ), 
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)
                            )
                          )
                        ]
                      )
                    )
                  ) 
                ]
              )
            ); 
          }
        ); 
      }
    );
  }

  Widget _buildPostContent(String content) {
    if (content.startsWith('MOOD_SHARE|')) {
      final parts = content.split('|');
      final moodLevel = double.tryParse(parts.length > 1 ? parts[1] : '50') ?? 50.0;
      final moodDurumu = parts.length > 2 ? parts[2] : "";
      
      Color bgColor; 
      IconData icon; 
      String titleText;
      
      if (moodLevel < 20) { 
        bgColor = const Color(0xFF455A64); 
        icon = Icons.thunderstorm_rounded; 
        titleText = "İçinde fırtınalar kopuyor."; 
      } else if (moodLevel < 40) { 
        bgColor = const Color(0xFF78909C); 
        icon = Icons.water_drop_rounded; 
        titleText = "Hava yağmurlu. Desteğe ihtiyacı var."; 
      } else if (moodLevel < 60) { 
        bgColor = const Color(0xFFB39DDB); 
        icon = Icons.cloud_rounded; 
        titleText = "Düşünceleri bulutlu."; 
      } else if (moodLevel < 80) { 
        bgColor = const Color(0xFFFFD54F); 
        icon = Icons.wb_cloudy_rounded; 
        titleText = "Güneş yüzünü gösteriyor!"; 
      } else { 
        bgColor = const Color(0xFF64B5F6); 
        icon = Icons.wb_sunny_rounded; 
        titleText = "Gökyüzü pırıl pırıl!"; 
      }
      
      return Container(
        width: double.infinity, 
        margin: const EdgeInsets.only(top: 10), 
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20), 
        decoration: BoxDecoration(
          color: bgColor, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.4), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ]
        ), 
        child: Column(
          children: [
            Icon(icon, size: 70, color: Colors.white), 
            const SizedBox(height: 15), 
            Text(
              titleText, 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
            ), 
            const SizedBox(height: 8), 
            Text(
              "Şu an $moodDurumu hissediyor.", 
              style: const TextStyle(color: Colors.white70, fontSize: 15)
            )
          ]
        )
      );
      
    } else if (content.startsWith('MASCOT_SHARE|')) {
      final parts = content.split('|'); 
      final stageName = parts.length > 1 ? parts[1] : ""; 
      final emoji = parts.length > 2 ? parts[2] : "🦊";
      
      return Container(
        width: double.infinity, 
        margin: const EdgeInsets.only(top: 10), 
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20), 
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)], 
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight
          ), 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9A9E).withOpacity(0.4), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ]
        ), 
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), 
              child: Text(emoji, style: const TextStyle(fontSize: 50))
            ), 
            const SizedBox(height: 20), 
            const Text(
              "Evrim Tamamlandı! ✨", 
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)
            ), 
            const SizedBox(height: 5), 
            Text(
              "Maskotu '$stageName' seviyesine ulaştı", 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)
            )
          ]
        )
      );
    }
    
    // Normal metin
    return Text(
      content, 
      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Topluluk", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _yeniGonderiEkle(context), 
        backgroundColor: const Color(0xFF6C63FF), 
        icon: const Icon(Icons.edit, color: Colors.white), 
        label: const Text("Paylaş", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        : ValueListenableBuilder<List<CommunityPost>>(
            valueListenable: toplulukGonderileri,
            builder: (context, posts, child) {
              if (posts.isEmpty) {
                return const Center(
                  child: Text("Henüz hiç gönderi yok. İlk paylaşan sen ol!", style: TextStyle(color: Colors.grey))
                );
              }
              
              return ListView.builder(
                physics: const BouncingScrollPhysics(), 
                padding: const EdgeInsets.all(20), 
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20), 
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22, 
                              backgroundColor: const Color(0xFFE8EAF6), 
                              child: Text(
                                post.author[0], 
                                style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w900, fontSize: 18)
                              )
                            ), 
                            const SizedBox(width: 12), 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.author, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))
                                ),
                                // YAZARIN İSMİNİN ALTINDAKİ ŞIK STİL ROZETİ
                                Container(
                                  margin: const EdgeInsets.only(top: 4), 
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withOpacity(0.1), 
                                    borderRadius: BorderRadius.circular(8)
                                  ), 
                                  child: ValueListenableBuilder<String>(
                                    valueListenable: kullaniciStili, 
                                    builder: (context, stil, child) { 
                                      return Text(
                                        stil, 
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)
                                      ); 
                                    }
                                  )
                                ),
                              ],
                            )
                          ]
                        ), 
                        const SizedBox(height: 15),
                        
                        _buildPostContent(post.content),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15), 
                          child: Divider(height: 1)
                        ),
                        
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async { 
                                post.isLiked = !post.isLiked; 
                                post.likes += post.isLiked ? 1 : -1; 
                                toplulukGonderileri.value = List.from(toplulukGonderileri.value); 
                                
                                if (post.isLiked) {
                                  await http.post(Uri.parse('$apiUrl/topluluk/${post.id}/begen')); 
                                }
                              }, 
                              child: Row(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300), 
                                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child), 
                                    child: Icon(
                                      post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                      key: ValueKey(post.isLiked), 
                                      color: post.isLiked ? const Color(0xFFFF6584) : Colors.grey, 
                                      size: 22
                                    )
                                  ), 
                                  const SizedBox(width: 6), 
                                  Text(
                                    "${post.likes}", 
                                    style: TextStyle(color: post.isLiked ? const Color(0xFFFF6584) : Colors.grey, fontWeight: FontWeight.bold)
                                  )
                                ]
                              )
                            ), 
                            const SizedBox(width: 25),
                            
                            GestureDetector(
                              onTap: () => _yorumlariAc(context, post), 
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey, size: 20), 
                                  const SizedBox(width: 6), 
                                  Text(
                                    "${post.comments.length}", 
                                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                                  )
                                ]
                              )
                            )
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            }
          ),
    );
  }
}

// ==========================================
// 10. DUYGU & HAVA DURUMU
// ==========================================
class WeatherTab extends StatefulWidget {
  const WeatherTab({super.key});

  @override 
  State<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<WeatherTab> with SingleTickerProviderStateMixin {
  double _moodLevel = 50.0;
  bool _isBreathing = false;
  late AnimationController _breatheController;

  @override 
  void initState() { 
    super.initState(); 
    _breatheController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 4)
    ); 
    
    _breatheController.addStatusListener((status) { 
      if (status == AnimationStatus.completed) { 
        _breatheController.reverse(); 
      } else if (status == AnimationStatus.dismissed) { 
        _breatheController.forward(); 
      } 
    }); 
  }
  
  @override 
  void dispose() { 
    _breatheController.dispose(); 
    super.dispose(); 
  }

  Color get _bgColor { 
    if (_moodLevel < 20) return const Color(0xFF455A64); 
    if (_moodLevel < 40) return const Color(0xFF78909C); 
    if (_moodLevel < 60) return const Color(0xFFB39DDB); 
    if (_moodLevel < 80) return const Color(0xFFFFD54F); 
    return const Color(0xFF64B5F6); 
  }
  
  IconData get _weatherIcon { 
    if (_moodLevel < 20) return Icons.thunderstorm_rounded; 
    if (_moodLevel < 40) return Icons.water_drop_rounded; 
    if (_moodLevel < 60) return Icons.cloud_rounded; 
    if (_moodLevel < 80) return Icons.wb_cloudy_rounded; 
    return Icons.wb_sunny_rounded; 
  }
  
  String get _weatherText { 
    if (_moodLevel < 20) return "İçinde fırtınalar kopuyor."; 
    if (_moodLevel < 40) return "Hava yağmurlu. Kendine şefkat göster."; 
    if (_moodLevel < 60) return "Düşüncelerin bulutlu."; 
    if (_moodLevel < 80) return "Güneş yüzünü gösteriyor!"; 
    return "Gökyüzü pırıl pırıl!"; 
  }
  
  String get _moodDurumu { 
    if (_moodLevel < 20) return "krizde"; 
    if (_moodLevel < 40) return "biraz huzursuz"; 
    if (_moodLevel < 60) return "karmaşık"; 
    if (_moodLevel < 80) return "sakin"; 
    return "harika"; 
  }

  void _toplulugaPaylas() async {
    final mesaj = "MOOD_SHARE|$_moodLevel|$_moodDurumu";
    try { 
      await http.post(
        Uri.parse('$apiUrl/topluluk/paylas'), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({
          "author": kullaniciAdi.value, 
          "content": mesaj
        })
      ); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Hislerin Görsel Olarak Paylaşıldı! 💙", 
            style: TextStyle(fontWeight: FontWeight.bold)
          ), 
          backgroundColor: const Color(0xFF6C63FF), 
          behavior: SnackBarBehavior.floating, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        )
      ); 
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paylaşım başarısız."), backgroundColor: Colors.red)
      ); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600), 
      color: _bgColor, 
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _isBreathing 
                ? AnimatedBuilder(
                    animation: _breatheController, 
                    builder: (context, child) { 
                      return Container(
                        width: 150 + (_breatheController.value * 100), 
                        height: 150 + (_breatheController.value * 100), 
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: Colors.white.withOpacity(0.3)
                        ), 
                        alignment: Alignment.center, 
                        child: Text(
                          _breatheController.status == AnimationStatus.forward ? "Nefes Al" : "Nefes Ver", 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                        )
                      ); 
                    }
                  ) 
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400), 
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child), 
                        child: Icon(
                          _weatherIcon, 
                          key: ValueKey(_weatherIcon), 
                          size: 180, 
                          color: Colors.white.withOpacity(0.95)
                        )
                      ), 
                      const SizedBox(height: 30), 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40), 
                        child: Text(
                          _weatherText, 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, height: 1.4)
                        )
                      )
                    ]
                  ),
            )
          ), 
          
          Container(
            padding: const EdgeInsets.all(30), 
            decoration: const BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40), 
                topRight: Radius.circular(40)
              )
            ), 
            child: SafeArea(
              top: false, 
              child: Column(
                children: [
                  Text(
                    _isBreathing ? "Kendi ritmine odaklan..." : "Şu an tam olarak nasılsın?", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))
                  ), 
                  const SizedBox(height: 15), 
                  
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF6C63FF), 
                      inactiveTrackColor: const Color(0xFFE8EAF6), 
                      thumbColor: const Color(0xFF6C63FF), 
                      trackHeight: 8.0, 
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0)
                    ), 
                    child: Slider(
                      value: _moodLevel, 
                      min: 0, 
                      max: 100, 
                      onChanged: _isBreathing 
                        ? null 
                        : (val) { 
                            setState(() { 
                              _moodLevel = val; 
                            }); 
                          }
                    )
                  ), 
                  
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text("Krizdeyim", style: TextStyle(color: Color(0xFFFF6584), fontWeight: FontWeight.bold)), 
                      Text("Huzurluyum", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold))
                    ]
                  ), 
                  const SizedBox(height: 25), 
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () { 
                            setState(() { 
                              _isBreathing = !_isBreathing; 
                              _isBreathing ? _breatheController.forward() : _breatheController.stop(); 
                            }); 
                          }, 
                          icon: Icon(
                            _isBreathing ? Icons.stop_circle_outlined : Icons.air_rounded
                          ), 
                          label: Text(
                            _isBreathing ? "Bitir" : "Nefes Egzersizi", 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ), 
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6C63FF), 
                            side: const BorderSide(color: Color(0xFF6C63FF), width: 2), 
                            padding: const EdgeInsets.symmetric(vertical: 15), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          )
                        )
                      ), 
                      const SizedBox(width: 15), 
                      
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isBreathing ? null : _toplulugaPaylas, 
                          icon: const Icon(Icons.people_alt_rounded, size: 18), 
                          label: const Text(
                            "Topluluğa At", 
                            style: TextStyle(fontWeight: FontWeight.bold)
                          ), 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF), 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(vertical: 15), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          )
                        )
                      )
                    ]
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}

// ==========================================
// 11. ORTAK MASKOT EVRİMİ
// ==========================================
class MascotTab extends StatelessWidget {
  const MascotTab({super.key});

  final List<Map<String, dynamic>> _stages = const [
    {"emoji": "🦊", "name": "Uyuyan Yavru", "xp_needed": 0, "size": 60.0},
    {"emoji": "🦊", "name": "Minik Tilki", "xp_needed": 30, "size": 80.0},
    {"emoji": "🦊", "name": "Meraklı Tilki", "xp_needed": 80, "size": 100.0},
    {"emoji": "🦊", "name": "Genç Tilki", "xp_needed": 150, "size": 120.0},
    {"emoji": "🦊", "name": "Yetişkin Tilki", "xp_needed": 300, "size": 140.0},
    {"emoji": "🦊✨", "name": "Bilge Tilki", "xp_needed": 600, "size": 145.0}, 
  ];

  void _maskotuPaylas(BuildContext context, String stageName, String emoji) async {
    final mesaj = "MASCOT_SHARE|$stageName|$emoji";
    
    try { 
      await http.post(
        Uri.parse('$apiUrl/topluluk/paylas'), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({
          "author": kullaniciAdi.value, 
          "content": mesaj
        })
      ); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Maskot Kartı Toplulukta Paylaşıldı! 🎉", 
            style: TextStyle(fontWeight: FontWeight.bold)
          ), 
          backgroundColor: const Color(0xFF6C63FF), 
          behavior: SnackBarBehavior.floating, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        )
      ); 
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paylaşım başarısız."), backgroundColor: Colors.red)
      ); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maskotumuz", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: globalPuan,
        builder: (context, puan, child) {
          int currentLevel = 0;
          for (int i = 0; i < _stages.length; i++) { 
            if (puan >= _stages[i]["xp_needed"]) { 
              currentLevel = i; 
            } 
          }
          
          bool isMax = currentLevel == _stages.length - 1; 
          int nextXp = isMax ? puan : _stages[currentLevel + 1]["xp_needed"]; 
          int currentStageXp = _stages[currentLevel]["xp_needed"]; 
          double progress = isMax 
            ? 1.0 
            : (puan - currentStageXp) / (nextXp - currentStageXp);
            
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Container(
                  width: 240, 
                  height: 240, 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: Colors.white, 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2), 
                        blurRadius: 50, 
                        spreadRadius: 10
                      )
                    ]
                  ), 
                  alignment: Alignment.center, 
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800), 
                    child: Text(
                      _stages[currentLevel]["emoji"], 
                      key: ValueKey(currentLevel), 
                      style: TextStyle(fontSize: _stages[currentLevel]["size"])
                    )
                  )
                ), 
                const SizedBox(height: 30), 
                
                Text(
                  "Evrim ${currentLevel + 1}: ${_stages[currentLevel]["name"]}", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))
                ), 
                const SizedBox(height: 10), 
                
                Text(
                  "Asistanla konuştukça ve görevleri yaptıkça büyür.", 
                  style: TextStyle(color: Colors.grey[600])
                ), 
                const SizedBox(height: 40), 
                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40), 
                  padding: const EdgeInsets.all(25), 
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24), 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04), 
                        blurRadius: 20, 
                        offset: const Offset(0, 8)
                      )
                    ]
                  ), 
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(
                            "Gelişim XP: $puan", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)
                          ), 
                          Text(
                            isMax ? "Maksimum" : "Hedef: $nextXp", 
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                          )
                        ]
                      ), 
                      const SizedBox(height: 15), 
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10), 
                        child: LinearProgressIndicator(
                          value: progress, 
                          minHeight: 12, 
                          backgroundColor: const Color(0xFFF4F6F9), 
                          color: Colors.orangeAccent
                        )
                      ), 
                      const SizedBox(height: 20), 
                      
                      SizedBox(
                        width: double.infinity, 
                        child: OutlinedButton.icon(
                          onPressed: () => _maskotuPaylas(
                            context, 
                            _stages[currentLevel]["name"], 
                            _stages[currentLevel]["emoji"]
                          ), 
                          icon: const Icon(Icons.share_rounded, size: 18), 
                          label: const Text(
                            "Evrimini Toplulukta Paylaş", 
                            style: TextStyle(fontWeight: FontWeight.bold)
                          ), 
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange, 
                            side: const BorderSide(color: Colors.orange), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          )
                        )
                      )
                    ]
                  )
                )
              ]
            )
          );
        },
      ),
    );
  }
}

// ==========================================
// 12. PROFİL VE İSTATİSTİKLER EKRANI
// ==========================================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _profilDuzenle(BuildContext context) {
    final nameCtrl = TextEditingController(text: kullaniciAdi.value);
    final emailCtrl = TextEditingController(text: kullaniciEmail.value);
    
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30))
      ), 
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, 
          left: 30, 
          right: 30, 
          top: 30
        ), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text(
              "Bilgilerini Güncelle", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))
            ), 
            const SizedBox(height: 25), 
            
            TextField(
              controller: nameCtrl, 
              decoration: InputDecoration(
                labelText: "İsim Soyisim", 
                filled: true, 
                fillColor: const Color(0xFFF4F6F9), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
              )
            ), 
            const SizedBox(height: 15), 
            
            TextField(
              controller: emailCtrl, 
              decoration: InputDecoration(
                labelText: "E-posta", 
                filled: true, 
                fillColor: const Color(0xFFF4F6F9), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
              )
            ), 
            const SizedBox(height: 30), 
            
            SizedBox(
              width: double.infinity, 
              height: 55, 
              child: ElevatedButton(
                onPressed: () { 
                  kullaniciAdi.value = nameCtrl.text; 
                  kullaniciEmail.value = emailCtrl.text; 
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil bilgileri güncellendi!"), backgroundColor: Colors.green)
                  ); 
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF), 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ), 
                child: const Text(
                  "Değişiklikleri Kaydet", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                )
              )
            ), 
            const SizedBox(height: 30)
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & İstatistikler", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), 
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ValueListenableBuilder<String>(
                valueListenable: kullaniciAdi,
                builder: (context, isim, child) {
                  return Column(
                    children: [
                      const CircleAvatar(
                        radius: 50, 
                        backgroundColor: Color(0xFFE8EAF6), 
                        child: Icon(Icons.person, size: 55, color: Color(0xFF6C63FF))
                      ), 
                      const SizedBox(height: 15),
                      
                      Text(
                        isim, 
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))
                      ), 
                      const SizedBox(height: 5),
                      
                      // PROFİLDE BAĞLANMA STİLİ GÖSTERİMİ
                      ValueListenableBuilder<String>(
                        valueListenable: kullaniciStili, 
                        builder: (context, stil, child) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              "🎯 $stil", 
                              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)
                            ),
                          );
                        }
                      ),
                      
                      ValueListenableBuilder<String>(
                        valueListenable: kullaniciEmail, 
                        builder: (context, email, child) { 
                          return Text(
                            email, 
                            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)
                          ); 
                        }
                      ), 
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _profilDuzenle(context), 
                            icon: const Icon(Icons.edit_rounded, size: 18), 
                            label: const Text("Profili Düzenle", style: TextStyle(fontWeight: FontWeight.bold)), 
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6C63FF), 
                              side: const BorderSide(color: Color(0xFF6C63FF)), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            )
                          ), 
                          const SizedBox(width: 15), 
                          
                          OutlinedButton.icon(
                            onPressed: () { 
                              kullaniciAdi.value = ""; 
                              kullaniciEmail.value = ""; 
                              analizGecmisi.value = []; 
                              Navigator.pushReplacement(
                                context, 
                                MaterialPageRoute(builder: (_) => const AuthScreen())
                              ); 
                            }, 
                            icon: const Icon(Icons.logout_rounded, size: 18), 
                            label: const Text("Çıkış Yap", style: TextStyle(fontWeight: FontWeight.bold)), 
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent, 
                              side: const BorderSide(color: Colors.redAccent), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            )
                          )
                        ]
                      )
                    ],
                  );
                }
              ),
            ),
            const SizedBox(height: 40),
            
            const Text(
              "Haftalık Duygu Grafiği", 
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF2D3142))
            ), 
            const SizedBox(height: 15), 
            
            Container(
              height: 180, 
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), 
                    blurRadius: 24, 
                    offset: const Offset(0, 8)
                  )
                ]
              ), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                  _buildBar(0.4, "Pzt"), 
                  _buildBar(0.7, "Sal"), 
                  _buildBar(0.3, "Çar"), 
                  _buildBar(0.8, "Per", isToday: true), 
                  _buildBar(0.2, "Cum"), 
                  _buildBar(0.5, "Cmt"), 
                  _buildBar(0.6, "Paz")
                ]
              )
            ), 
            const SizedBox(height: 35),
            
            const Text(
              "Asistan Geçmişi", 
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF2D3142))
            ), 
            const SizedBox(height: 15),
            
            ValueListenableBuilder<List<ChatSession>>(
              valueListenable: analizGecmisi,
              builder: (context, liste, child) {
                if (liste.isEmpty) {
                  return Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.all(30), 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: const Color(0xFFE8EAF6))
                    ), 
                    child: const Column(
                      children: [
                        Icon(Icons.history_rounded, size: 50, color: Colors.grey), 
                        SizedBox(height: 10), 
                        Text("Henüz bir analiz yapılmadı.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))
                      ]
                    )
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: liste.length, 
                  itemBuilder: (context, index) { 
                    final session = liste[index]; 
                    final previewText = session.mesajlar.isNotEmpty ? session.mesajlar.first.text : ""; 
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12), 
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20), 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02), 
                            blurRadius: 10, 
                            offset: const Offset(0, 4)
                          )
                        ]
                      ), 
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20), 
                        onTap: () { 
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => ChatScreen(session: session))
                          ); 
                        }, 
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16), 
                          leading: Container(
                            padding: const EdgeInsets.all(12), 
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F9), 
                              borderRadius: BorderRadius.circular(15)
                            ), 
                            child: const Icon(Icons.psychology_rounded, color: Color(0xFF6C63FF))
                          ), 
                          title: Text(
                            session.teshis, 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142), fontSize: 16)
                          ), 
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0), 
                            child: Text(
                              '"$previewText"', 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis, 
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], height: 1.4)
                            )
                          ), 
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                        )
                      )
                    ); 
                  }
                );
              }
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double heightFactor, String day, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end, 
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500), 
          width: 24, 
          height: 100 * heightFactor, 
          decoration: BoxDecoration(
            gradient: isToday 
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)], 
                  begin: Alignment.bottomCenter, 
                  end: Alignment.topCenter
                ) 
              : null, 
            color: isToday ? null : const Color(0xFFF4F6F9), 
            borderRadius: BorderRadius.circular(12)
          )
        ), 
        const SizedBox(height: 10), 
        Text(
          day, 
          style: TextStyle(
            fontSize: 13, 
            color: isToday ? const Color(0xFF6C63FF) : Colors.grey[500], 
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600
          )
        )
      ]
    );
  }
}