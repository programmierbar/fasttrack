class ModelParser {
  static List<T> parseList<T extends Model>(Map<String, dynamic> envelope) {
    final includedModels = <String, Map<String, Model>>{};
    if (envelope.containsKey('included')) {
      final includedData = envelope['included'].cast<Map<String, dynamic>>();
      for (final data in includedData) {
        final model = parse(data, includedModels);
        includedModels.putIfAbsent(model._type, () => {})[model.id] = model;
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
    final relations = data.containsKey('relationships')
        ? _parseRelations(data['relationships'] as Map<String, dynamic>, includes)
        : <String, dynamic>{};

    return Model._fromJson(type, id, attributes, relations);
  }

  static Map<String, dynamic> _parseRelations(Map<String, dynamic> data, Map<String, Map<String, Model>> includes) {
    final relations = <String, dynamic>{};
    for (final entry in data.entries) {
      final relationName = entry.key;
      final relationShip = entry.value as Map<String, dynamic>;
      final relationShipData = relationShip['data'];
      if (relationShipData != null) {
        if (relationShipData is List) {
          for (final element in relationShipData) {
            final relatedType = element['type'] as String;
            final relatedId = element['id'] as String;
            relations.putIfAbsent(relationName, () => []).add(includes[relatedType]![relatedId]!);
          }
        } else {
          final relatedType = relationShipData['type'] as String;
          final relatedId = relationShipData['id'] as String;
          relations[relationName] = includes[relatedType]![relatedId]!;
        }
      }
    }

    return relations;
  }
}

abstract class Model {
  final String _type;
  final String id;

  Model._(this.id, this._type);
  factory Model._fromJson(String type, String id, Map<String, dynamic> attributes, Map<String, dynamic> relations) {
    switch (type) {
      case App.type:
        return App._(id, attributes, relations);
      case AppStoreVersion.type:
        return AppStoreVersion._(id, attributes, relations);
      case AppStoreVersionPhasedRelease.type:
        return AppStoreVersionPhasedRelease._(id, attributes);
      case Build.type:
        return Build._(id, attributes);
      default:
        throw Exception('Type $type is not supported yet');
    }
  }
}

class App extends Model {
  static const type = 'apps';
  static const fields = ['name', 'bundleId', 'sku', 'primaryLocale'];

  final String name;
  final String bundleId;
  final String sku;
  final String primaryLocale;
  final List<AppStoreVersion> versions;

  App._(String id, Map<String, dynamic> attributes, Map<String, dynamic> relations)
      : name = attributes['name'],
        bundleId = attributes['bundleId'],
        sku = attributes['sku'],
        primaryLocale = attributes['primaryLocale'],
        versions = relations['appStoreVersions']?.cast<AppStoreVersion>() ?? [],
        super._(id, type);

  AppStoreVersion? get liveVersion {
    return versions.where((version) => version.live).first;
  }

  AppStoreVersion? get editVersion {
    return versions.where((version) => version.editable).first;
  }
}

class AppStoreVersion extends Model {
  static const type = 'appStoreVersions';
  static const fields = ['versionString', 'appStoreState', 'releaseType'];

  final String name;
  final AppStoreState state;
  final ReleaseType releaseType;
  final AppStoreVersionPhasedRelease? phasedRelease;
  final Build? build;

  AppStoreVersion._(String id, Map<String, dynamic> attributes, Map<String, dynamic> relations)
      : name = attributes['versionString'],
        state = AppStoreState._(attributes['appStoreState']),
        releaseType = ReleaseType._(attributes['releaseType']),
        phasedRelease = relations['appStoreVersionPhasedRelease'] as AppStoreVersionPhasedRelease?,
        build = relations['build'] as Build?,
        super._(id, type);

  bool get live => AppStoreState.liveStates.contains(state);
  bool get editable => AppStoreState.editStates.contains(state);
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

  String toString() => _name;
}

class AppStoreVersionPhasedRelease extends Model {
  static const type = 'appStoreVersionPhasedReleases';
  static const fields = ['phasedReleaseState', 'totalPauseDuration', 'currentDayNumber'];
  static const _userFractions = {1: 0.01, 2: 0.02, 3: 0.05, 4: 0.1, 5: 0.2, 6: 0.5, 7: 1.0};

  final PhasedReleaseState state;
  final Duration pauseDuration;
  final int dayNumber;

  AppStoreVersionPhasedRelease._(String id, Map<String, dynamic> attributes)
      : state = enumfromString(PhasedReleaseState.values, (attributes['phasedReleaseState'] as String).toLowerCase()),
        pauseDuration = Duration(days: attributes['totalPauseDuration']),
        dayNumber = attributes['currentDayNumber'],
        super._(id, type);

  double get userFraction {
    if (state == PhasedReleaseState.complete) {
      return 1;
    } else if (state == PhasedReleaseState.active) {
      return _userFractions[dayNumber] ?? 0;
    } else {
      return 0;
    }
  }
}

enum PhasedReleaseState {
  inactive,
  active,
  paused,
  complete,
}

T enumfromString<T>(List<T> values, String value) {
  return values.firstWhere((it) => enumToString(it) == value);
}

String enumToString<T>(T member) {
  final name = member.toString();
  return name.substring(name.indexOf('.') + 1);
}

class Build extends Model {
  static const type = 'builds';

  final String version;
  final ProcessingState processingState;

  Build._(String id, Map<String, dynamic> attributes)
      : version = attributes['version'],
        processingState =
            enumfromString(ProcessingState.values, (attributes['processingState'] as String).toLowerCase()),
        super._(id, type);
}

enum ProcessingState {
  processing,
  failed,
  invalid,
  valid,
}
