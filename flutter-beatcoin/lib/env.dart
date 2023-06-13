import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'SERVER_SECRET', obfuscate: true)
  static final String serverSecret = _Env.serverSecret;
}
