<img src="https://repository-images.githubusercontent.com/350715488/b637b900-d441-11eb-9ef9-0a8183e9a2d4" alt="FastTrack"
	title="Simplify your Flutter app deployment" width="480" />

# Fasttrack

Fasttrack is a command line tool for controlling the release of app versions in 
the **Google Play Store** or **Apple App Store**. It was build to simplify the tasks of creating
app versions, setting the release properties and controlling the rollout of app versions
in multi-app **Flutter** projects.

It is heavily inspired by fastlane, but only supports the central parts of fastlane to
control the final steps of the app release process.

**Supported functionality**

* **App & Play Store** Release Status
* **App Store** Version Creation
* **App Store** Submission for Review
* **Play Store** Version Promotion
* **App Store** Phased Release Update
* **Play Store** Staged Rollout Update

**(Yet) unsupported functionality**

* **iOS Build** Code Singing
* **App Store** archive upload
* **Play Store** bundle upload

## Installation

Install the fasttrack tool to be globally available on the command line

```shell
dart pub global activate fasttrack
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
    id: package.name.1 # either you can specify the application id directly and use the default release configuration
    id2: # or you can override the rollout fraction per app
      packageName: package.name.2
      rollout: 0.2
```

To get your authentication credentials, please follow the corresponding documentation for 
[Android](https://docs.fastlane.tools/getting-started/android/setup/#collect-your-google-credentials) and 
[iOS](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api). 

## Commands

You can always specify the `--help` option, get a list of all commands and options available for fasttrack
and all subcommands.

By default, all commands will run the operation for all apps defined in the config. You can run a command 
for only one or a set of apps by specifying the `--app` or `-a` option.

```shell
fastrack appstore status --app id
fastrack playstore status -a id
```

Fasttrack will use the version and build number found in the version property of project's pubspec.yaml file.
You can always run a command against a specific version, by defining the version with the `--version` or `-v`
parameter.

All modifying commands will show a prompt to the user, that they have to acknowledge to execute the operation.
For a CI/CD system you can suppress this prompt by running the command with the `--no-check` option.

## Play Store commands

fasttrack provides a set of commands to control the release of apps against the Google Play Store. 
These commands can be addressed by calling fasttrack with the `playstore` or `ps` sub command.

All Play Store commands provide the `--dry-run` flag, which can be used to validate the command against
the Play Store API without actually performing a change.

### Release Status

Get the release status of all configured apps from Play Store:

```shell
fastrack playstore status [--help] [--app] [--version] [--track] [--dry-run]
```

When running the command without parameters, fasttrack will get the release status for the version currently found
in the `pubsepc.yaml` file of the project. When providing the `--version` or `-v` option, you can lookup the release
status for a specific version. When specifying the `--version` option with `live`, you can lookup the release status 
of the version currently live or in rollout.

```shell
fasttrack playstore status --version 3.16.1
fasttrack ps status -v live
```

By default, fasttrack will get the status of the apps on the `release` track. When you want to get the status on the
`internal`, `alpha` or `beta` track, specify the specific track with the `--track` option.

```shell
fasttrack playstore status --track internal
```

### Release Promotion

Promote a release from one track to another. Optionally define a fraction at which the release will be rolled out
after the promotion/review on the other track completed.

```shell
fasttrack playstore promote [--help] [--app] [--version] [--track=internal] [--to=production] [--rollout] [--no-check] [--dry-run]
```

By default, fasttrack will promote the apps on the `internal` to the `production` track. When you want to promote
an app from the `alpha` or `beta` track, specify the desired track with the `--track` option. To define `alpha` 
or `beta` track as destination for the promotion, specify the desired track with the `--to` option.

```shell
fasttrack playstore promote --track alpha --to beta
```

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

To update the rollout percentage, you can use the `update` sub command with the desired percentage.

```shell
fastrack playstore rollout update 0.5
fasttrack ps rollout update 50%
```

Use the `halt` sub command to halt the rollout of the current app version. A halted app version can
be resumed later on using the `update` sub command.

```shell
fasttrack playstore rollout halt
```

To finally complete the rollout and deliver your app version to all of your users, you can use the
`complete` sub command.

```shell
fasttrack playstore rollout complete
```

