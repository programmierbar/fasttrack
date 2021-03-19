import 'dart:convert';

import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/appstore/connect_api/token.dart';
import 'package:http/http.dart';

class AppStoreConnectApi {
  final AppStoreConnectClient _client;
  final String _appId;

  AppStoreConnectApi(this._client, this._appId);

  Future<List<AppStoreVersion>> getVersions({
    List<String>? versions,
    List<AppStoreState>? states,
  }) async {
    final request = _Request('apps/$_appId/appStoreVersions') //
      ..include('appStoreVersionPhasedRelease')
      ..include('build');

    if (versions != null) {
      request.filter('versionString', versions);
    }
    if (states != null) {
      request.filter('appStoreState', states);
    }

    final response = await _client._get(request);
    return response.asList<AppStoreVersion>();
  }
}

class AppStoreConnectClient {
  final AppStoreConnectTokenConfig _config;
  final Client _client = Client();

  AppStoreConnectToken? _token;

  AppStoreConnectClient(this._config);

  Future<_Response> _get(_Request request) async {
    final uri = request.toUri();
    final token = await _getToken();
    final response = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    });
    //print('Received response ${response.body}');

    return _Response(response);
  }

  Future<AppStoreConnectToken> _getToken() async {
    return _token ??= await AppStoreConnectToken.fromFile(
      keyId: _config.keyId,
      issuerId: _config.issuerId,
      path: _config.keyFile,
    );
  }
}

class _Request {
  static const _apiUri = 'https://api.appstoreconnect.apple.com/v1/';

  final String _path;
  final Map<String, dynamic> _filters = {};
  final Set<String> _includes = {};
  final Map<String, String> _fields = {};
  final Map<String, int> _limits = {};

  _Request(this._path);

  void filter(String name, dynamic value) {
    _filters[name] = value is List ? value.map((item) => item.toString()).join(',') : value;
  }

  void include(String type, {List<String>? fields, int? limit}) {
    _includes.add(type);
    if (fields != null) {
      _fields[type] = fields.join(',');
    }
    if (limit != null) {
      _limits[type] = limit;
    }
  }

  Uri toUri() {
    final params = <String, dynamic>{
      for (final filter in _filters.entries) //
        'filter[${filter.key}]': filter.value,
      if (_includes.isNotEmpty) //
        'include': _includes.join(','),
      for (final fields in _fields.entries) //
        'fields[${fields.key}]': fields.value,
      for (final limit in _limits.entries) //
        'limit[${limit.key}]': limit.value.toString()
    };

    return Uri.parse(_apiUri + _path).replace(queryParameters: params);
  }
}

class _Response {
  final Response _response;

  _Response(this._response);

  int get status => _response.statusCode;
  Map<String, dynamic> get json => jsonDecode(_response.body);

  List<T> asList<T extends Model>() => ModelParser.parseList<T>(json);
}
