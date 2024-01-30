# NDNSensorApp


## Mirror
If you are viewing this from a mirror then please visit `https://github.com/NDNAppBachelorThesis/NDNSensorApp` to
access the build artifacts


## Get NDN to run on Windows
1. Install NDN Forwarder https://github.com/named-data/NFD
2. Use the WSLHostPatcher https://github.com/CzBiX/WSLHostPatcher to expose the WSL ports to the network
3. run ``sudo nfd`` to start the daemon
4. Compile and install jNDN https://github.com/named-data/jndn and use that version


## Get App to run
1. Install NFD Forwarder
   1. Download app from https://m.apkpure.com/de/ndn-forwarding-daemon-nfd/net.named_data.nfd (or Google Play)
   2. In the app configure a new face ``tcp://<your_computer_ip>`` and make sure you check `Keep it permanent`
      Add a new route on the prefix ``/`` and the Face ID of the previous step and make sure you check `Keep it permanent`
   3. Start NDF daemon
   4. (If the NDF forwarder app "forgets" your config disable and re-enable NFD.)


## Expose WSL2 ports to the network
- https://github.com/CzBiX/WSLHostPatcher
- (maybe also) https://github.com/microsoft/WSL/issues/4150#issuecomment-1018524753
