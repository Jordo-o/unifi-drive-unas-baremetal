# UniFi Drive install script for arm64

Run UniFi Drive UNAS in Docker on ARM64 hardware.

## Usage
For the latest features and fixes always use the latest version.  
Some things may not work properly if Drive version is not new enough.  

**Make sure you have read the below section [Issues with remote access](#issues-with-remote-access).**

### Updates

> [!WARNING]
> Maintain regular backups of the host running Protect and its data and always make backups before updating.

Use `docker compose pull` followed by `docker compose up -d`.  
Protect should take care of migrating itself to a new version automatically (cameras firmware will also auto-update).  
**Never downgrade versions as this may break Protect.**

When Protect updates to a new version, this could introduce new firmware for the cameras, which will start updating.  
The camera firmware update could potentially make the camera no longer work with previous versions of Protect.  
Generally, camera firmware is stable, but should issues occur please note that downgrading camera firmware is very hard or not possible sometimes.

### Config

`STORAGE_DISK` should point to your disk holding the `storage` folder volume.
Drive data is at `/srv` volume.

### Network

> [!IMPORTANT]
> Protect requires `IPv6` enabled (even if blocked by firewall or not routed) and make sure ports used by Protect are not in use by other services/images (`80`, `443` etc.).  

Real UNAS has 2 network interfaces (`enp0s1` and `enp0s2`), if you mask your real network interface with `enp0s2` (see [Issues with remote access](#issues-with-remote-access)), then you only need to add `enp0s1`.  
For Debian, Ubuntu and other alike you can add a dummy interface with `ip link add enp0s1 type dummy`, and to be persistent across reboots, add to host network config at `/etc/network/interfaces`:
```
auto enp0s1
iface enp0s1 inet manual
    pre-up ip link add enp0s1 type dummy
    post-down ip link del enp0s1
```
Although this may not be needed and Protect may work and not give errors, the `ubnt-systool` network speed info will return an error when queried by Protect. It is not yet clear how or if this error influences Protect.  
This further helps mimic the UNVR hardware which Protect expects to be running on.

## Setup

> [!IMPORTANT]
> Drive requires at least 4 GB RAM in order to boot and run correctly.  

When you run the image for the first time, you have to go through the initial console setup, find the host IP address and
navigate to `http://host-ip`.  
Make sure you have disconnected the internet on the docker host (else it will auto update and may break the container),
and proceed with the offline mode setup.  
After the initial setup, got to console settings and disable auto update of the console and applications.  
The auto-update does not work and may break the container.

## Logs

You can check logs using `docker compose logs -f` and files inside container at `/var/log`.  
Inside the container you can check logs using `journalctl -f`.  
`unifi-drive` logs are at `/srv/unifi-drive/logs`.  
`unifi-core` logs are at `/data/unifi-core/logs`.  
If `DEBUG_STORAGE` is enabled, logs are at `/var/log/storage_disk_debug.log`.

## Issues with remote access

> [!CAUTION]
> Make sure to update your network settings (**including your firewall rules**) to reflect the new interface name or you will lose internet connectivity. This is typically in `/etc/network/interfaces`.  
> If you are using NetworkManager service on host, then this does not apply, as your new interface will be configured using DHCP automatically, but your firewall rules may still need updating.

> [!NOTE]
> Remote access via the cloud does not work with Docker on macOS (use a Debian VM instead).

There is a known issue that remote access to your UNVR via the cloud will not work with the console unless the primary network interface is named `enp0s2`. To achieve this, **on your host machine** create the file `/etc/systemd/network/98-enp0s2.link` with the content below, replacing `xx:xx:xx:xx:xx:xx` with your actual MAC address.

```
[Match]
MACAddress=xx:xx:xx:xx:xx:xx

[Link]
Name=enp0s2
```

**Make sure to update your network settings and your firewall rules to reflect the new interface name.**  
To apply the settings, run `sudo update-initramfs -u` and reboot your host machine.

I have also discovered that **direct remote access via the app** (without remote access enabled via Ubnt cloud, or being signed to UI account in the app) requires Protect to have access to `https://static.ui.com` in order to download MAC fingerprints, else you will run into a connection failed issue and will have to hit try again button a few times before you can connect directly and also your console may be displayed offline in the app. So for direct remote access to work correctly in the app, make sure Protect can access `https://static.ui.com`.

## RTSP

RTSP streams from Protect are available under camera settings > Advanced.  
Remove `?enableSrtp` from the end and change to rtsp (port 7447) `rtsp://host-ip:7447/camera-id`.

## Building

Use the `build.sh` script.  
This will download and extract the firmware packages from the latest version available for the `UNVR` from the official UniFi download source (https://fw-update.ubnt.com), inside a docker container.  
You can provide a custom `FW_URL` environment variable to download the firmware binary from a custom link.  
Set `DOCKER_IMAGE` environment variable to use a custom image tag.  
Set `FW_UNSTABLE` when building firmware to download the latest version, skipping the stable flag.
Set `ALL_DEBS` when building firmware to extract and save all packages.

## Acknowledgements

This project has been greatly inspired from below projects.

[markdegrootnl/unifi-protect-arm64](https://github.com/markdegrootnl/unifi-protect-arm64) - original project  

## Disclaimer

This Docker image is not associated with UniFi and/or Ubiquiti in any way.  
We do not distribute any third party software and only use packages that are freely available on the internet.
