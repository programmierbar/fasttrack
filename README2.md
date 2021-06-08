# Fasttrack

The fasttrack tool is a command line tool for controlling the release of app versions in 
the **Google Play Store** or **Apple App Store**. It was designed to simplify the tasks of creating
app versions, setting the release properties and controlling the rollout of app versions
in multi-app **Flutter** projects.

It is heavily inspired by fastlane, but only supports the core aspects of fastlane to
control the app release process.

## Installation

Install the fasttrack tool to be globally available in your favorite CLI:

```shell
flutter pub global activate --source git https://github.com/lotum/fasttrack
```

Add the bin cache of the pub tool to global path to your favorite CLI startup script (e.g. `.zshrc`):

```shell
export PATH="$PATH:$HOME/.pub-cache/bin:$HOME/<path-to-flutter-sdk>/.pub-cache/bin"
```

Fix the dart executable shell entry point:

```shell
vi <path-to-flutter-sdk>/.pub-cache/bin/fasttrack
flutter pub global run fasttrack:fasttrack "$@"
```

## Configuration

fasttrack expects its configuration in a `config.yaml` file located in the `fasttrack` directory in the project root 
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

fasttrack provides a set of commands to control the release of apps against the Google Play Store. 
These commands can be addressed by calling fasttrack with the `playstore` or `ps` sub command. To get
a list of all sub commands available on the `playstore` command, call the command with the `--help` option.
```shell
fastrack playstore --help
```

### --no-check
All modifying commands will show a prompt to the user, that they have to acknowledge to execute the operation.
For a CI/CD system you can suppress this prompt by running the command with the `--no-check` option.

#### --dry-run
All Play Store commands provide the `--dry-run` flag, which can be used to validate the command against
the Play Store API without actually performing a change.

### Release Status

Get the release status of all configured apps from Play Store:

```shell
fastrack playstore status [--help] [--app] [--track] [--version] [--dry-run]
```

#### --app
By default, the status command will get the release status for all defined Play Store apps. You can specify
to get the release status for only one or a set of apps by specifying the `--app` option.

```shell
fastrack playstore status --app id
fastrack ps status -a id -a id2
```

#### --version
When running the command without parameters, fasttrack will get the release status for the version currently found
in the `pubsepc.yaml` file of the project. When providing the `--version` or `-v` option, you can lookup the release
status for a specific version. When specifying the `--version` option with `live`, you can lookup the release status 
of the version currently live or in rollout.

```shell
fasttrack playstore status --version 3.16.1
fasttrack ps status -v live
```

#### --track
By default, fasttrack will get the status of the apps on the `release` track. When you want to get the status on the
`internal`, `alpha` or `beta` track, specify the specific track with the `--track` option.

```shell
fasttrack playstore status --track internal
```

### Release Promotion

Promote a release from one track to another. Optionally define a fraction at which the release will be rolled out
after the promotion/review on the other track completed.

```shell
fasttrack playstore promote [--help] [--app] [--track=internal] [--to=production] [--version] [--rollout] [--no-check] [--dry-run]
```

#### --app
By default, the promote command will promote all defined apps from one track to another. You can specify
to promote only one or a set of apps by specifying the app ids the `--app` option.

```shell
fastrack playstore promote --app id
fastrack ps promote -a id -a id2
```

#### --track
By default, fasttrack will promote the apps on the `internal` to the `production` track. When you want to promote
an app from the `alpha` or `beta` track, specify the desired track with the `--track` option.

```shell
fasttrack playstore promote --track beta
```

#### --to
Defines the track, where the app version should be promoted to. By default, fasttrack will promote the app
from the `internal` to the `production` track. To define `alpha` or `beta` track as destination for the
promotion, specify the desired track with the `--to` option.

```shell
fastrack playstore promote --to alpha
```

#### --version
When running the promote command without parameters, fasttrack will promote the version currently found
in the `pubsepc.yaml` file of the project. When providing the `--version` or `-v` option, you can promote
a specific version to another track.

#### --rollout
By default, fasttrack will release the app to the user fraction defined in the `rollout` parameter in
the configuration file. You can override the configured rollout fraction by specifying the desired
fraction with the `--rollout` option. A fraction of `0` will promote the app version as draft. A fraction
of `1` will completely release the app version after promotion. A fraction between `0` and `1` will release
the app version to the corresponding percentage of users. The fraction can also be defined as percentage
between `0%` and `100%`.

```shell
fasttrack playstore promote --rollout 0.2
fasttrack ps promote --r 100%
```

### Release Update

Updates, pauses or completes an app version currently in rollout.

#### update

Updates the app version with a new rollout fraction.

```shell
fastrack playstore rollout update 0.5
fasttrack ps rollout update 50%
```

#### pause

Halts the app version currently in rollout. A halted app version can be resumed later on.

```shell
fasttrack playstore rollout halt
```

#### complete

Completes the rollout of the app version.

```shell
fasttrack playstore rollout complete
```

