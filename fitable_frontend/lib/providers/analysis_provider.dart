import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'dart:convert';

// --- STATE SINIFI ---
class AnalysisState {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  AnalysisState({this.isLoading = false, this.result, this.error});

  AnalysisState copyWith({bool? isLoading, Map<String, dynamic>? result, String? error}) {
    return AnalysisState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

// --- NOTIFIER SINIFI (Algoritma Burada) ---
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  AnalysisNotifier() : super(AnalysisState());

  Future<void> analizEt({
    required String url,
    required String boy,
    required String kilo,
    required String omuz,
    required String bel,
  }) async {
    // 1. Yükleniyor durumuna geç
    state = state.copyWith(isLoading: true, error: null, result: null);

    try {
      // 2. API İsteği
      final response = await ApiService.analizEt(
        url: url,
        boy: boy,
        kilo: kilo,
        omuz: omuz,
        bel: bel,
      );

      // 3. Hata Kontrolü
      if (response.containsKey("error")) {
        state = state.copyWith(isLoading: false, error: response["error"]);
      } else {
        // 4. JSON Temizleme ve İşleme
        Map<String, dynamic> aiData;
        
        if (response['ai_response'] is String) {
           String rawJson = response['ai_response']
               .replaceAll('```json', '')
               .replaceAll('```', '')
               .trim();
           aiData = jsonDecode(rawJson);
        } else {
           aiData = response['ai_response'];
        }

        // 5. Sonucu tek bir yapıda birleştir
        final finalResult = {
          ...response, // title, image_url vb.
          ...aiData,   // valid, message vb.
        };

        state = state.copyWith(isLoading: false, result: finalResult);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Beklenmedik bir hata: $e");
    }
  }
}

// --- PROVIDER TANIMI ---
final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier();
});
