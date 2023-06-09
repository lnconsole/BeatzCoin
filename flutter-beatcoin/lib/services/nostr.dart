import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';

class NostrService extends GetxService {
  final _pkKey = 'pk';
  late SharedPreferences _prefs;
  RxBool loggedIn = false.obs;
  RxString pubKey = ''.obs;

  NostrService(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future init() async {
    final pk = _prefs.getString(_pkKey);
    if (pk != null && pk != '') {
      await _setPrivateKey(pk);
    }
  }

  Future<bool> setPrivateKey(String privateKey) async {
    return await _setPrivateKey(privateKey);
  }

  Future<bool> logout() async {
    pubKey.value = '';
    loggedIn.value = false;

    return await _prefs.remove(_pkKey);
  }

  Future<bool> _setPrivateKey(String privateKey) async {
    String pk = privateKey;
    if (privateKey.startsWith('nsec1')) {
      pk = Nip19.decodePrivkey(privateKey);
    }

    final kc = Keychain(pk);
    pubKey.value = kc.public;
    loggedIn.value = true;

    return await _prefs.setString(_pkKey, pk);
  }
}
