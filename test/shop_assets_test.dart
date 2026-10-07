import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/presentation/rewards/widgets/rewards_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada objeto con render 3D tiene su imagen en assets/shop', () async {
    for (final code in ShopRender.rendered) {
      final data = await rootBundle.load(ShopRender.assetOf(code));
      expect(data.lengthInBytes, greaterThan(1000), reason: code);
    }
  });
}
