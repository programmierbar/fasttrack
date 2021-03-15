import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AppStoreConnectToken {
  static Future<AppStoreConnectToken> fromFile({
    required String keyId,
    required String issuerId,
    required String path,
  }) async {
    final key = await File(path).readAsString();
    return AppStoreConnectToken(keyId: keyId, issuerId: issuerId, key: key);
  }

  final String keyId;
  final String issuerId;
  final String key;
  final Duration duration;

  DateTime? _expiration;
  String? _value;

  AppStoreConnectToken({
    required this.keyId,
    required this.issuerId,
    required this.key,
    this.duration = const Duration(seconds: 1200),
  }) {
    refresh();
  }

  bool get expired => _expiration!.isBefore(DateTime.now());
  String get value {
    if (expired) refresh();
    return _value!;
  }

  void refresh() {
    _expiration = DateTime.now().add(duration);
    final token = JsonWebToken({
      'iss': issuerId,
      'exp': secondsSinceEpoch(_expiration!),
      'aud': 'appstoreconnect-v1',
    }, headers: {
      'kid': keyId
    });

    _value = token.sign(ECPrivateKey(key), algorithm: JWTAlgorithm.ES256);
  }
}

final jsonBase64 = json.fuse(utf8.fuse(base64Url));

String base64Unpadded(String value) {
  if (value.endsWith('==')) return value.substring(0, value.length - 2);
  if (value.endsWith('=')) return value.substring(0, value.length - 1);
  return value;
}

int secondsSinceEpoch(DateTime time) {
  return time.millisecondsSinceEpoch ~/ 1000;
}

class JsonWebToken extends JWT {
  Map<String, String>? headers;

  JsonWebToken(Map<String, dynamic> payload, {this.headers}) : super(payload);

  String sign(
    Key key, {
    JWTAlgorithm algorithm = JWTAlgorithm.HS256,
    Duration? expiresIn,
    Duration? notBefore,
    bool noIssueAt = false,
  }) {
    final headers = {'alg': algorithm.name, 'typ': 'JWT'};
    if (this.headers != null) {
      headers.addAll(this.headers!);
    }

    if (payload is Map<String, dynamic>) {
      payload = Map<String, dynamic>.from(payload);
    }

    final encodedHeaders = base64Unpadded(jsonBase64.encode(headers));
    final encodedPayload = base64Unpadded(jsonBase64.encode(payload));

    final body = '$encodedHeaders.$encodedPayload';
    final signature = base64Unpadded(base64Url.encode(algorithm.sign(key, Uint8List.fromList(utf8.encode(body)))));

    return body + '.' + signature;
  }
}
