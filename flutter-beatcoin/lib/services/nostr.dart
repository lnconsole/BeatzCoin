import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'dart:io';

class NostrService extends GetxService {
  String _relayUrl = '';
  late SharedPreferences _prefs;
  late WebSocket _ws;
  final _pkKey = 'pk';
  late Keychain _keychain;
  final loggedIn = false.obs;
  final pubKey = ''.obs;
  final profile = NostrProfile.empty().obs;

  NostrService(SharedPreferences prefs, String relayUrl) {
    _prefs = prefs;
    _relayUrl = relayUrl;
  }

  Future init() async {
    final pk = _prefs.getString(_pkKey);
    if (pk != null && pk != '') {
      await _setPrivateKey(pk);
      await _connectToRelay();
    }
  }

  void dispose() {
    _ws.close();
  }

  Future<bool> setPrivateKey(String privateKey) async {
    return await _setPrivateKey(privateKey);
  }

  Future<bool> logout() async {
    pubKey.value = '';
    loggedIn.value = false;

    return await _prefs.remove(_pkKey);
  }

  void sendEncryptedDM(String content) async {
    final e = EncryptedDirectMessage.redact(
      _keychain.private,
      _keychain.public,
      content,
    );
    _ws.add(e.serialize());
    print(e);
  }

  Future _connectToRelay() async {
    _ws = await WebSocket.connect(
      _relayUrl,
    );

    Request requestWithFilter = Request(
      generate64RandomHexChars(),
      [
        Filter(
          authors: [
            _keychain.public,
          ],
          kinds: [0, 4],
          since: 1686306208,
          limit: 450,
        )
      ],
    );

    _ws.add(requestWithFilter.serialize());

    _ws.listen((event) {
      final e = Message.deserialize(event);
      switch (e.type) {
        case "EVENT":
          _handleEvent(e.message);
          break;
        default:
          print(event);
      }
    });
  }

  Future _handleEvent(Event event) async {
    switch (event.kind) {
      case 0:
        await _handleMetadataMessage(event);
        break;
      case 4:
        _handleEncryptedDM(event);
      default:
    }
  }

  Future _handleMetadataMessage(Event event) async {
    final p = jsonDecode(event.content);

    profile.update((pInstance) {
      pInstance?.name = p['display_name'];
      pInstance?.pictureUrl = p['picture'];
    });
  }

  Future _handleEncryptedDM(Event event) async {
    final dm = EncryptedDirectMessage.receive(event);
    print(dm.getPlaintext(_keychain.private));
  }

  Future<bool> _setPrivateKey(String privateKey) async {
    String pk = privateKey;
    if (privateKey.startsWith('nsec1')) {
      pk = Nip19.decodePrivkey(privateKey);
    }

    _keychain = Keychain(pk);
    pubKey.value = _keychain.public;
    loggedIn.value = true;

    return await _prefs.setString(_pkKey, pk);
  }
}

class NostrProfile {
  String name;
  String pictureUrl;

  NostrProfile(
    this.name,
    this.pictureUrl,
  );

  factory NostrProfile.empty() {
    return NostrProfile("", "");
  }
}
