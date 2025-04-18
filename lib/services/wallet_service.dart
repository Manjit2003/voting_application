import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService extends ChangeNotifier {
  static const _connectorKey = 'walletconnect';
  late final WalletConnect connector;
  bool get isConnected => connector.connected;
  String get address => connector.session.accounts[0];

  WalletService() {
    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'Voting App',
        description: 'A decentralized voting application',
        url: 'https://your-website.com',
        icons: ['https://your-website.com/icon.png'],
      ),
    );

    connector.on('connect', (session) => notifyListeners());
    connector.on('session_update', (payload) => notifyListeners());
    connector.on('disconnect', (payload) => notifyListeners());
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString(_connectorKey);

    if (session != null) {
      connector.reconnect();
    }
  }

  Future<bool> connect() async {
    if (!connector.connected) {
      try {
        final session = await connector.createSession(
          chainId: 80001, // Mumbai testnet
          onDisplayUri: (uri) async {
            await _launchUrl(uri);
          },
        );

        if (session != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_connectorKey, session.toString());
          return true;
        }
        return false;
      } catch (e) {
        print('Error connecting: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> disconnect() async {
    if (connector.connected) {
      await connector.killSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_connectorKey);
    }
  }

  Future<void> _launchUrl(String uri) async {
    final url = Uri.parse(uri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $uri';
    }
  }
}
