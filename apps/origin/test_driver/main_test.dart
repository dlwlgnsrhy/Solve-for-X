import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> _wait(Duration ms) async => Future.delayed(ms);

Future<void> _screen(FlutterDriver d, String name) async {
  final b = await d.screenshot();
  Directory('.screenshots').createSync(recursive: true);
  File('.screenshots/$name.png').writeAsBytesSync(b);
  print('  OK: $name');
}

void main() async {
  final driver = await FlutterDriver.connect();
  try {
    await driver.waitUntilFirstFrameRasterized();
    print('App loaded');

    // 01: Welcome
    print('--- 01_welcome ---');
    await _screen(driver, '01_welcome');
    await driver.tap(find.byValueKey('beginWritingBtn'));
    await _wait(Duration(milliseconds: 500));

    // 02: Keystroke Capture
    print('--- 02_keystroke_capture ---');
    try {
      final tf = find.byValueKey('keystrokeTextField');
      await driver.waitFor(tf, timeout: Duration(seconds: 5));
      await driver.tap(tf);
      await Future.delayed(Duration(milliseconds: 300));
      await driver.enterText('The best thoughts are not premeditated but spontaneous.\n\nEvery keystroke tells a story of the mind at work.');
    } catch (_) {}
    await _screen(driver, '02_keystroke_capture');
    await _wait(Duration(milliseconds: 300));
    await driver.tap(find.byValueKey('completeOnboardingBtn'));
    await _wait(Duration(milliseconds: 1000));

    // 03: Write Tab
    print('--- 03_write_tab ---');
    await driver.waitFor(
      find.byValueKey('completeDocumentBtn'),
      timeout: Duration(seconds: 10),
    );
    try {
      final tf = find.byType('TextField');
      await driver.enterText('Write something here. This is a sample document for testing authenticity features.\n\nAuthenticity measured via unique keystroke patterns.');
    } catch (_) {}
    await _screen(driver, '03_write_tab');
    await driver.tap(find.byValueKey('completeDocumentBtn'));
    await _wait(Duration(milliseconds: 2000));

    // 04: Score Tab
    print('--- 04_score_tab ---');
    try {
      await driver.waitFor(
        find.byValueKey('scoreGauge'),
        timeout: Duration(seconds: 10),
      );
    } catch (_) {}
    await _screen(driver, '04_score_tab');
    await _wait(Duration(milliseconds: 300));

    // 05: Stamps Tab — use Tab text label
    print('--- 05_stamps_tab ---');
    try {
      final stampsTab = find.byTooltip('Stamps');
      await driver.waitFor(stampsTab, timeout: Duration(seconds: 5));
      await driver.tap(stampsTab);
      await _wait(Duration(milliseconds: 1500));
    } catch (_) {
      // Fallback: just take screenshot of current screen (Score)
      print('Note: Could not find Stamps tab');
    }
    try {
      await driver.waitFor(
        find.text('No stamps yet'),
        timeout: Duration(seconds: 5),
      );
    } catch (_) {}
    await _screen(driver, '05_stamps_tab');
    await _wait(Duration(milliseconds: 300));

    // 06: Stamp Overview (Score with data)
    print('--- 06_stamp_overview ---');
    try {
      final scoreTab = find.byTooltip('Score');
      await driver.waitFor(scoreTab, timeout: Duration(seconds: 3));
      await driver.tap(scoreTab);
      await _wait(Duration(milliseconds: 800));
    } catch (_) {}
    await _screen(driver, '06_stamp_overview');

    print('ALL DONE!');
  } catch (e, st) {
    print('ERROR: $e\n$st');
  } finally {
    await driver.close();
  }
}
