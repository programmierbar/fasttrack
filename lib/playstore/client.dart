import 'dart:io' as io;

import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

class PlayStoreApiClient {
  final String _jsonKeyFile;
  late final AuthClient _client;
  late final AndroidPublisherApi _api;

  PlayStoreApiClient(this._jsonKeyFile);

  Future<void> connect() async {
    final content = await io.File(_jsonKeyFile).readAsString();
    final credentials = ServiceAccountCredentials.fromJson(content);
    final scopes = [AndroidPublisherApi.androidpublisherScope];

    _client = await clientViaServiceAccount(credentials, scopes);
    _api = AndroidPublisherApi(_client);
  }

  PlayStoreTrackApi getTrackApi({required String packageName}) {
    return PlayStoreTrackApi._(_api, packageName);
  }

  void close() {
    _client.close();
  }
}

class PlayStoreApi {
  final String packageName;
  final EditsResource _resource;
  AppEdit? _edit;

  PlayStoreApi._(AndroidPublisherApi api, this.packageName) : _resource = api.edits;

  Future<void> _begin() async {
    _edit ??= await _resource.insert(AppEdit(), packageName);
  }

  Future<void> validate() async {
    assert(_edit != null);
    await _resource.validate(packageName, _edit!.id!);
  }

  Future<void> commit() async {
    assert(_edit != null);
    await _resource.commit(packageName, _edit!.id!);
    _edit = null;
  }

  Future<void> abort() async {
    assert(_edit != null);
    await _resource.delete(packageName, _edit!.id!);
    _edit = null;
  }
}

class PlayStoreTrackApi extends PlayStoreApi {
  PlayStoreTrackApi._(AndroidPublisherApi api, String packageName) : super._(api, packageName);

  Future<Track> get({required String track}) async {
    await _begin();
    return await _resource.tracks.get(packageName, _edit!.id!, track);
  }

  Future<void> update(Track track) async {
    await _begin();
    await _resource.tracks.update(track, packageName, _edit!.id!, track.track!);
  }
}
