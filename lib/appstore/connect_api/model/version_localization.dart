import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model/model.dart';

class VersionLocalization extends CallableModel {
  static const type = 'appStoreVersionLocalizations';
  static const fields = ['whatsNew'];

  final String locale;
  final String? whatsNew;

  VersionLocalization(String id, AppStoreConnectClient client, Map<String, dynamic> attributes)
      : locale = attributes['locale'],
        whatsNew = attributes['whatsNew'],
        super(type, id, client);

  Future<VersionLocalization> update(VersionLocalizationAttributes attributes) async {
    return client.patchModel(type: 'appStoreVersionLocalizations', id: id, attributes: attributes);
  }
}

class VersionLocalizationAttributes implements ModelAttributes {
  final String? whatsNew;

  VersionLocalizationAttributes({this.whatsNew});

  Map<String, dynamic?> toMap() {
    return {
      'whatsNew': whatsNew,
    };
  }
}
