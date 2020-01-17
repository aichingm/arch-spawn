# Arch-Spawn

Create offline and/or automated archlinux installation iso's.

## Installation

Just clone the repository.

## Dependencies

* make
* pacman
* pacman-contrib (pactree)
* squashfs-tools (unsquashfs, mksquashfs)
* cdrtools (mkiosfs)
* sudo
* coreutils

You can check if you have installed all dependencies by running `make check-deps`.

## Create a new .iso

Create a  new iso by running `make iso` with the name of the profile.  You can use the profiles in `profiles/`.

```bash
make iso profile=default
```

## Profiles

All profiles are extending the `default.ini` profile omitted values will be taken from there.

### Default profiles

- default

  ```ini
  Name=arch-spawn-default
  Halt_For_Patching=0
  On_Startup=scripts/on_startup.sh
  On_Login=scripts/on_login.sh
  After_Install=scripts/after_install.sh
  Offline=0
  Packages=
  Installer=1
  Zone=Europe
  SubZone=London
  Password=default
  Locale=en_US.UTF-8
  Auto_Install=1
  ```

- test

  ```ini
  Name=arch-spawn-test
  Halt_For_Patching=1
  On_Startup=none
  On_Login=none
  After_Install=none
  Offline=1
  Packages=vim
  Auto_Install=0
  ```

- offline

  ```ini
  Name=arch-spawn-offline
  Halt_For_Patching=0
  On_Startup=none
  On_Login=none
  After_Install=none
  Offline=1
  Packages=vim
  Installer=0
  Auto_Install=0
  ```

- offline-auto

  ```ini
  Name=arch-spawn-offline
  Halt_For_Patching=0
  On_Startup=none
  On_Login=none
  After_Install=none
  Offline=1
  Packages=vim
  Installer=1
  Auto_Install=1
  ```

### Values

* Name \<string> name of the profile (should be the same as the file name)
* Halt_For_Patching \<0 or 1> when set to 1 `make iso` will halt during the process and to let you make manual modifications
* On_Startup \<string> path to a bash file which will be run at startup of the iso
* On_Login=\<string> path to a bash file which will be run at login of the iso
* After_Install=\<string> path to a bash file which will be run after the installation inside of the chroot
* Offline \<0 or 1> When set to 1 all needed packages will be downloaded to the iso and pacstrap will be patched to enable an offline installation
* Packages=\<list of space separated packages> This additional (to base) packages will be installed by the installer. If `Offline` is set to 1 this packages will be included in the iso.
* Installer \<0 or 1> Set to one to include the installer on the iso.
* Zone=<string> A geographical zone. Check `/usr/share/zoneinfo`.
* SubZone \<string> A geographical sub zone. Check `/usr/share/*/`.
* Password \<string> The root password for the installation
* Locale \<string> The locale for the installation like `en_US.UTF-8`. Check `/etc/locale.gen` *Only utf-8 locale*
* Auto_Install \<0 or 1> Set to 1 to start the installer after the boot of the iso.

### Custom profiles

To create a custom profile copy the default profile and change the values. Make sure to place the new profile in `profiles/`.  and add the `.iso` suffix. Git will not track other then the default profiles.

## Hooks

You can create a set of hooks with `make hooks` which will hook into some parts of the creation process. Simply run `make hooks` and check the `hooks` directory the names of the  files in there should be self-explanatory. The hooks will be executed with `bash` so make sure to to write valid code in there.

## Installer

The installer will install archlinux on `/dev/sda` with the vary basic options. If `/dev/sda` has a partition table the installer will abort, so make sure `/dev/sda` is clean. For more detail check `installer/install.sh` and `installer/chroot.sh`

## Var

You can override values in `const/` by creating the directory `var` and a file with the name of the file in `const/` which you want to override. Files in `var` will always overrule the corresponding file in `const`.

## Troubleshooting

`make grab` returns with error 22 this most likely means that the iso could not be downloaded. Check the value in `var/iso_version` or `const/iso_version`.

## How does it work

Arch-Spawn basically does this simple steps:

1. Downloading the official archlinux installation iso.
2. Mounting the iso
3. Unpacking the file system
4. Unmounting the iso
5. Inserting the packages and files
6. Packing the file system
7. Creating a new iso

## Updating to a new ISO-Version

1. Change the version in const/iso_version to e.g. `2019.10.01`
2. Change the sha1 hash in const/iso_hash to e.g. `23da63fe1f83f6f066ce0cc5450a1c5171e242d9`
3. Test the new version
   1. `make iso profile=offline-auto`
   2. `make test-qumu profile=offline-auto`
   3. Login with user `root` and password `default`









