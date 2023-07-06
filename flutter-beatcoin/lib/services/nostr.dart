import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'dart:io';

class NostrService extends GetxService {
  String _relayUrl = '';
  final _pkKey = 'pk';
  static const eventKindMetadata = 0;
  static const eventKindEncryptedDM = 4;
  static const eventKindBeatzcoinHistory = 33333;
  final _interestingEvents = [
    eventKindMetadata,
    eventKindEncryptedDM,
    eventKindBeatzcoinHistory,
  ];
  late SharedPreferences _prefs;
  late WebSocket _ws;
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

  void sendEncryptedDM(String receiverPubkey, String content) async {
    final e = EncryptedDirectMessage.redact(
      _keychain.private,
      receiverPubkey,
      content,
    );
    _ws.add(e.serialize());
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
          kinds: _interestingEvents,
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
      }
    });
  }

  Future _handleEvent(Event event) async {
    switch (event.kind) {
      case NostrService.eventKindMetadata:
        await _handleMetadataMessage(event);
        break;
      case NostrService.eventKindEncryptedDM:
        _handleEncryptedDM(event);
        break;
      case NostrService.eventKindBeatzcoinHistory:
        _handleBeatzcoinEvent(event);
        break;
      default:
    }
  }

  Future _handleMetadataMessage(Event event) async {
    final p = jsonDecode(event.content);

    profile.update((pInstance) {
      pInstance?.name = p['display_name'];
      pInstance?.pictureUrl = p['picture'];
      pInstance?.lud16 = p['lud16'] ?? '';
    });
  }

  Future _handleEncryptedDM(Event event) async {
    final dm = EncryptedDirectMessage.receive(event);
    print('received encrypted dm');
  }

  Future _handleBeatzcoinEvent(Event event) async {}

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
  String lud16;

  NostrProfile(
    this.name,
    this.pictureUrl,
    this.lud16,
  );

  factory NostrProfile.empty() {
    return NostrProfile("", "", "");
  }
}

class WorkoutDetails {
  DateTime date;
  int satsEarned;

  WorkoutDetails(this.date, this.satsEarned);

  factory WorkoutDetails.fromJSON(Map<String, dynamic> json) {
    var satsEarned = int.tryParse(json['sats_earned']);
    satsEarned ??= 0;
    var date = DateTime.tryParse(json['date']);
    date ??= DateTime.now();

    return WorkoutDetails(date, satsEarned);
  }
}

class BeatzcoinEventContent {
  List<WorkoutDetails> workout;

  BeatzcoinEventContent(this.workout);

  factory BeatzcoinEventContent.fromJSON(Map<String, dynamic> json) {
    var w = json['workout'] as List<Map<String, dynamic>>;

    return BeatzcoinEventContent(
      w.map((e) => WorkoutDetails.fromJSON(e)).toList(),
    );
  }
}
