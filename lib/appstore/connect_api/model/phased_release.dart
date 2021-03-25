import 'package:fasttrack/appstore/connect_api/client.dart';
import 'package:fasttrack/appstore/connect_api/model/model.dart';

class AppStoreVersionPhasedReleaseAttributes extends ModelAttributes {
  final PhasedReleaseState phasedReleaseState;

  AppStoreVersionPhasedReleaseAttributes({required this.phasedReleaseState});

  Map<String, dynamic?> toMap() {
    return {'phasedReleaseState': phasedReleaseState.toString()};
  }
}

class AppStoreVersionPhasedRelease extends CallableModel {
  static const type = 'appStoreVersionPhasedReleases';
  static const fields = ['phasedReleaseState', 'totalPauseDuration', 'currentDayNumber'];
  static const _userFractions = {1: 0.01, 2: 0.02, 3: 0.05, 4: 0.1, 5: 0.2, 6: 0.5, 7: 1.0};

  final PhasedReleaseState phasedReleaseState;
  final Duration totalPauseDuration;
  final int currentDayNumber;

  AppStoreVersionPhasedRelease(String id, AppStoreConnectClient client, Map<String, dynamic> attributes)
      : phasedReleaseState = PhasedReleaseState._(attributes['phasedReleaseState']),
        totalPauseDuration = Duration(days: attributes['totalPauseDuration']),
        currentDayNumber = attributes['currentDayNumber'],
        super(type, id, client);

  double get userFraction {
    if (phasedReleaseState == PhasedReleaseState.complete) {
      return 1;
    } else if (phasedReleaseState == PhasedReleaseState.active) {
      return _userFractions[currentDayNumber] ?? 0;
    } else {
      return 0;
    }
  }

  Future<void> update(AppStoreVersionPhasedReleaseAttributes attributes) {
    return client.patchAttributes(type: type, id: id, attributes: attributes);
  }

  Future<void> delete() {
    return client.delete('$type/$id');
  }
}

class PhasedReleaseState {
  static const inactive = PhasedReleaseState._('INACTIVE');
  static const active = PhasedReleaseState._('ACTIVE');
  static const paused = PhasedReleaseState._('PAUSED');
  static const complete = PhasedReleaseState._('COMPLETE');

  final String _value;
  const PhasedReleaseState._(this._value);

  int get hashCode => _value.hashCode;
  bool operator ==(dynamic other) => other is PhasedReleaseState && other._value == _value;
  String toString() => _value;
}
