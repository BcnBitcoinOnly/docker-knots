# Deterministic Build Guide

The following is a step-by-step guide to perform a deterministic build of [Bitcoin Knots] and attest with
your PGP signature that the binaries distributed in [Knots' website] are genuine.

## Requirements

* Ubuntu 22.04 (not a hard requirement, but to be able to follow the guide verbatim)
* An Apple Developer account (requires email and SMS verification to set up the account)
* A PGP key to attest to the build results
* A GitHub account to submit your build attestation
* A powerful CPU
* Lots of RAM
* About 100GB of free space for intermediary build artifacts
* A bit of proficiency with the Linux command line
* Patience

## Install Guix

Start by installing the `guix`, `build-essentials` and `curl` packages provided by Ubuntu, then update Guix to its latest stable version using its own update command (`pull`, for some reason):

```shell
$ sudo apt install guix build-essential curl
$ guix pull
```

After the second command ends, it will suggest to add the following two lines to your `$HOME/.profile` file. Do it:

```
# append the following two lines to your $HOME/.profile file:

export GUIX_PROFILE="$HOME/.config/guix/current"
. "$GUIX_PROFILE/etc/profile"
```

Apply the changes by running `source $HOME/.profile`, then run `guix --version`. It will suggest to install one Guix package and add one more line to your `.profile` file:

```shell
$ guix install glibc-locales
```
```
# append the following to $HOME/.profile:

export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
```

Reload your environment again with `source $HOME/.profile`, now `guix --version` should show no warnings.
At this point you can log out and log in again to your user session so that the `.profile` changes are automatically applied to all your shell sessions instead of just the current one.

## Install the MacOS SDK

First download the appropriate `Xcode.xip` file for the version of Bitcoin Knots you want to build.
To be able to download these files you'll need to use a browser that is logged into [Apple's developer portal], otherwise these links won't work.

| Bitcoin Knots Version | XCode Version    | SHA256 Digest                                                      |
|-----------------------|------------------|--------------------------------------------------------------------|
| v28.1.knots20250305   | [Xcode_15.xip]   | `4daaed2ef2253c9661779fa40bfff50655dc7ec45801aba5a39653e7bcdde48e` |
| v27.1.knots20240801   | [Xcode_15.xip]   | `4daaed2ef2253c9661779fa40bfff50655dc7ec45801aba5a39653e7bcdde48e` |
| v26.1.knots20240513   | [Xcode_12.2.xip] | `28d352f8c14a43d9b8a082ac6338dc173cb153f964c6e8fb6ba389e5be528bd0` |

(Note: browse the README.md file from the [`contrib/macdeploy`] directory in Bitcoin Knots at the desired tag version to cross-check this information)

Assuming you downloaded `Xcode_15.xip` into your `$HOME/Downloads` folder, now install the `git` and `cpio` packages,
clone Bitcoin Core's [`apple-sdk-tools`] repository and use its `extract_xcode.py` script and `cpio` to extract the xip archive.

```shell
$ cd $HOME
$ sudo apt install cpio git
$ git clone https://github.com/bitcoin-core/apple-sdk-tools
$ python3 apple-sdk-tools/extract_xcode.py -f Downloads/Xcode_15.xip | cpio -d -i
```

This will create a huge `Xcode.app` folder in your home directory.
Now clone the Bitcoin Knots repository to run another helper script that will take this directory and prepare an "Xcode SDK" from it.
Since we are cloning the Knots repo take the opportunity to check out the specific version you want to build.
In this guide we are building Bitcoin Knots v28.1.knots20250305, so we'll check out the `v28.1.knots20250305` tag.

```shell
$ cd $HOME
$ git clone https://github.com/bitcoinknots/bitcoin knots
$ cd knots
$ git checkout v28.1.knots20250305
$ cd ..
$ ./knots/contrib/macdeploy/gen-sdk $HOME/Xcode.app
Found Xcode (version: 15.0, build id: 15A240d)
Found MacOSX SDK (version: 14.0, build id: 23A334)
Creating output .tar.gz file...
Adding MacOSX SDK 14.0 files...
Done! Find the resulting gzipped tarball at:
/home/you/Xcode-15.0-15A240d-extracted-SDK-with-libcxx-headers.tar.gz
```

The `gen-sdk` command will generate an `Xcode-15.0-15A240d-extracted-SDK-with-libcxx-headers.tar.gz` file in your home directory.
It contains the Apple bits that Bitcoin Knots needs to perform deterministic builds for MacOS.
Now create a dedicated folder in your home directory for MacOS SDKs and extract this .tar.gz in it:

```shell
$ cd $HOME
$ mkdir MacOS-SDKs
$ mv Xcode-15.0-15A240d-extracted-SDK-with-libcxx-headers.tar.gz MacOS-SDKs
$ cd MacOS-SDKs
$ tar zxf Xcode-15.0-15A240d-extracted-SDK-with-libcxx-headers.tar.gz
```

With this folder structure in place we're ready to do Guix MacOS builds.
If you want you can now delete the `XCode.app` directory and the .xip download to reclaim some 70GB of space in your hard drive.
But save the .tar.gz archive file somewhere (only 70MB) and keep it close to your heart in case you ever need it again.

## Build Bitcoin Knots

Start by creating a couple of temporary folders in your home directory that the build process will need to use.

```shell
$ cd $HOME
$ mkdir depends-SOURCES_PATH depends-BASE_CACHE
```

At this stage we're almost ready to start the build proper.
The Guix build is governed by a series of environment variables that we'll now define.
These are needed to locate the directories we just created and the one containing the MacOS SDK.

```shell
$ export SOURCES_PATH="$HOME/depends-SOURCES_PATH"
$ export BASE_CACHE="$HOME/depends-BASE_CACHE"
$ export SDK_PATH="$HOME/MacOS-SDKs"
```

...and we're ready to buidl.

```shell
$ cd $HOME
$ cd knots
$ ./contrib/guix/guix-build
```

A very long and scary build log will start streaming down your shell, and your computer's fans will start going brrr.

Now it's a good time to let your machine do the deed and take a break.

## Attesting the deterministic build with PGP

After the build completes check that it didn't error out:

```shell
$ echo $?
0
```

Then proceed to clone Knots' `bitcoin-detached-sigs` repository to generate a few more build artifacts:

```shell
$ cd $HOME 
$ git clone https://github.com/bitcoinknots/bitcoin-detached-sigs knots-detached-sigs
$ cd knots-detached-sigs
$ git checkout v28.1.knots20250305
$ cd $HOME
$ cd knots
$ env HOSTS='arm64-apple-darwin x86_64-apple-darwin' DETACHED_SIGS_REPO="$HOME/knots-detached-sigs/" ./contrib/guix/guix-codesign
```

At this point you need to fork Knots' [`guix.sigs`] repository into your own GitHub account and clone it.
This is where your attestation result will be saved.

```shell
$ cd $HOME
$ git clone git@github.com:you/guix.sigs
$ cd knots
$ env GUIX_SIGS_REPO="$HOME/guix.sigs" SIGNER=you ./contrib/guix/guix-attest
```

For that last command to work you need to have a PGP key loaded in your local keyring identifiable by that username (`you` in this example).
If that doesn't work you can use the full key ID instead.

If the command succeeds a new directory named `you` (or the key ID) will have been created inside the `guix.sigs/27.1.knots20240801` directory (or the release you built).
You can rename this directory to whatever you like, especially if it has been named after a key ID.

In a successful attestation this directory will contain 4 files: `all.SHA256SUMS`, `all.SHA256SUMS.asc`, `noncodesigned.SHA256SUMS` and `noncodesigned.SHA256SUMS.asc`.
`all.SHA256SUMS` and `noncodesigned.SHA256SUMS` must have identical contents to those of other attestations for the same release.

The following diffs should not show any differences:

```shell
$ cd $HOME
$ cd guix.sigs/27.1.knots20240801
$ diff luke-jr/all.SHA256SUMS you/all.SHA256SUMS
$ diff luke-jr/noncodesigned.SHA256SUMS you/noncodesigned.SHA256SUMS
```

Also, if it's the first time attesting a Knots release you must include an ASCII-armored copy of your PGP public key in the `builder-keys` directory.
This simplifies finding your public key when someone needs to verify your signatures from here on.

The name of the key should match the name of the directory where you stored your attestation (e.g. `guix.sigs/27.1.knots20240801/you`).

```shell
$ gpg --armor --export you > builder-keys/you.gpg
```

If everything looks good you can commit the attestation in a new branch to prepare your submission.

## Submit your attestation

The last step of the process is submitting your attestation to Knots' `guix.sigs` repository.
Commit the local changes in your fork of `guix.sigs` to a new branch and open a PR to the parent repository.
It should look similar to [this one].


## Appendix

I've put this guide together from the following sources:

* Guix binary installation document: [https://guix.gnu.org/manual/en/html_node/Binary-Installation.html](https://guix.gnu.org/manual/en/html_node/Binary-Installation.html)
* Guix README, Bitcoin Knots: [https://github.com/bitcoinknots/bitcoin/tree/28.x-knots/contrib/guix](https://github.com/bitcoinknots/bitcoin/tree/28.x-knots/contrib/guix)
* Guix installation docs, Bitcoin Knots: [https://github.com/bitcoinknots/bitcoin/blob/28.x-knots/contrib/guix/INSTALL.md](https://github.com/bitcoinknots/bitcoin/blob/28.x-knots/contrib/guix/INSTALL.md)
* MacOS SDK extraction guide: [https://github.com/bitcoinknots/bitcoin/tree/28.x-knots/contrib/macdeploy](https://github.com/bitcoinknots/bitcoin/tree/28.x-knots/contrib/macdeploy)


[Bitcoin Knots]: https://github.com/bitcoinknots/bitcoin/
[Knots' website]: https://bitcoinknots.org/
[Apple's developer portal]: https://developer.apple.com/
[Xcode_15.xip]: https://developer.apple.com/services-account/download?path=/Developer_Tools/Xcode_15/Xcode_15.xip
[Xcode_12.2.xip]: https://developer.apple.com/services-account/download?path=/Developer_Tools/Xcode_12.2/Xcode_12.2.xip
[`contrib/macdeploy`]: https://github.com/bitcoinknots/bitcoin/tree/v28.1.knots20250305/contrib/macdeploy
[`apple-sdk-tools`]: https://github.com/bitcoin-core/apple-sdk-tools
[`guix.sigs`]: https://github.com/bitcoinknots/guix.sigs
[this one]: https://github.com/bitcoinknots/guix.sigs/pull/18/files
