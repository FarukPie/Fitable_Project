import 'package:flutter_riverpod/flutter_riverpod.dart';

// Basit bir StateProvider ile sayfa indeksini tutuyoruz
final navProvider = StateProvider<int>((ref) => 1); // Varsayılan: 1 (Analiz Ekranı)
