import 'dart:convert';

import 'package:fasttrack/appstore/config.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/appstore/connect_api/token.dart';
import 'package:http/http.dart';

// https://github.com/fastlane/fastlane/blob/f075aff8776e3a3eb6f48f7fe84c338778bf62ae/spaceship/docs/AppStoreConnect.md

class AppStoreConnectClient {
  static const _apiUri = 'https://api.appstoreconnect.apple.com/v1/';

  final AppStoreConfig _config;
  final Client _client;

  AppStoreConnectToken? _token;

  AppStoreConnectClient(this._config) : _client = Client();

  Future<AppStoreConnectToken> get __token async {
    return _token ??= await AppStoreConnectToken.fromFile(
      keyId: _config.keyId,
      issuerId: _config.issuerId,
      path: _config.keyFile,
    );
  }

  Future<List<App>> getApps({List<String>? bundleIds}) async {
    final response = await _get(
      'apps',
      filters: {if (bundleIds != null) 'bundleId': bundleIds},
      includes: ['appStoreVersions'],
      fields: {'appStoreVersions': AppStoreVersion.fields},
      limits: {'appStoreVersions': 3},
    );

    final apps = response.asList<App>();

    return (bundleIds != null) //
        ? apps.where((app) => bundleIds.contains(app.bundleId)).toList()
        : apps;
  }

  Future<_Response> _get(
    String path, {
    Map<String, dynamic>? filters,
    List<String>? includes,
    Map<String, dynamic>? fields,
    Map<String, int>? limits,
  }) async {
    final uri = _Uri(_apiUri, path);
    if (filters != null) uri.param('filter', filters);
    if (includes != null) uri.param('include', includes);
    if (fields != null) uri.param('fields', fields);
    if (limits != null) uri.param('limit', limits);

    final token = await __token;
    final response = await _client.get(uri.toUri(), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    });

    return _Response(response);
  }
}

class _Uri {
  final String _uri;
  final Map<String, dynamic> _params = {};

  _Uri(String root, String path) : _uri = root + path;

  void param(String name, dynamic value) {
    if (value is Map) {
      for (final entry in value.entries) {
        param('$name[${entry.key}]', entry.value);
      }
    } else if (value is List) {
      _params[name] = value.map((item) => item.toString()).join(',');
    } else {
      _params[name] = value.toString();
    }
  }

  Uri toUri() {
    return Uri.parse(_uri).replace(queryParameters: _params);
  }
}

class _Response {
  final Response _response;

  _Response(this._response);

  int get status => _response.statusCode;
  Map<String, dynamic> get json => jsonDecode(_response.body);

  List<T> asList<T extends Model>() => Model.parseList<T>(json);
}
