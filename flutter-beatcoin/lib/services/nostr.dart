import 'dart:convert';
import 'package:beatcoin/env.dart';
import 'package:beatcoin/services/debug.dart';
import 'package:beatcoin/services/models.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:get/get.dart';
import 'package:nostr/nostr.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NostrService extends GetxService {
  static const eventKindMetadata = 0;
  static const eventKindEncryptedDM = 4;
  static const eventKindBeatzcoinHistory = 33333;

  final loggedIn = false.obs;
  final pubKey = ''.obs;
  final profile = NostrProfile.empty().obs;
  final connected = false.obs;
  bool get isProfileReady => loggedIn.value && profile.value.lud16 != '';

  final DebugService _debugService;
  final String _relayUrl;
  final _pkKey = 'pk';
  final FlutterSecureStorage _storage;
  late WebSocket _ws;
  late Keychain _keychain;
  final _currentSubscriptions = <Request>[];

  NostrService(
    this._storage,
    this._relayUrl,
    this._debugService,
  );

  Future init() async {
    final pk = await _storage.read(key: _pkKey);
    if (pk != null && pk != '') {
      await _setPrivateKey(pk);

      await _connectToRelay();

      _subscribeToEventsForPubkey();
    }
  }

  void dispose() {
    _ws.close();
    connected.value = false;
  }

  bool validatePrivateKey(String privateKey) {
    try {
      String pk = privateKey;
      if (privateKey.startsWith('nsec1')) {
        pk = Nip19.decodePrivkey(privateKey);
      }

      _keychain = Keychain(pk);
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<bool> setPrivateKey(String privateKey) async {
    try {
      await _setPrivateKey(privateKey);
    } catch (e) {
      return false;
    }

    await _connectToRelay();

    _closeAndClearSubscriptions();

    _subscribeToEventsForPubkey();

    return true;
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
    _debugService.log(
      '[Nostr] sent kind 4 ${e.serialize()}',
    );
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

  void _subscribeToEventsForPubkey() {
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
    _currentSubscriptions.add(requestWithFilter);
  }

  void _closeAndClearSubscriptions() {
    for (final sub in _currentSubscriptions) {
      final closeSub = Close(sub.subscriptionId);
      _ws.add(closeSub.serialize());
    }
    _currentSubscriptions.clear();
  }

  Future _connectToRelay() async {
    _ws = await WebSocket.connect(
      _relayUrl,
    );
    _debugService.log('[Nostr] connected to relay');

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

    _debugService.log('[Nostr] received kind 0');
  }

  Future _handleBeatzcoinEvent(Event event) async {
    for (final tag in event.tags) {
      if (tag.isNotEmpty &&
          tag.first == "d" &&
          tag.contains(_keychain.public)) {
        final eventContent = BeatzcoinEventContent.fromJSON(
          jsonDecode(
            event.content,
          ),
        );

        final rewardService = Get.find<RewardsService>();
        rewardService.setWorkoutHistory(eventContent.workout);

        if (eventContent.workout.isNotEmpty) {
          _debugService.log(
            '[Nostr] received kind 33333 {satsEarned: ${eventContent.workout.first.satsEarned}, id: ${event.id}}',
          );
        }

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
