
## Global install

Install the fasttrack tool to be globally available in your favorite cli.

```
flutter pub global activate --source git https://github.com/lotum/fasttrack
```

Add the bin cache of the pub tool to global path for your favorite cli.

```
export PATH="$PATH:$HOME/.pub-cache/bin:$HOME/<path-to-flutter-sdk>/.pub-cache/bin"
```

Fix the dart executable shell entry point

```
vi <path-to-flutter-sdk>/.pub-cache/bin/fasttrack
flutter pub global run fasttrack:fasttrack "$@"
```
