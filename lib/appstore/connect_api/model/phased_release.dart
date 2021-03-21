import 'package:fasttrack/appstore/connect_api/model/model.dart';
import 'package:fasttrack/common/extension.dart';

class AppStoreVersionPhasedRelease extends Model {
  static const type = 'appStoreVersionPhasedReleases';
  static const fields = ['phasedReleaseState', 'totalPauseDuration', 'currentDayNumber'];
  static const _userFractions = {1: 0.01, 2: 0.02, 3: 0.05, 4: 0.1, 5: 0.2, 6: 0.5, 7: 1.0};

  final PhasedReleaseState phasedReleaseState;
  final Duration totalPauseDuration;
  final int currentDayNumber;

  AppStoreVersionPhasedRelease(String id, Map<String, dynamic> attributes)
      : phasedReleaseState =
            enumfromString(PhasedReleaseState.values, (attributes['phasedReleaseState'] as String).toLowerCase()),
        totalPauseDuration = Duration(days: attributes['totalPauseDuration']),
        currentDayNumber = attributes['currentDayNumber'],
        super(type, id);

  double get userFraction {
    if (phasedReleaseState == PhasedReleaseState.complete) {
      return 1;
    } else if (phasedReleaseState == PhasedReleaseState.active) {
      return _userFractions[currentDayNumber] ?? 0;
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
