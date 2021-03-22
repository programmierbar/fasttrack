import 'dart:convert';

import 'package:fasttrack/appstore/connect_api/model/build.dart';
import 'package:fasttrack/appstore/connect_api/model/model.dart';
import 'package:fasttrack/appstore/connect_api/model/version.dart';
import 'package:fasttrack/appstore/connect_api/token.dart';
import 'package:http/http.dart';

const _apiUri = 'https://api.appstoreconnect.apple.com/v1/';

class AppStoreConnectApi {
  final AppStoreConnectClient _client;
  final String appId;

  AppStoreConnectApi(this._client, this.appId);

  Future<List<AppStoreVersion>> getVersions({
    List<String>? versions,
    List<AppStoreState>? states,
    List<AppStorePlatform>? platforms,
  }) async {
    final request = GetRequest('apps/$appId/appStoreVersions') //
      ..include('appStoreVersionPhasedRelease')
      ..include('build');

    if (versions != null) {
      request.filter('versionString', versions);
    }
    if (states != null) {
      request.filter('appStoreState', states);
    }
    if (platforms != null) {
      request.filter('platform', platforms);
    }

    final response = await _client.get(request);
    return response.asList<AppStoreVersion>();
  }

  Future<AppStoreVersion> postVersion({
    required AppStoreVersionAttributes attributes,
  }) async {
    final response = await _client.post(
      'appStoreVersions',
      {
        'type': 'appStoreVersions',
        'attributes': attributes.toMap()..removeWhere((_, value) => value == null),
        'relationships': {
          'app': {
            'data': {
              'type': 'apps',
              'id': appId,
            }
          }
        }
      },
    );
    return response.as<AppStoreVersion>();
  }

  Future<List<Build>> getBuilds({required String version, String? buildNumber}) async {
    final request = GetRequest('builds') //
      ..filter('app', appId)
      ..filter('preReleaseVersion.version', version)
      ..filter('processingState', ['PROCESSING', 'FAILED', 'INVALID', 'VALID'])
      ..sort('uploadedDate', descending: true);

    if (buildNumber != null) {
      request.filter('version', buildNumber);
    }

    final response = await _client.get(request);
    return response.asList<Build>();
  }
}

class AppStoreConnectClient {
  final AppStoreConnectTokenConfig _config;
  final Client _client = Client();

  AppStoreConnectToken? _token;

  AppStoreConnectClient(this._config);

  Future<ApiResponse> get(GetRequest request) async {
    final uri = request.toUri();
    final token = await _getToken();
    final response = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    });
    print('Get response ${response.body}');

    return ApiResponse(this, response);
  }

  Future<ApiResponse> post(String path, Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse(_apiUri + path),
      headers: await _getHeaders(),
      body: jsonEncode({'data': data}),
    );

    print('Post response ${response.body}');
    return ApiResponse(this, response);
  }

  Future<ApiResponse> patch(String path, Map<String, dynamic> data) async {
    final response = await _client.patch(
      Uri.parse(_apiUri + path),
      headers: await _getHeaders(),
      body: jsonEncode({'data': data}),
    );

    print('Patch response ${response.body}');
    return ApiResponse(this, response);
  }

  Future<T> patchAttributes<T extends Model>({
    required String type,
    required String id,
    required ModelAttributes attributes,
  }) async {
    final response = await patch('$type/$id', {
      'type': type,
      'id': id,
      'attributes': attributes.toMap()..removeWhere((_, value) => value == null),
    });
    return response.as<T>();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    };
  }

  Future<AppStoreConnectToken> _getToken() async {
    return _token ??= await AppStoreConnectToken.fromFile(
      keyId: _config.keyId,
      issuerId: _config.issuerId,
      path: _config.keyFile,
    );
  }
}

class GetRequest {
  final String _path;
  final Map<String, dynamic> _filters = {};
  final Set<String> _includes = {};
  final Map<String, String> _fields = {};
  final Map<String, int> _limits = {};
  final Map<String, bool> _sort = {};

  GetRequest(this._path);

  void filter(String field, dynamic value) {
    _filters[field] = value is List ? value.map((item) => item.toString()).join(',') : value;
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

  void sort(String field, {bool descending = false}) {
    _sort[field] = descending;
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
        'limit[${limit.key}]': limit.value.toString(),
      if (_sort.isNotEmpty) //
        'sort': _sort.entries.map((entry) => '${entry.value ? '-' : ''}${entry.key}').join(',')
    };

    return Uri.parse(_apiUri + _path).replace(queryParameters: params);
  }
}

class ApiResponse {
  final AppStoreConnectClient _client;
  final Response _response;

  ApiResponse(this._client, this._response);

  int get status => _response.statusCode;
  Map<String, dynamic> get json => jsonDecode(_response.body);

  List<T> asList<T extends Model>() => ModelParser.parseList<T>(_client, json);
  T as<T extends Model>() => ModelParser.parse<T>(_client, json);
}
