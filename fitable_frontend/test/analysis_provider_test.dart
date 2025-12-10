import 'package:flutter_test/flutter_test.dart';
import 'package:fitable_frontend/providers/analysis_provider.dart';

void main() {
  group('AnalysisNotifier', () {
    test('initial state should be empty', () {
      final notifier = AnalysisNotifier();
      expect(notifier.state.isLoading, false);
      expect(notifier.state.result, null);
      expect(notifier.state.error, null);
    });
  });
}
