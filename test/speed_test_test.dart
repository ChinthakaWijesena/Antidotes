import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/speed_test/data/models/speed_test_result.dart';
import 'package:antidotes/features/speed_test/data/services/speed_test_service.dart';
import 'package:antidotes/features/speed_test/presentation/controllers/speed_test_controller.dart';

class MockSpeedTestService extends SpeedTestService {
  @override
  Future<NetworkMetaInfo> fetchNetworkMeta() async {
    return const NetworkMetaInfo(
      ip: '112.134.138.153',
      isp: 'Sri Lanka Telecom',
      city: 'Colombo',
      country: 'Sri Lanka',
      countryCode: 'LK',
    );
  }

  @override
  Future<({int ping, int jitter})> measurePing({String target = '1.1.1.1'}) async {
    return (ping: 14, jitter: 2);
  }

  @override
  Future<double> measureDownload({
    required void Function(double currentMbps, double progress, int remainingSeconds)
        onProgress,
    int durationSeconds = 25,
    int parallelStreams = 4,
  }) async {
    onProgress(50.0, 0.5, 12);
    onProgress(100.0, 1.0, 0);
    return 100.0;
  }

  @override
  Future<double> measureUpload({
    required void Function(double currentMbps, double progress, int remainingSeconds)
        onProgress,
    int durationSeconds = 25,
    int parallelStreams = 4,
  }) async {
    onProgress(25.0, 0.5, 12);
    onProgress(50.0, 1.0, 0);
    return 50.0;
  }
}

void main() {
  group('SpeedTest Models Tests', () {
    test('NetworkMetaInfo parses from JSON correctly', () {
      final json = {
        'query': '112.134.138.153',
        'isp': 'Sri Lanka Telecom',
        'city': 'Colombo',
        'country': 'Sri Lanka',
        'countryCode': 'LK',
      };

      final meta = NetworkMetaInfo.fromJson(json);
      expect(meta.ip, '112.134.138.153');
      expect(meta.isp, 'Sri Lanka Telecom');
      expect(meta.city, 'Colombo');
      expect(meta.country, 'Sri Lanka');
      expect(meta.countryCode, 'LK');
    });

    test('SpeedTestResult evaluates accurate connection qualities', () {
      final highSpeedResult = SpeedTestResult(
        downloadMbps: 120.0,
        uploadMbps: 45.0,
        pingMs: 12,
        jitterMs: 2,
        timestamp: DateTime.now(),
      );

      expect(highSpeedResult.gamingQuality, 'Ultra Low Latency (Pro)');
      expect(highSpeedResult.streamingQuality, '4K Ultra HD (Seamless)');
      expect(highSpeedResult.callQuality, 'Studio HD Video Calls');

      final slowResult = SpeedTestResult(
        downloadMbps: 4.0,
        uploadMbps: 1.0,
        pingMs: 120,
        jitterMs: 30,
        timestamp: DateTime.now(),
      );

      expect(slowResult.gamingQuality, 'High Latency / Ping Spikes');
      expect(slowResult.streamingQuality, 'Standard Definition (480p)');
      expect(slowResult.callQuality, 'Audio Calls Recommended');
    });
  });

  group('SpeedTestController Tests', () {
    test('Controller initializes with meta and runs test to completion', () async {
      final mockService = MockSpeedTestService();
      final controller = SpeedTestController(service: mockService);

      expect(controller.phase, SpeedTestPhase.idle);
      expect(controller.isTesting, isFalse);

      await controller.init();
      expect(controller.meta.isp, 'Sri Lanka Telecom');
      expect(controller.meta.ip, '112.134.138.153');

      // Run end-to-end test
      await controller.startTest();

      expect(controller.phase, SpeedTestPhase.completed);
      expect(controller.isTesting, isFalse);
      expect(controller.lastResult, isNotNull);
      expect(controller.lastResult!.downloadMbps, 100.0);
      expect(controller.lastResult!.uploadMbps, 50.0);
      expect(controller.lastResult!.pingMs, 14);
      expect(controller.lastResult!.jitterMs, 2);
      expect(controller.sessionHistory.length, 1);
    });

    test('Controller can cancel test cleanly', () async {
      final controller = SpeedTestController(service: MockSpeedTestService());
      controller.cancelTest();
      expect(controller.phase, SpeedTestPhase.idle);
      expect(controller.liveSpeed, 0.0);
    });
  });
}
