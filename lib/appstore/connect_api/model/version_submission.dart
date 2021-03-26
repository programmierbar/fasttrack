import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';

class AppStoreVersionSubmission extends CallableModel {
  static const type = 'appStoreVersionSubmissions';

  final bool canReject;

  AppStoreVersionSubmission(String id, AppStoreConnectClient client, Map<String, dynamic> attributes)
      : canReject = attributes['canReject'] ?? true,
        super(type, id, client);

  Future<void> delete() {
    return client.delete('$type/$id');
  }
}
