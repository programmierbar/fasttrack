# Fasttrack

The fasttrack tool is a command line tool for controlling the release of app versions in 
the **Google Play Store** or **Apple App Store**. It was designed to simplify the tasks fo creating
app versions, setting the release properties and controlling the rollout of app versions
in multi app **Flutter** projects.

It is heavily inspired by fastlane, but only supports the central aspects of fastalane to
control the app release process.

## Installation

Install the fasttrack tool to be globally available in your favorite cli.

```shell
flutter pub global activate --source git https://github.com/lotum/fasttrack
```

Add the bin cache of the pub tool to global path to your favorite cli startup script (e.g. `.zshrc`)

```shell
export PATH="$PATH:$HOME/.pub-cache/bin:$HOME/<path-to-flutter-sdk>/.pub-cache/bin"
```

Fix the dart executable shell entry point

```shell
vi <path-to-flutter-sdk>/.pub-cache/bin/fasttrack
flutter pub global run fasttrack:fasttrack "$@"
```

## Configuration

Fasttracks expects its configuration in a `config.yaml` file located in the `fasttrack` directory in the project root 
directory.

```yaml
metadata:
  dir: . # the directory where the project metadata like release notes are located
appStore: # this section defines the App Store related configuration 
  credentials:
    keyFile: auth_key.pem # the private authentication key in pem format
    keyId: # the id of the provided authentication key
    issuerId: # the issuer id of the publisher
  release: # the default release settings for all app configurations. Can be overridden for each app
    phased: false # whether to do a phased release for the app by default
    manual: false # whether to manually release the app after review
  apps: # this section defines the app specific release configurations
    id: 111111111 # either you can only the define the app id and use the common release settings
    id2: # or you can override the release settings for each app individually
      appId: 22222222
      phased: true
      manual: true
playStore: # this section defines the Play Store related configuration
  keyFile: auth_key.json # the authentication for the Google Play Store service user in json format
  rollout: 0.1 # the initial rollout fraction when promoting an app version to the release track 
  apps: # the app specific release configurations
    id: application.id # either you can specify the application id directly and use the default release configuration
    id2: # or you can override the rollout fraction per app
      appId: application2.id
      rollout: 0.2
```

## Play Store commands

Fasttrack provides a set of commands to control the release of apps against the Google PlayStore. 
These commands can be addressed by calling fasttrack with the `playstore` or `ps` sub command. To get
a list of all sub commands available on the `playstore` command, call the command with the `--help` option.
```shell
fastrack playstore --help
```

### Release status

Get the release status of all configured apps from Play Store.

```shell
fastrack playstore status [--help] [--app] [--track] [--version] [--dry-run]
```

#### --app
By default the fasttrack status command will get the release status for all defined Play Store apps. You 

#### --version
When running the command without parameters, fasttrack will get the release status for the version currently found
in the `pubsepc.yaml` file of the project. When providing the `--version` or `-v` option, you can lookup the release
status for a specific version. When specifying the `--version` option with `live`, you can lookup the release status 
of the version currently live or in rollout.

```shell
fasttrack playstore status --version 3.16.1
fasttrack ps status -v live
```