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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod Import

import 'onboarding_screen.dart'; 
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../core/constants.dart';
import '../providers/nav_provider.dart'; // Nav Provider
import '../providers/analysis_provider.dart'; // Analysis Provider

// Riverpod için ConsumerStatefulWidget kullanıyoruz
class AnaSayfa extends ConsumerStatefulWidget {
  const AnaSayfa({super.key});
  @override
  ConsumerState<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends ConsumerState<AnaSayfa> {
  final _urlController = TextEditingController();
  final _isimController = TextEditingController();
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _omuzController = TextEditingController();
  final _belController = TextEditingController();

  String _profilFotoUrl = ""; 
  bool _veriYuklendiMi = false;
  final String uid = FirebaseAuth.instance.currentUser!.uid; 
  
  final List<String> _avatarListesi = [
    "https://cdn-icons-png.flaticon.com/512/4140/4140048.png", "https://cdn-icons-png.flaticon.com/512/4140/4140037.png", "https://cdn-icons-png.flaticon.com/512/4140/4140047.png", "https://cdn-icons-png.flaticon.com/512/4140/4140051.png", "https://cdn-icons-png.flaticon.com/512/4140/4140076.png", "https://cdn-icons-png.flaticon.com/512/4140/4140061.png", "https://cdn-icons-png.flaticon.com/512/147/147140.png", "https://cdn-icons-png.flaticon.com/512/1999/1999625.png", 
  ];

  @override
  void initState() {
    super.initState();
    _baslangicKontrolu();
  }

  // Provider'daki değişiklikleri dinleyip aksiyon almak için
  void _listenAnalysisState() {
    ref.listen(analysisProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: Colors.red));
      } else if (next.result != null && (previous?.result != next.result)) {
        // İşlem başarılı ve yeni bir sonuç var
        final data = next.result!;
        bool isValid = data['valid'] ?? false;
        String mesaj = data['message'] ?? "Sonuç alınamadı.";
        String urunBasligi = data['title'] ?? "Ürün";
        String resimUrl = data['image_url'] ?? "";
        String link = _urlController.text;

        _urlController.clear();

        if (isValid == false) {
           showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Row(children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 10), Text("Hata")]), content: const Text("UYARI: Girdiğiniz link bir kıyafet veya giyim ürününe ait görünmüyor."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TAMAM"))]));
        } else {
           _sonucPopupGoster(mesaj, urunBasligi, resimUrl, link);
           // Sonucu kaydet
           FirebaseFirestore.instance.collection('users').doc(uid).collection('dolap').add({
              'link': link, 'baslik': urunBasligi, 'resim': resimUrl, 'analiz': mesaj, 'tarih': FieldValue.serverTimestamp()
           });
        }
      }
    });
  }

  // --- HELPER FONKSİYONLAR (Mezura, Link Açma vb.) ---
  // (Aynı kalacaklar, sadece setState kısımları provider'a gerek duymuyor çünkü lokal UI state)
  void _mezuraYokAraci(TextEditingController hedefController, String bolgeIsmi) {
    double boy = double.tryParse(_boyController.text) ?? 170;
    double birKarisCm = double.parse((boy * 0.115).toStringAsFixed(1)); 
    double kacKaris = 2.0; 

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateLocal) { // setStateLocal ismi karışmasın diye
            double hesaplananCm = double.parse((kacKaris * birKarisCm).toStringAsFixed(1));
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [const Icon(Icons.handshake, color: AppColors.primary), const SizedBox(width: 10), const Text("Karış Hesabı")]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("Boyuna göre 1 karışın: $birKarisCm cm", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Text("$bolgeIsmi: $kacKaris Karış", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Slider(value: kacKaris, min: 0.5, max: 10.0, divisions: 19, activeColor: AppColors.primary, onChanged: (val) { setStateLocal(() { kacKaris = val; }); }),
                  Text("$hesaplananCm cm", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
              actions: [
                ElevatedButton(onPressed: () { hedefController.text = hesaplananCm.toStringAsFixed(0); Navigator.pop(ctx); }, child: const Text("KULLAN")),
              ],
            );
          },
        );
      },
    );
  }

  void _olcuRehberiGoster(String baslik, String aciklama, IconData ikon, TextEditingController controller) {
      showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Row(children: [Icon(ikon, color: AppColors.primary), const SizedBox(width: 10), Text(baslik)]), content: Column(mainAxisSize: MainAxisSize.min, children: [Text(aciklama), const SizedBox(height: 10), OutlinedButton(onPressed: () => _mezuraYokAraci(controller, baslik.split(" ")[0]), child: const Text("Mezuran yok mu?"))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TAMAM"))]));
  }

  Future<void> _linkiAc(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try { if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw 'Link açılamadı'; } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link açılamadı!"), backgroundColor: Colors.red)); }
  }

  // --- FIREBASE VERİ ÇEKME ---
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
        setState(() { // Burası lokal state kalabilir çünkü text controller'ları güncelliyor
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

  Future<void> _profiliGuncelle() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'boy': _boyController.text, 'kilo': _kiloController.text,
        'omuz': _omuzController.text, 'bel': _belController.text,
        'profil_foto': _profilFotoUrl, 
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi! ✅"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  void _sonucPopupGoster(String analiz, String baslik, String resim, String link) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: resim.isNotEmpty ? Image.network(resim, height: 250, width: double.infinity, fit: BoxFit.contain) : Container(height: 150, color: Colors.grey.shade200, child: const Icon(Icons.checkroom, size: 50))),
              Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                    Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                    const Divider(),
                    Text(analiz),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(onPressed: () => _linkiAc(link), icon: const Icon(Icons.open_in_new), label: const Text("ÜRÜNE GİT"), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: () { 
                      Navigator.pop(ctx); 
                      ref.read(navProvider.notifier).state = 1; // Başka link sorgulaya dön
                    }, child: const Text("KAPAT"))
                  ]))
          ]),
        ),
      ),
    );
  }

  // --- ANALİZ BUTONU ---
  void _analiziBaslat() {
     if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen link girin"), backgroundColor: Colors.red));
      return;
    }
    // Riverpod ile analiz başlat
    ref.read(analysisProvider.notifier).analizEt(
      url: _urlController.text,
      boy: _boyController.text,
      kilo: _kiloController.text,
      omuz: _omuzController.text,
      bel: _belController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    _listenAnalysisState(); // Listener'ı build içinde çağırmak yerine initState'e de alabilirdik ama build içinde ref.listen güvenlidir.
    
    // Riverpod'dan değerleri oku
    final seciliSayfaIndex = ref.watch(navProvider);
    final analysisState = ref.watch(analysisProvider);

    return Scaffold(
      body: SafeArea(
        child: seciliSayfaIndex == 0 ? _buildDolapEkrani() : (seciliSayfaIndex == 1 ? _buildAnalizEkrani(analysisState.isLoading) : _buildProfilEkrani()),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent, 
        color: AppColors.primary, 
        buttonBackgroundColor: AppColors.primary, 
        height: 60, 
        index: seciliSayfaIndex, // Provider'dan geliyor
        items: const <Widget>[Icon(Icons.checkroom, size: 30, color: Colors.white), Icon(Icons.search, size: 30, color: Colors.white), Icon(Icons.person, size: 30, color: Colors.white)], 
        onTap: (index) { 
           // Provider'ı güncelle
           ref.read(navProvider.notifier).state = index; 
        }
      ),
    );
  }

  // --- EKRAN WIDGETLARI ---
  Widget _buildAnalizEkrani(bool isLoading) {
    return Padding(padding: const EdgeInsets.all(20.0), child: SingleChildScrollView(child: Column(children: [
       if (_veriYuklendiMi) ...[
        if (isLoading) 
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(height: 200, child: Lottie.network('https://assets5.lottiefiles.com/packages/lf20_tmsiddoc.json')), 
             const SizedBox(height: 20),
             const LoadingMessages(),
          ]))
        else 
          Column(children: [
            const SizedBox(height: 30), const Icon(Icons.checkroom, size: 100, color: AppColors.primary), const SizedBox(height: 20), Text("Link Sorgula", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 20), 
            CustomTextField(controller: _urlController, label: "Ürün Linkini Yapıştır...", icon: Icons.link), const SizedBox(height: 20), 
            CustomButton(text: "BEDENİMİ BUL", onPressed: _analiziBaslat, icon: Icons.auto_awesome),
        ]),
      ]
    ])));
  }

  Widget _buildProfilEkrani() {
     // (Buradaki kodun geri kalanı büyük oranda aynı, sadece setState'ler local UI için, o yüzden özetliyorum)
     return Padding(padding: const EdgeInsets.all(20.0), child: SingleChildScrollView(child: Column(children: [
        const SizedBox(height: 10), Text("Profilim", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 20),
        GestureDetector(onTap: () { 
            // Basit avatar seçimi (bunu da provider'a alabilirdik ama şimdilik lokal kalsın)
             showModalBottomSheet(context: context, builder: (ctx) { return Container(height: 400, child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4), itemCount: _avatarListesi.length, itemBuilder: (c, i) => InkWell(onTap: () { setState(() {_profilFotoUrl = _avatarListesi[i];}); Navigator.pop(ctx); }, child: Image.network(_avatarListesi[i]))));});
        }, child: CircleAvatar(radius: 60, backgroundImage: _profilFotoUrl.isNotEmpty ? NetworkImage(_profilFotoUrl) : null, child: _profilFotoUrl.isEmpty ? const Icon(Icons.person) : null)),
        const SizedBox(height: 30),
        Row(children: [Expanded(child: CustomTextField(controller: _boyController, label: "Boy")), const SizedBox(width: 10), Expanded(child: CustomTextField(controller: _kiloController, label: "Kilo"))]),
        const SizedBox(height: 15),
        Row(children: [Expanded(child: CustomTextField(controller: _omuzController, label: "Omuz")), const SizedBox(width: 10), Expanded(child: CustomTextField(controller: _belController, label: "Bel"))]),
        const SizedBox(height: 20),
        CustomButton(text: "GÜNCELLE", onPressed: _profiliGuncelle, icon: Icons.save),
        const SizedBox(height: 40), ListTile(title: const Text("Çıkış"), leading: const Icon(Icons.logout), onTap: () => FirebaseAuth.instance.signOut())
      ])));
  }

  Widget _buildDolapEkrani() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('dolap').orderBy('tarih', descending: true).snapshots(),
      builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var veriler = snapshot.data!.docs;
          if (veriler.isEmpty) return const Center(child: Text("Dolabın boş."));
          return ListView.builder(
            itemCount: veriler.length,
            itemBuilder: (context, index) {
              var urun = veriler[index];
              return ListTile(
                leading: Image.network(urun['resim'], width: 50, errorBuilder: (c,e,s)=>const Icon(Icons.image)),
                title: Text(urun['baslik']),
                subtitle: Text(urun['analiz'], maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('users').doc(uid).collection('dolap').doc(urun.id).delete()),
                onTap: () => _sonucPopupGoster(urun['analiz'], urun['baslik'], urun['resim'], urun['link']),
              );
            },
          );
      }
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
  final List<String> _messages = ["Yorumlar okunuyor... 💬", "Fotoğraflar analiz ediliyor... 📸", "Vücut ölçülerine bakılıyor... 📏", "Kumaş inceleniyor... 🧵", "En uygun beden bulunuyor... 🧥"];
  late Timer _timer;
  @override
  void initState() { super.initState(); _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) { if (mounted) setState(() { _index = (_index + 1) % _messages.length; }); }); }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return Text(_messages[_index], style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic)); }
}
