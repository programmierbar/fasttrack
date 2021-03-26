import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model.dart';
import 'package:fasttrack/appstore/connect_api/model/build.dart';
import 'package:fasttrack/appstore/connect_api/model/model.dart';
import 'package:fasttrack/appstore/connect_api/model/phased_release.dart';
import 'package:fasttrack/appstore/connect_api/model/version_submission.dart';

class AppStoreVersion extends CallableModel {
  static const type = 'appStoreVersions';
  static const fields = ['versionString', 'appStoreState', 'releaseType'];

  final AppStorePlatform platform;
  final String versionString;
  final AppStoreState appStoreState;
  final ReleaseType releaseType;

  final Build? build;
  final AppStoreVersionPhasedRelease? phasedRelease;
  final AppStoreVersionSubmission? submission;

  AppStoreVersion(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    Map<String, dynamic> relations,
  )   : platform = AppStorePlatform._(attributes['platform']),
        versionString = attributes['versionString'],
        appStoreState = AppStoreState._(attributes['appStoreState']),
        releaseType = ReleaseType._(attributes['releaseType']),
        build = relations['build'] as Build?,
        phasedRelease = relations['appStoreVersionPhasedRelease'] as AppStoreVersionPhasedRelease?,
        submission = relations['appStoreVersionSubmission'] as AppStoreVersionSubmission?,
        super(type, id, client);

  bool get live => AppStoreState.liveStates.contains(appStoreState);
  bool get editable => AppStoreState.editStates.contains(appStoreState);

  Future<List<AppStoreVersionLocalization>> getLocalizations() async {
    final request = GetRequest('appStoreVersions/$id/appStoreVersionLocalizations');
    final response = await client.get(request);
    return response.asList<AppStoreVersionLocalization>();
  }

  Future<AppStoreVersion> update(AppStoreVersionAttributes attributes) {
    return client.patchModel(
      type: 'appStoreVersions',
      id: id,
      attributes: attributes,
    );
  }

  Future<AppStoreVersionPhasedRelease> setPhasedRelease(AppStoreVersionPhasedReleaseAttributes attributes) {
    return client.postModel(
      type: AppStoreVersionPhasedRelease.type,
      attributes: attributes,
      relationships: {
        'appStoreVersion': ModelRelationship(type: AppStoreVersion.type, id: id),
      },
    );
  }

  Future<AppStoreVersion> setBuild(Build build) async {
    return client.patchModel<AppStoreVersion>(
      type: AppStoreVersion.type,
      id: id,
      relationships: {
        'build': ModelRelationship(type: Build.type, id: build.id),
      },
    );
  }

  Future<AppStoreVersionSubmission> addSubmission() {
    return client.postModel<AppStoreVersionSubmission>(
      type: AppStoreVersionSubmission.type,
      relationships: {
        'appStoreVersion': ModelRelationship(type: AppStoreVersion.type, id: id),
      },
    );
  }

  Future<ReleaseRequest> addReleaseRequest() {
    return client.postModel<ReleaseRequest>(
      type: ReleaseRequest.type,
      relationships: {
        'appStoreVersion': ModelRelationship(type: AppStoreVersion.type, id: id),
      },
    );
  }
}

class AppStoreVersionAttributes implements ModelAttributes {
  final AppStorePlatform? platform;
  final String? versionString;
  final ReleaseType? releaseType;

  AppStoreVersionAttributes({
    this.platform,
    this.versionString,
    this.releaseType,
  });

  Map<String, dynamic?> toMap() {
    return {
      'platform': platform?.toString(),
      'versionString': versionString,
      'releaseType': releaseType?.toString(),
    };
  }
}

class AppStorePlatform {
  static const iOS = AppStorePlatform._('IOS');
  static const MacOS = AppStorePlatform._('MacOS');
  static const TvOS = AppStorePlatform._('TV_OS');

  final String _name;
  const AppStorePlatform._(this._name);

  String toString() => _name;
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

class ReleaseRequest extends Model {
  static const type = 'appStoreVersionReleaseRequests';
  ReleaseRequest(String id) : super(type, id);
}
