import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/appstore/connect_api/model/build.dart';
import 'package:fasttrack/appstore/connect_api/model/model.dart';
import 'package:fasttrack/appstore/connect_api/model/phased_release.dart';

class AppStoreVersion extends ApiModel {
  static const type = 'appStoreVersions';
  static const fields = ['versionString', 'appStoreState', 'releaseType'];

  final String versionString;
  final AppStoreState appStoreState;
  final ReleaseType releaseType;

  final AppStoreVersionPhasedRelease? phasedRelease;
  final Build? build;

  AppStoreVersion(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    Map<String, dynamic> relations,
  )   : versionString = attributes['versionString'],
        appStoreState = AppStoreState._(attributes['appStoreState']),
        releaseType = ReleaseType._(attributes['releaseType']),
        phasedRelease = relations['appStoreVersionPhasedRelease'] as AppStoreVersionPhasedRelease?,
        build = relations['build'] as Build?,
        super(type, id, client);

  bool get live => AppStoreState.liveStates.contains(appStoreState);
  bool get editable => AppStoreState.editStates.contains(appStoreState);

  Future<AppStoreVersion> update(AppStoreVersionAttributes attributes) async {
    final response = await client.patch(
      'appStoreVersions/$id',
      {
        'type': 'appStoreVersions',
        'id': id,
        'attributes': attributes.toMap()..removeWhere((_, value) => value == null),
      },
    );
    return response.as<AppStoreVersion>();
  }

  Future<List<AppStoreVersionLocalization>> getLocalizations() async {
    final request = GetRequest('appStoreVersions/$id/appStoreVersionLocalizations');
    final response = await client.get(request);
    return response.asList<AppStoreVersionLocalization>();
  }
}

class AppStoreVersionAttributes {
  final String? versionString;
  final AppStorePlatform? platform;

  const AppStoreVersionAttributes({this.versionString, this.platform});

  Map<String, dynamic> toMap() {
    return {
      'versionString': versionString,
      'platform': platform.toString(),
    };
  }
}

class AppStoreState {
  static const readyForSale = AppStoreState._('READY_FOR_SALE');
  static const processingForAppStore = AppStoreState._('PROCESSING_FOR_APP_STORE');
  static const pendingDeveloperRelease = AppStoreState._('PENDING_DEVELOPER_RELEASE');
  static const pendingAppleRelease = AppStoreState._('PENDING_APPLE_RELEASE');
  static const inReview = AppStoreState._('WAITING_FOR_REVIEW');
  static const waitingForReview = AppStoreState._('WAITING_FOR_REVIEW');
  static const developerRejected = AppStoreState._('DEVELOPER_REJECTED');
  static const developerRemovedFromSale = AppStoreState._('DEVELOPER_REMOVED_FROM_SALE');
  static const rejected = AppStoreState._('REJECTED');
  static const prepareForSubmission = AppStoreState._('PREPARE_FOR_SUBMISSION');
  static const metadataRejected = AppStoreState._('METADATA_REJECTED');
  static const invalidBinary = AppStoreState._('INVALID_BINARY');

  static const liveStates = [
    readyForSale,
    pendingAppleRelease,
    pendingDeveloperRelease,
    processingForAppStore,
    inReview,
    developerRemovedFromSale
  ];
  static const editStates = [
    prepareForSubmission,
    developerRejected,
    rejected,
    metadataRejected,
    waitingForReview,
    invalidBinary
  ];

  final String _name;
  const AppStoreState._(this._name);

  int get hashCode => _name.hashCode;
  bool operator ==(dynamic other) => other is AppStoreState && other._name == _name;
  String toString() => _name;
}

class ReleaseType {
  static const afterApproval = ReleaseType._('AFTER_APPROVAL');
  static const manual = ReleaseType._('MANUAL');
  static const scheduled = ReleaseType._('SCHEDULED');

  final String _name;
  const ReleaseType._(this._name);

  int get hashCode => _name.hashCode;
  bool operator ==(dynamic other) => other is ReleaseType && other._name == _name;
  String toString() => _name;
}
