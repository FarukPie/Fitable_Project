import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:async'; 
import 'dart:convert'; // ✨ İŞTE EKSİK OLAN BU SATIRDI! (JSON Çözücü)

import 'onboarding_screen.dart'; 
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../core/constants.dart';
import '../services/api_service.dart'; 

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final _urlController = TextEditingController();
  final _isimController = TextEditingController();
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _omuzController = TextEditingController();
  final _belController = TextEditingController();

  String _sonucMetni = ""; 
  String _profilFotoUrl = ""; 
  
  final List<String> _avatarListesi = [
    "https://cdn-icons-png.flaticon.com/512/4140/4140048.png", "https://cdn-icons-png.flaticon.com/512/4140/4140037.png", "https://cdn-icons-png.flaticon.com/512/4140/4140047.png", "https://cdn-icons-png.flaticon.com/512/4140/4140051.png", "https://cdn-icons-png.flaticon.com/512/4140/4140076.png", "https://cdn-icons-png.flaticon.com/512/4140/4140061.png", "https://cdn-icons-png.flaticon.com/512/147/147140.png", "https://cdn-icons-png.flaticon.com/512/1999/1999625.png", 
  ];

  bool _yukleniyor = false;
  bool _veriYuklendiMi = false;
  
  int _seciliSayfaIndex = 1; 
  final String uid = FirebaseAuth.instance.currentUser!.uid; 

  @override
  void initState() {
    super.initState();
    _baslangicKontrolu();
  }

  void _mezuraYokAraci(TextEditingController hedefController, String bolgeIsmi) {
    double boy = double.tryParse(_boyController.text) ?? 170;
    double birKarisCm = double.parse((boy * 0.115).toStringAsFixed(1)); 
    double kacKaris = 2.0; 

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            double hesaplananCm = double.parse((kacKaris * birKarisCm).toStringAsFixed(1));
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [const Icon(Icons.handshake, color: AppColors.primary), const SizedBox(width: 10), const Text("Karış Hesabı", style: TextStyle(fontWeight: FontWeight.bold))]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Boyunuza ($boy cm) göre 1 karışınız yaklaşık $birKarisCm cm'dir.", style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text("$bolgeIsmi kaç karış?", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("$kacKaris Karış", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Slider(value: kacKaris, min: 0.5, max: 10.0, divisions: 19, activeColor: AppColors.primary, label: "$kacKaris", onChanged: (val) { setState(() { kacKaris = val; }); }),
                  const Divider(),
                  const Text("Tahmini Ölçü:", style: TextStyle(color: Colors.grey)),
                  Text("$hesaplananCm cm", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İPTAL", style: TextStyle(color: Colors.grey))),
                ElevatedButton(onPressed: () { hedefController.text = hesaplananCm.toStringAsFixed(0); Navigator.pop(ctx); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text("BU DEĞERİ KULLAN")),
              ],
            );
          },
        );
      },
    );
  }

  void _olcuRehberiGoster(String baslik, String aciklama, IconData ikon, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(ikon, color: AppColors.primary), const SizedBox(width: 10), Text(baslik, style: const TextStyle(fontSize: 18))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 80, width: 80, decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(ikon, size: 40, color: Colors.grey)),
            const SizedBox(height: 15),
            Text(aciklama, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _mezuraYokAraci(controller, baslik.split(" ")[0]), icon: const Icon(Icons.handshake_outlined, size: 18), label: const Text("Mezuran yok mu? Elle ölç"), style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary))))
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANLADIM"))],
      ),
    );
  }

  Future<void> _linkiAc(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try { if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw 'Link açılamadı'; } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link açılamadı!"), backgroundColor: Colors.red)); }
  }

  Future<void> _baslangicKontrolu() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ZorunluBilgiEkrani()));
      } else {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['boy'] == null || data['boy'] == "") {
           if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ZorunluBilgiEkrani()));
           return;
        }
        setState(() {
          _isimController.text = data['isim'] ?? 'Kullanıcı';
          _boyController.text = data['boy'] ?? '';
          _kiloController.text = data['kilo'] ?? '';
          _omuzController.text = data['omuz'] ?? '';
          _belController.text = data['bel'] ?? '';
          _profilFotoUrl = data['profil_foto'] ?? ''; 
          _veriYuklendiMi = true;
        });
      }
    } catch (e) { /* Hata */ }
  }

  void _avatarSec() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) { return Container(padding: const EdgeInsets.all(20), height: 400, child: Column(children: [const Text("Bir Avatar Seç", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15), itemCount: _avatarListesi.length, itemBuilder: (context, index) { return GestureDetector(onTap: () { setState(() { _profilFotoUrl = _avatarListesi[index]; }); Navigator.pop(ctx); }, child: CircleAvatar(backgroundColor: Colors.grey.shade200, backgroundImage: NetworkImage(_avatarListesi[index]))); }))])); });
  }

  Future<void> _profiliGuncelle() async {
    setState(() { _yukleniyor = true; });
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'boy': _boyController.text, 'kilo': _kiloController.text,
        'omuz': _omuzController.text, 'bel': _belController.text,
        'profil_foto': _profilFotoUrl, 
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi! ✅"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() { _yukleniyor = false; });
    }
  }

  Future<void> _hesabiSil() async {
    bool? onayla = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Hesabı Sil?"), content: const Text("Bu işlem geri alınamaz. Emin misin?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("EVET, SİL", style: TextStyle(color: Colors.red)))]));
    if (onayla == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await FirebaseAuth.instance.currentUser!.delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: Lütfen çıkış yapıp tekrar girin.")));
      }
    }
  }

  Future<void> _urunuSil(String docId) async {
    bool? onayla = await showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text("Silmek istiyor musun?"), content: const Text("Bu ürünü dolabından kaldırmak üzeresin."), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İPTAL", style: TextStyle(color: Colors.grey))), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SİL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))]));
    if (onayla == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('dolap').doc(docId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ürün silindi 🗑️"), backgroundColor: Colors.orange));
    }
  }

  void _sonucPopupGoster(String analiz, String baslik, String resim, String link) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: resim.isNotEmpty 
                      ? Container(color: Colors.white, height: 300, width: double.infinity, child: Image.network(resim, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.error, color: Colors.red))))
                      : Container(height: 150, width: double.infinity, color: Colors.grey.shade200, child: const Icon(Icons.checkroom, size: 50, color: Colors.grey)),
                  ),
                  Positioned(right: 10, top: 10, child: CircleAvatar(radius: 15, backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.close, size: 15, color: Colors.black), onPressed: () => Navigator.pop(ctx)))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(baslik, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                    const Divider(height: 20),
                    Text(analiz, style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 25),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _linkiAc(link), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.open_in_new), label: const Text("ÜRÜNE GİT"))),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); setState(() { _seciliSayfaIndex = 1; }); }, style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.search), label: const Text("BAŞKA LİNK SORGULA"))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 GÜNCELLENEN ANALİZ FONKSİYONU (JSON ÇÖZÜMÜ İLE)
  Future<void> analizEt() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen link girin"), backgroundColor: Colors.red));
      return;
    }
    
    String linkToSave = _urlController.text;
    setState(() { _yukleniyor = true; }); 

    final sonuc = await ApiService.analizEt(
      url: linkToSave, 
      boy: _boyController.text, 
      kilo: _kiloController.text, 
      omuz: _omuzController.text, 
      bel: _belController.text
    );

    setState(() { _yukleniyor = false; }); 

    if (sonuc.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sonuc["error"]), backgroundColor: Colors.red));
    } else {
      // --- JSON PARSING KISMI (BURASI DÜZELDİ) ---
      try {
        // Backend'den gelen "ai_response" artık bir JSON string. Onu çözmemiz lazım.
        // Eğer backend direkt JSON objesi dönüyorsa buna gerek kalmayabilir ama garanti olsun.
        Map<String, dynamic> aiData;
        
        if (sonuc['ai_response'] is String) {
           // Eğer string geldiyse (örneğin json stringi), onu map'e çevir
           // Bazen stringin başında ```json yazısı olabilir, temizleyelim
           String rawJson = sonuc['ai_response'].replaceAll('```json', '').replaceAll('```', '').trim();
           aiData = jsonDecode(rawJson);
        } else {
           // Zaten map geldiyse direkt al
           aiData = sonuc['ai_response'];
        }
        
        bool isValid = aiData['valid'] ?? false;
        String mesaj = aiData['message'] ?? "Sonuç alınamadı.";
        
        String urunBasligi = sonuc['title'] ?? "Ürün";
        String resimUrl = sonuc['image_url'] ?? "";

        _urlController.clear(); 

        if (isValid == false) {
          // 🚨 HATA POPUP
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 10), Text("Hata")]),
              content: const Text("UYARI: Girdiğiniz link bir kıyafet veya giyim ürününe ait görünmüyor. Lütfen sadece giyim ürünleri sorgulayınız."),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TAMAM", style: TextStyle(color: Colors.black)))],
            )
          );
        } else {
          // ✅ BAŞARILI POPUP
          _sonucPopupGoster(mesaj, urunBasligi, resimUrl, linkToSave);
          
          await FirebaseFirestore.instance.collection('users').doc(uid).collection('dolap').add({
            'link': linkToSave, 'baslik': urunBasligi, 'resim': resimUrl, 'analiz': mesaj, 'tarih': FieldValue.serverTimestamp()
          });
        }

      } catch (e) {
        // Eğer AI saçmalayıp bozuk JSON dönerse
        print("JSON Hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Cevabı anlaşılamadı."), backgroundColor: Colors.orange));
      }
    }
  }

  Widget _buildAnalizEkrani() {
    return Padding(padding: const EdgeInsets.all(20.0), child: SingleChildScrollView(child: Column(children: [
       if (_veriYuklendiMi) ...[
        if (_yukleniyor) 
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
  height: 200,
  child: Lottie.network('https://assets5.lottiefiles.com/packages/lf20_tmsiddoc.json'), 
),
             const SizedBox(height: 20),
             const LoadingMessages(),
          ]))
        else 
          Column(children: [
            const SizedBox(height: 30), const Icon(Icons.checkroom, size: 100, color: AppColors.primary), const SizedBox(height: 20), Text("Link Sorgula", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 20), 
            CustomTextField(controller: _urlController, label: "Ürün Linkini Yapıştır...", icon: Icons.link), const SizedBox(height: 20), 
            CustomButton(text: "BEDENİMİ BUL", onPressed: analizEt, icon: Icons.auto_awesome),
        ]),
      ]
    ])));
  }

  Widget _buildProfilEkrani() {
     return Padding(padding: const EdgeInsets.all(20.0), child: SingleChildScrollView(child: Column(children: [
        const SizedBox(height: 10), Text("Profilim", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 20),
        GestureDetector(onTap: _avatarSec, child: Stack(children: [CircleAvatar(radius: 60, backgroundColor: AppColors.primary, backgroundImage: _profilFotoUrl.isNotEmpty ? NetworkImage(_profilFotoUrl) : null, child: _profilFotoUrl.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.white) : null), Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.edit, color: AppColors.primary, size: 20)))])),
        const SizedBox(height: 15), Text("Merhaba, ${_isimController.text} 👋", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)), const Text("Ölçülerini güncel tut, tarzını yakala!", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 30),
        Row(children: [Expanded(child: CustomTextField(controller: _boyController, label: "Boy", keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: CustomTextField(controller: _kiloController, label: "Kilo", keyboardType: TextInputType.number))]), const SizedBox(height: 15), 
        Row(children: [
          Expanded(child: CustomTextField(controller: _omuzController, label: "Omuz", keyboardType: TextInputType.number, onHelpPressed: () => _olcuRehberiGoster("Omuz Nasıl Ölçülür?", "Dik durun. Mezura ile sırtınızdan, bir omuz kemiği ucundan diğer omuz kemiği ucuna kadar olan mesafeyi ölçün.", Icons.accessibility, _omuzController))), 
          const SizedBox(width: 10), 
          Expanded(child: CustomTextField(controller: _belController, label: "Bel", keyboardType: TextInputType.number, onHelpPressed: () => _olcuRehberiGoster("Bel Nasıl Ölçülür?", "Göbek deliğinizin hizasından, nefesinizi tutmadan ve karnınızı içeri çekmeden bel çevrenizi tam tur ölçün.", Icons.monitor_weight, _belController)))
        ]),
        const SizedBox(height: 20), 
        CustomButton(text: "BİLGİLERİ GÜNCELLE", onPressed: _profiliGuncelle, isLoading: _yukleniyor, icon: Icons.save),
        const SizedBox(height: 40), const Divider(), ListTile(leading: const Icon(Icons.logout, color: Colors.orange), title: const Text("Çıkış Yap", style: TextStyle(color: Colors.orange)), onTap: () => FirebaseAuth.instance.signOut()), ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text("Hesabımı Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: _hesabiSil),
      ])));
  }

  Widget _buildDolapEkrani() {
    return Column(children: [
      const SizedBox(height: 10), Text("Dolabım", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 10),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('dolap').orderBy('tarih', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var veriler = snapshot.data!.docs;
          if (veriler.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Lottie.network('[https://assets9.lottiefiles.com/packages/lf20_47pyyfcf.json](https://assets9.lottiefiles.com/packages/lf20_47pyyfcf.json)', height: 200), const Text("Dolabın henüz boş.")]));
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: veriler.length,
            itemBuilder: (context, index) {
              var urun = veriler[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: urun['resim'] != "" ? Image.network(urun['resim'], width: 60, height: 60, fit: BoxFit.cover) : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image))),
                  title: Text(urun['baslik'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(urun['analiz'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _urunuSil(urun.id)),
                  onTap: () { _sonucPopupGoster(urun['analiz'], urun['baslik'], urun['resim'], urun['link']); },
                ),
              );
            },
          );
        },
      ))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _seciliSayfaIndex == 0 ? _buildDolapEkrani() : (_seciliSayfaIndex == 1 ? _buildAnalizEkrani() : _buildProfilEkrani())),
      bottomNavigationBar: CurvedNavigationBar(backgroundColor: Colors.transparent, color: AppColors.primary, buttonBackgroundColor: AppColors.primary, height: 60, index: _seciliSayfaIndex, items: const <Widget>[Icon(Icons.checkroom, size: 30, color: Colors.white), Icon(Icons.search, size: 30, color: Colors.white), Icon(Icons.person, size: 30, color: Colors.white)], onTap: (index) { setState(() { _seciliSayfaIndex = index; }); }),
    );
  }
}

class LoadingMessages extends StatefulWidget {
  const LoadingMessages({super.key});
  @override
  State<LoadingMessages> createState() => _LoadingMessagesState();
}

class _LoadingMessagesState extends State<LoadingMessages> {
  int _index = 0;
  final List<String> _messages = ["Yorumlar okunuyor... 💬", "Fotoğraflar analiz ediliyor... 📸", "Vücut ölçülerinize bakılıyor... 📏", "Kumaş ve kalıp inceleniyor... 🧵", "Sizin için en uygun beden bulunuyor... 🧥"];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) { if (mounted) setState(() { _index = (_index + 1) % _messages.length; }); });
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(duration: const Duration(milliseconds: 500), transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c), child: Text(_messages[_index], key: ValueKey<int>(_index), style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600, fontStyle: FontStyle.italic), textAlign: TextAlign.center));
  }
}