import 'dart:convert';
import 'package:beatcoin/env.dart';
import 'package:beatcoin/services/models.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:get/get.dart';
import 'package:nostr/nostr.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NostrService extends GetxService {
  String _relayUrl = '';
  final _pkKey = 'pk';
  static const eventKindMetadata = 0;
  static const eventKindEncryptedDM = 4;
  static const eventKindBeatzcoinHistory = 33333;
  late FlutterSecureStorage _storage;
  late WebSocket _ws;
  late Keychain _keychain;

  final loggedIn = false.obs;
  final pubKey = ''.obs;
  final profile = NostrProfile.empty().obs;
  final connected = false.obs;
  bool get isProfileReady => loggedIn.value && profile.value.lud16 != '';

  NostrService(FlutterSecureStorage storage, String relayUrl) {
    _storage = storage;
    _relayUrl = relayUrl;
  }

  Future init() async {
    final pk = await _storage.read(key: _pkKey);
    if (pk != null && pk != '') {
      await _setPrivateKey(pk);

      await _connectToRelay();

      Request requestWithFilter = Request(
        generate64RandomHexChars(),
        [
          Filter(
            authors: [
              _keychain.public,
            ],
            kinds: [NostrService.eventKindMetadata],
            since: 1686306208,
            limit: 450,
          ),
          Filter(
            authors: [
              Env.serverPubkey,
            ],
            kinds: [NostrService.eventKindBeatzcoinHistory],
            since: 1686306208,
            limit: 450,
          ),
        ],
      );
      _ws.add(requestWithFilter.serialize());
    }
  }

  void dispose() {
    _ws.close();
    connected.value = false;
  }

  Future setPrivateKey(String privateKey) async {
    await _connectToRelay();
    await _setPrivateKey(privateKey);

    Request requestWithFilter = Request(
      generate64RandomHexChars(),
      [
        Filter(
          authors: [
            _keychain.public,
          ],
          kinds: [NostrService.eventKindMetadata],
          since: 1686306208,
        ),
        Filter(
          authors: [
            Env.serverPubkey,
          ],
          kinds: [NostrService.eventKindBeatzcoinHistory],
          since: 1686306208,
        ),
      ],
    );
    _ws.add(requestWithFilter.serialize());
  }

  Future logout() async {
    pubKey.value = '';
    loggedIn.value = false;
    _ws.close();
    connected.value = false;

    await _storage.delete(key: _pkKey);
  }

  void sendEncryptedDM(String receiverPubkey, String content) async {
    final e = EncryptedDirectMessage.redact(
      _keychain.private,
      receiverPubkey,
      content,
    );
    _ws.add(e.serialize());
  }

  void updateLud16(String lud16) async {
    final e = Event.from(
      kind: 0,
      tags: [],
      content: jsonEncode(
        NostrProfile(
          profile.value.name,
          profile.value.pictureUrl,
          lud16,
        ).toJSON(),
      ),
      privkey: _keychain.private,
    );

    _ws.add(e.serialize());
  }

  Future _connectToRelay() async {
    _ws = await WebSocket.connect(
      _relayUrl,
    );

    connected.value = true;

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
  }

  Future _handleBeatzcoinEvent(Event event) async {
    for (final tag in event.tags) {
      if (tag.contains(_keychain.public)) {
        final eventContent = BeatzcoinEventContent.fromJSON(
          jsonDecode(
            event.content,
          ),
        );

        final rewardService = Get.find<RewardsService>();
        rewardService.setWorkoutHistory(eventContent.workout);

        return;
      }
    }
  }

  Future _setPrivateKey(String privateKey) async {
    String pk = privateKey;
    if (privateKey.startsWith('nsec1')) {
      pk = Nip19.decodePrivkey(privateKey);
    }

    _keychain = Keychain(pk);
    pubKey.value = _keychain.public;

    await _storage.write(key: _pkKey, value: pk);

    profile.value = NostrProfile.empty();
    loggedIn.value = true;
  }
}
