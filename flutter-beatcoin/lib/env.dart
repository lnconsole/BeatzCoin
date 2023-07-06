import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'SERVER_SECRET', obfuscate: true)
  static final String serverSecret = _Env.serverSecret;

  @EnviedField(varName: 'SERVER_PUBKEY')
  static const String serverPubkey = _Env.serverPubkey;
}
