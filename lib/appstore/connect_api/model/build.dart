import 'package:fasttrack/appstore/connect_api/model/model.dart';

class Build extends Model {
  static const type = 'builds';

  final String version;
  final ProcessingState processingState;

  Build(String id, Map<String, dynamic> attributes)
      : version = attributes['version'],
        processingState = ProcessingState._(attributes['processingState']),
        super(type, id);

  bool get valid => processingState == ProcessingState.valid;
  bool get processed => processingState != ProcessingState.processing;
}

class ProcessingState {
  static const processing = ProcessingState._('PROCESSING');
  static const failed = ProcessingState._('FAILED');
  static const invalid = ProcessingState._('INVALID');
  static const valid = ProcessingState._('VALID');

  final String _value;
  const ProcessingState._(this._value);

  int get hashCode => _value.hashCode;
  bool operator ==(dynamic other) => other is ProcessingState && other._value == _value;
  String toString() => _value;
}
