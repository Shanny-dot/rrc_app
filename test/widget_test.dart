import 'package:flutter_test/flutter_test.dart';
import 'package:rrc_app/services/version_gate.dart';
import 'package:rrc_app/utils/formatters.dart';

// Unit tests for pure helpers used by the 3.1 screens.
// (The old counter smoke test came from the Flutter template and never matched this app.)
void main() {
  test('version comparison', () {
    expect(VersionGate.compare('3.0.0', '3.1.0') < 0, isTrue);
    expect(VersionGate.compare('3.1.0+43', '3.1.0'), 0);
    expect(VersionGate.compare('3.10.0', '3.9.9') > 0, isTrue);
  });

  test('number and points formatting', () {
    expect(Fmt.number(2050), '2,050');
    expect(Fmt.number(-1500000), '-1,500,000');
    expect(Fmt.signedPts(2000), '+2,000');
    expect(Fmt.signedPts(-50), '-50');
  });

  test('greeting by time of day', () {
    expect(Fmt.greeting(DateTime(2026, 1, 1, 8)), 'Good morning');
    expect(Fmt.greeting(DateTime(2026, 1, 1, 14)), 'Good afternoon');
    expect(Fmt.greeting(DateTime(2026, 1, 1, 20)), 'Good evening');
  });
}
