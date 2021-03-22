import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model/model.dart';

class AppStoreVersionLocalization extends CallableModel {
  static const type = 'appStoreVersionLocalizations';
  static const fields = ['whatsNew'];

  final String locale;
  final String? whatsNew;

  AppStoreVersionLocalization(String id, AppStoreConnectClient client, Map<String, dynamic> attributes)
      : locale = attributes['locale'],
        whatsNew = attributes['whatsNew'],
        super(type, id, client);

  Future<AppStoreVersionLocalization> update(AppStoreVersionLocalizationAttributes attributes) async {
    return client.patchAttributes(type: 'appStoreVersionLocalizations', id: id, attributes: attributes);
  }
}

class AppStoreVersionLocalizationAttributes implements ModelAttributes {
  final String? whatsNew;

  AppStoreVersionLocalizationAttributes({this.whatsNew});

  Map<String, dynamic?> toMap() {
    return {
      'whatsNew': whatsNew,
    };
  }
}
