import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:custom_multi_imagepicker_2/custom_multi_imagepicker_2.dart';

void main() {
  const MethodChannel channel = MethodChannel('custom_multi_imagepicker_2');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await CustomMultiImagepicker2.cameraOrGallery(null), '42');
  });
}
