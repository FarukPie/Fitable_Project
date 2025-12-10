import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// Diğer dosyalarımızı çağırıyoruz 👇
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'core/constants.dart';

// --- FIREBASE AYARLARI ---
// Keys are now loaded from .env file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Load .env
    
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['API_KEY'] ?? '',
        appId: dotenv.env['APP_ID'] ?? '',
        messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['PROJECT_ID'] ?? '',
      ),
    );
  } catch (e) {
    print("Firebase/Dotenv hatası: $e");
  }
  runApp(const FitableApp());
}

class FitableApp extends StatelessWidget {
  const FitableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitable',
      theme: ThemeData(
        // ✨ ARTIK RENKLERİ VE YAZI TİPİNİ BURADAN YÖNETİYORUZ
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // Sabit renk dosyasından alıyoruz
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        
        // Ortak AppBar Tasarımı
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        
        // Ortak TextField Tasarımı
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          prefixIconColor: AppColors.primary,
        ),
        
        // Ortak Buton Tasarımı
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      
      // --- TRAFİK POLİSİ ---
      // Kullanıcı giriş yapmışsa Home'a, yapmamışsa Login'e gönder
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const AnaSayfa(); // home_screen.dart'tan geliyor
          }
          return const GirisEkrani(); // login_screen.dart'tan geliyor
        },
      ),
    );
  }
}