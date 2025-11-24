import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart'; 
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../core/constants.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  
  DateTime? _dogumTarihi;
  String? _secilenCinsiyet; 
  
  // ✨ DEĞİŞİKLİK BURADA: 'true' yaptık ki varsayılan GİRİŞ YAP olsun
  bool _isLogin = true; 
  
  bool _sifreGizli = true;
  String _errorMessage = "";
  bool _yukleniyor = false;

  String? _sifreKontrol(String sifre) {
    if (sifre.length < 8 || sifre.length > 16) return "Şifre 8-16 karakter arasında olmalı.";
    if (!sifre.contains(RegExp(r'[A-Z]'))) return "En az 1 büyük harf içermeli.";
    if (!sifre.contains(RegExp(r'[0-9]'))) return "En az 1 rakam içermeli.";
    return null;
  }

  Future<void> _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!);
      },
    );
    if (secilen != null) setState(() { _dogumTarihi = secilen; });
  }

  Future<void> islemYap() async {
    setState(() { _errorMessage = ""; });

    if (_isLogin) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() { _errorMessage = "Lütfen alanları doldurun."; });
        return;
      }
      setState(() { _yukleniyor = true; });
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        setState(() { 
          if(e.code == 'user-not-found') _errorMessage = "Kullanıcı bulunamadı.";
          else if(e.code == 'wrong-password') _errorMessage = "Şifre hatalı.";
          else _errorMessage = e.message ?? "Giriş hatası.";
          _yukleniyor = false;
        });
      }
    } else {
      if (_adController.text.isEmpty || _soyadController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _dogumTarihi == null || _secilenCinsiyet == null) {
        setState(() { _errorMessage = "Lütfen tüm alanları doldurun."; });
        return;
      }

      String? sifreHata = _sifreKontrol(_passwordController.text);
      if (sifreHata != null) { setState(() { _errorMessage = sifreHata; }); return; }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() { _errorMessage = "Şifreler eşleşmiyor!"; });
        return;
      }

      setState(() { _yukleniyor = true; });

      try {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = cred.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'isim': "${_adController.text.trim()} ${_soyadController.text.trim()}",
          'ad': _adController.text.trim(),
          'soyad': _soyadController.text.trim(),
          'email': _emailController.text.trim(),
          'dogum_tarihi': Timestamp.fromDate(_dogumTarihi!),
          'cinsiyet': _secilenCinsiyet,
          'profil_foto': '', 
          'kayit_tarihi': FieldValue.serverTimestamp(),
          'boy': '', 'kilo': '', 'omuz': '', 'bel': '', 
        });

      } on FirebaseAuthException catch (e) {
        setState(() { 
          if(e.code == 'email-already-in-use') _errorMessage = "Bu e-posta zaten kayıtlı.";
          else _errorMessage = e.message ?? "Kayıt hatası.";
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.checkroom, size: 100, color: AppColors.primary),
                const SizedBox(height: 10),
                Text(AppText.appName, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 30),

                // TAB BUTTONS
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25)),
                  child: Row(
                    children: [
                      Expanded(child: GestureDetector(onTap: () => setState(() { _isLogin = true; _errorMessage=""; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _isLogin ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(25)), child: Text("Giriş Yap", textAlign: TextAlign.center, style: TextStyle(color: _isLogin ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))))),
                      Expanded(child: GestureDetector(onTap: () => setState(() { _isLogin = false; _errorMessage=""; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !_isLogin ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(25)), child: Text("Kayıt Ol", textAlign: TextAlign.center, style: TextStyle(color: !_isLogin ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))))),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                if (!_isLogin) ...[
                  Row(children: [
                    Expanded(child: CustomTextField(controller: _adController, label: "Ad", icon: Icons.person_outline)),
                    const SizedBox(width: 10),
                    Expanded(child: CustomTextField(controller: _soyadController, label: "Soyad")),
                  ]),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: InkWell(onTap: _tarihSec, child: InputDecorator(decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide.none), filled: true, fillColor: Color(0xFFF5F5F5)), child: Text(_dogumTarihi == null ? "Doğum Tarihi" : DateFormat('dd/MM/yyyy').format(_dogumTarihi!), style: TextStyle(color: _dogumTarihi == null ? Colors.grey[600] : Colors.black))))),
                    const SizedBox(width: 10),
                    Expanded(child: DropdownButtonFormField<String>(value: _secilenCinsiyet, items: ["Erkek", "Kadın"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _secilenCinsiyet = val), decoration: const InputDecoration(hintText: "Cinsiyet", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)))),
                  ]),
                  const SizedBox(height: 15),
                ],

                CustomTextField(controller: _emailController, label: "E-posta", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 15),
                CustomTextField(
                  controller: _passwordController, 
                  label: "Şifre", 
                  icon: Icons.lock_outline, 
                  isPassword: true, 
                  isObscure: _sifreGizli, 
                  onEyePressed: () => setState(() => _sifreGizli = !_sifreGizli)
                ),
                
                if (!_isLogin) ...[
                  const SizedBox(height: 15),
                  CustomTextField(controller: _confirmPasswordController, label: "Şifreyi Tekrarla", icon: Icons.lock_reset, isPassword: true, isObscure: true),
                  const SizedBox(height: 10),
                  const Text("⚠️ Şifre: 8-16 karakter, 1 büyük harf, 1 sayı.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],

                if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 15), Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))],
                
                const SizedBox(height: 25),
                
                CustomButton(
                  text: _isLogin ? "GİRİŞ YAP" : "KAYIT OL", 
                  onPressed: islemYap, 
                  isLoading: _yukleniyor
                ),

                const SizedBox(height: 30),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("veya", style: TextStyle(color: Colors.grey))), Expanded(child: Divider())]),
                const SizedBox(height: 20),

                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google servisi yakında aktif olacak! 🛠️"))); }, icon: Image.network('https://cdn-icons-png.flaticon.com/512/2991/2991148.png', height: 24), label: const Text("Google ile Devam Et", style: TextStyle(color: Colors.black)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}