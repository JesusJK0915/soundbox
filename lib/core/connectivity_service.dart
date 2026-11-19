import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await _refresh();
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final results = await _connectivity.checkConnectivity();
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);

    var reachable = false;
    if (hasNetwork) {
      try {
        final response = await _dio.get<String>(
          'https://archive.org/robots.txt',
          options: Options(responseType: ResponseType.plain),
        );
        reachable = response.statusCode == 200;
      } catch (_) {
        reachable = false;
      }
    }

    if (reachable != _isOnline) {
      _isOnline = reachable;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
