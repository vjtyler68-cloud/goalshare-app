import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Online/offline state for the slim OfflineBanner.
///
/// ⚠️ We deliberately do NOT use internet_connection_checker (or any remote
/// host ping) to "verify" internet. That package pings hardcoded DNS IPs
/// (8.8.8.8 / 1.1.1.1 / …) and flips to "disconnected" whenever those are slow
/// or blocked — which cell carriers routinely do — so it falsely screamed
/// "internet connection lost" on a phone with FULL service. Instead we trust the
/// OS-reported network interface: if there's wifi/mobile/ethernet/vpn, we're
/// online. If an actual request later fails, it surfaces its own inline error;
/// the app is offline-capable either way.
class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();

  final RxBool isConnected = true.obs;
  final RxBool isCheckingConnection = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _initConnectivity() async {
    isCheckingConnection.value = true;
    try {
      final results = await _connectivity.checkConnectivity();
      _apply(results);
    } catch (e) {
      // If the check itself throws, ASSUME ONLINE — never falsely block a user
      // who actually has service.
      isConnected.value = true;
      log('Error checking connectivity: $e', name: 'Connectivity');
    } finally {
      isCheckingConnection.value = false;
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_apply);
  }

  /// Online = the OS reports any real network interface.
  void _apply(List<ConnectivityResult> results) {
    isConnected.value = results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> retryConnection() async {
    isCheckingConnection.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      isConnected.value = true;
    }
    isCheckingConnection.value = false;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
