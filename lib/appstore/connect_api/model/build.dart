import 'package:fasttrack/appstore/connect_api/model/model.dart';
import 'package:fasttrack/common/extension.dart';

class Build extends Model {
  static const type = 'builds';

  final String version;
  final ProcessingState processingState;

  Build(String id, Map<String, dynamic> attributes)
      : version = attributes['version'],
        processingState =
            enumfromString(ProcessingState.values, (attributes['processingState'] as String).toLowerCase()),
        super(type, id);
}

enum ProcessingState {
  processing,
  failed,
  invalid,
  valid,
}
