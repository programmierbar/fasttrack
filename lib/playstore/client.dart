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

  Future<List<TrackRelease>?> getReleases({required String package, required String track}) async {
    final edits = _api.edits;
    final edit = await edits.insert(AppEdit(), package);
    final info = await edits.tracks.get(package, edit.id!, track);
    return info.releases;
  }

  void close() {
    _client.close();
  }
}
