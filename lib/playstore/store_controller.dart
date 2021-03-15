import 'package:fasttrack/common/language.dart';
import 'package:fasttrack/playstore/api_client.dart';

const _jsonKeyFile = './credentials/pics-8f026-f32e0b8abb61.json';
final _packageNames = {
  Language.de: 'de.lotum.whatsinthefoto.de',
  Language.en: 'de.lotum.whatsinthefoto.us',
  Language.fr: 'de.lotum.whatsinthefoto.fr',
  Language.es: 'de.lotum.whatsinthefoto.es',
  Language.it: 'de.lotum.whatsinthefoto.it',
  Language.br: 'de.lotum.whatsinthefoto.brazil',
  Language.nl: 'de.lotum.whatsinthefoto.nl',
  Language.ru: 'de.lotum.whatsinthefoto.ru'
};

class StoreController {
  Future<void> getReleases({List<Language>? languages, String track = 'production'}) async {
    languages ??= _packageNames.keys.toList();

    final client = await _getClient();
    final results = await Future.wait(languages.map((language) {
      return client.getReleases(package: _packageNames[language]!, track: track);
    }));

    final mappedResults = Map.fromIterables(languages, results);
    for (final entry in mappedResults.entries) {
      final releases = entry.value;
      if (releases != null) {
        final language = entry.key;
        for (final release in releases) {
          print([
            '${language.code}:',
            release.name,
            '(${release.versionCodes?.join(', ')})',
            '->',
            release.status,
            release.userFraction != null ? '${release.userFraction! * 100}%' : null,
          ].where((part) => part != null).join(' '));
        }
      }
    }

    client.close();
  }

  Future<ApiClient> _getClient() async {
    final client = ApiClient(_jsonKeyFile);
    await client.connect();
    return client;
  }
}
