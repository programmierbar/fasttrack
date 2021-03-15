abstract class Model {
  String get type;
  final String id;

  static List<T> parseList<T extends Model>(Map<String, dynamic> envelope) {
    final Map<String, Map<String, Model>> includedModels = {};
    if (envelope.containsKey('included')) {
      final includedData = envelope['included'].cast<Map<String, dynamic>>();
      for (final data in includedData) {
        final model = parse(data, includedModels);
        includedModels.putIfAbsent(model.type, () => {})[model.id] = model;
      }
    }

    final modelData = envelope['data'].cast<Map<String, dynamic>>();
    final modelList = modelData.map((data) => parse(data, includedModels)).toList();

    return modelList.cast<T>();
  }

  static Model parse(Map<String, dynamic> data, Map<String, Map<String, Model>> includes) {
    final type = data['type'] as String;
    final id = data['id'] as String;
    final attributes = data['attributes'] as Map<String, dynamic>;

    final Map<String, List<Model>> relations = {};
    if (data.containsKey('relationships')) {
      final relationShips = data['relationships'] as Map<String, dynamic>;
      for (final entry in relationShips.entries) {
        final relatedType = entry.key;
        if (includes.containsKey(relatedType)) {
          final relationShip = entry.value as Map<String, dynamic>;
          if (relationShip.containsKey('data')) {
            final relationShipIds = relationShip['data'].cast<Map<String, dynamic>>();
            for (final element in relationShipIds) {
              final relatedId = element['id'] as String;
              relations.putIfAbsent(relatedType, () => []).add(includes[relatedType]![relatedId]!);
            }
          }
        }
      }
    }

    return Model._fromJson(type, id, attributes, relations);
  }

  Model._(this.id);
  factory Model._fromJson(String type, String id, Map<String, dynamic> attributes, Map<String, List<Model>> relations) {
    switch (type) {
      case App._type:
        return App._(id, attributes, relations);
      case AppStoreVersion._type:
        return AppStoreVersion._(id, attributes);
      default:
        throw Exception('Type $type is not supported yet');
    }
  }
}

class App extends Model {
  static const _type = 'apps';
  static const fields = ['name', 'bundleId', 'sku', 'primaryLocale'];

  final String name;
  final String bundleId;
  final String sku;
  final String primaryLocale;
  final List<AppStoreVersion> versions;

  App._(String id, Map<String, dynamic> attributes, Map<String, List<Model>> relations)
      : name = attributes['name'],
        bundleId = attributes['bundleId'],
        sku = attributes['sku'],
        primaryLocale = attributes['primaryLocale'],
        versions = relations['appStoreVersions']?.cast<AppStoreVersion>() ?? [],
        super._(id);

  String get type => _type;

  AppStoreVersion? get liveVersion {
    return versions.where((version) => version.live).first;
  }

  AppStoreVersion? get editVersion {
    return versions.where((version) => version.editable).first;
  }
}

class AppStoreVersion extends Model {
  static const _type = 'appStoreVersions';
  static const fields = ['versionString', 'appStoreState', 'releaseType'];

  final String name;
  final AppStoreState state;
  final ReleaseType releaseType;

  AppStoreVersion._(String id, Map<String, dynamic> attributes)
      : name = attributes['versionString'],
        state = AppStoreState._(attributes['appStoreState']),
        releaseType = ReleaseType._(attributes['releaseType']),
        super._(id);

  String get type => _type;
  bool get live => AppStoreState._liveStates.contains(state);
  bool get editable => AppStoreState._editStates.contains(state);
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

  static const _liveStates = [
    readyForSale,
    pendingAppleRelease,
    pendingDeveloperRelease,
    processingForAppStore,
    inReview,
    developerRemovedFromSale
  ];
  static const _editStates = [
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

  String toString() => _name;
}
