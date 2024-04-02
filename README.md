# NDNSensorApp

## Mirror

If you are viewing this from a mirror then please
visit `https://github.com/NDNAppBachelorThesis/NDNSensorApp` to
access the build artifacts

# Get NDN to run on Windows

Just don't! I tried so hard and every solution, no matter how good it seems, has problems, which
render it unusable.
Go run a Hyper-V VM with and external virtual switch and enjoy the hours of time you just saved.


# Can't install the release version of the app
Run the following commands
```shell
adb shell pm list packages
adb uninstall de.matthes.ndn_sensor_app
```
