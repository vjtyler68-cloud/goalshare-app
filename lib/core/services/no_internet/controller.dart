import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker.createInstance();

  final RxBool isConnected = true.obs;
  final RxBool isCheckingConnection = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _connectionSubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _listenToConnectivityChanges();
    _listenToInternetConnectionChanges();
  }

  Future<void> _initConnectivity() async {
    isCheckingConnection.value = true;
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
    } catch (e) {
      isConnected.value = false;
      log('Error checking connectivity: $e', name: 'Connectivity');
    } finally {
      isCheckingConnection.value = false;
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      await _updateConnectionStatus(results);
    });
  }

  void _listenToInternetConnectionChanges() {
    _connectionSubscription = _connectionChecker.onStatusChange.listen((
      InternetConnectionStatus status,
    ) {
      isConnected.value = status == InternetConnectionStatus.connected;
      _handleConnectionChange();
    });
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // If ANY interface has no connection (or list contains none), it's possibly offline,
    // but usually, if at least one is wifi/mobile, we are good.
    // However, connectivity_plus says: "The list ... represents the connection status of each interface"
    // If the list is just [ConnectivityResult.none], then we are offline.
    // If the list contains mobile or wifi, we should check internet.

    // Simplest check: if list contains none and it's the only one, or if list is empty (rare).
    bool possiblyOffline =
        results.contains(ConnectivityResult.none) && results.length == 1;

    // Also consider if results are just bluetooth or other non-internet types if needed,
    // but usually we care if we have NO connection.

    if (possiblyOffline) {
      isConnected.value = false;
      _handleConnectionChange();
    } else {
      // Double check with actual internet connection
      final hasConnection = await _connectionChecker.hasConnection;
      isConnected.value = hasConnection;
      _handleConnectionChange();
    }
  }

  void _handleConnectionChange() {
    // Intentionally does NOT navigate anywhere. GoalShare is offline-capable:
    // losing signal no longer hijacks the app to a full-screen dead end. The
    // reactive [isConnected] flag drives a slim, non-blocking OfflineBanner
    // (see main.dart / offline_banner.dart) so users keep full access to
    // everything stored on-device, and network-only actions show their own
    // inline error when attempted.
  }

  Future<void> retryConnection() async {
    isCheckingConnection.value = true;
    await Future.delayed(Duration(seconds: 1)); // Small delay for UX

    final hasConnection = await _connectionChecker.hasConnection;
    isConnected.value = hasConnection;

    _handleConnectionChange();

    isCheckingConnection.value = false;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _connectionSubscription?.cancel();
    super.onClose();
  }
}
