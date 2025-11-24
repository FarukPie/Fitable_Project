import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../core/constants.dart';

class ZorunluBilgiEkrani extends StatefulWidget {
  const ZorunluBilgiEkrani({super.key});
  @override
  State<ZorunluBilgiEkrani> createState() => _ZorunluBilgiEkraniState();
}

class _ZorunluBilgiEkraniState extends State<ZorunluBilgiEkrani> {
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _omuzController = TextEditingController();
  final _belController = TextEditingController();
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { _hosgeldinPopupGoster(); });
  }

  void _hosgeldinPopupGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 35, backgroundColor: AppColors.primary, child: Icon(Icons.auto_awesome, size: 40, color: Colors.white)),
                  const SizedBox(height: 15),
                  Text("Fitable'a Hoş Geldin!", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  const Text("Yapılan yorumlara, beden tablolarına ve görselleri işleyerek size en uygun bedeni verecek yapay zeka destekli Fitable.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  CustomButton(text: "HARİKA, BAŞLAYALIM!", onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Positioned(right: 0, top: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx))),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ MEZURA YOKSA TAHMİN ARACI
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
                  Slider(
                    value: kacKaris,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    activeColor: AppColors.primary,
                    label: "$kacKaris",
                    onChanged: (val) { setState(() { kacKaris = val; }); },
                  ),
                  const Divider(),
                  const Text("Tahmini Ölçü:", style: TextStyle(color: Colors.grey)),
                  Text("$hesaplananCm cm", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İPTAL", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    hedefController.text = hesaplananCm.toStringAsFixed(0);
                    Navigator.pop(ctx); 
                    Navigator.pop(ctx); // Rehber popup'ını da kapat
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text("BU DEĞERİ KULLAN"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 📏 ÖLÇÜ REHBERİ POPUP'I
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _mezuraYokAraci(controller, baslik.split(" ")[0]), 
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text("Mezuran yok mu? Elle ölç"),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
              ),
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANLADIM"))],
      ),
    );
  }

  Future<void> kaydetVeDevamEt() async {
    if (_boyController.text.isEmpty || _kiloController.text.isEmpty || _omuzController.text.isEmpty || _belController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun!"), backgroundColor: Colors.red));
      return;
    }
    setState(() { _yukleniyor = true; });
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'boy': _boyController.text, 'kilo': _kiloController.text,
        'omuz': _omuzController.text, 'bel': _belController.text,
      });
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AnaSayfa()));
    } catch (e) { /* Hata */ } finally { if (mounted) setState(() { _yukleniyor = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text("Vücut Ölçüleri"), automaticallyImplyLeading: false),
        body: Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(children: [
           const Icon(Icons.accessibility_new, size: 60, color: AppColors.primary),
           const SizedBox(height: 20),
           Row(children: [Expanded(child: CustomTextField(controller: _boyController, label: "Boy (cm)", keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: CustomTextField(controller: _kiloController, label: "Kilo (kg)", keyboardType: TextInputType.number))]),
           const SizedBox(height: 10),
           // 👇 GÜNCELLENEN KISIMLAR: onHelpPressed EKLENDİ
           Row(children: [
             Expanded(child: CustomTextField(
               controller: _omuzController, 
               label: "Omuz (cm)", 
               keyboardType: TextInputType.number,
               onHelpPressed: () => _olcuRehberiGoster("Omuz Nasıl Ölçülür?", "Dik durun. Mezura ile sırtınızdan, bir omuz kemiği ucundan diğer omuz kemiği ucuna kadar olan mesafeyi ölçün.", Icons.accessibility, _omuzController),
             )), 
             const SizedBox(width: 10), 
             Expanded(child: CustomTextField(
               controller: _belController, 
               label: "Bel (cm)", 
               keyboardType: TextInputType.number,
               onHelpPressed: () => _olcuRehberiGoster("Bel Nasıl Ölçülür?", "Göbek deliğinizin hizasından, nefesinizi tutmadan ve karnınızı içeri çekmeden bel çevrenizi tam tur ölçün.", Icons.monitor_weight, _belController),
             ))
           ]),
           const SizedBox(height: 20),
           CustomButton(text: "KAYDET VE BAŞLA", onPressed: kaydetVeDevamEt, isLoading: _yukleniyor)
        ]))),
      ),
    );
  }
}