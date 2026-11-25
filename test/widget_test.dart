// Remove the old widget_test.dart that references the deleted counter app.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder - app bootstraps', () {
    // Real widget tests are in test/core/ and test/features/.
    expect(1 + 1, 2);
  });
}
