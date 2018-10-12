![alm-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![alm-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![alm-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/Application-Launch-Monitor--ALM-/blob/master/LICENSE)

# ALM – Application Launch Monitor (shell script version) <img src="https://github.com/JayBrown/Application-Launch-Monitor--ALM-/tree/master/img/jb-img.png" height="20px"/>

**ALM is a small Objective-C `NSWorkspace` listener combined with a (bigger) shell script; it extends macOS Gatekeeper protection by monitoring and intercepting every application launch, while re-evaluating the application's security and integrity.**

**ALM** is still in beta, so there will surely be some erros or bugs, and it will have to undergo a lot of testing before any final release. Testing is currently done on macOS High Sierra (10.13.6), and will continue on Mojave later in 2018.

Background: Reed T. Talk at *Virus Bulletin 2018*. Malwarebytes. 3 October 2018. Montreal. In: Seals T. 2018. ["Virus Bulletin 2018: macOS Flaw Allows Attackers to Hijack Installed Apps"](https://threatpost.com/virus-bulletin-2018-macos-flaw-allows-attackers-to-hijack-installed-apps/137942/). *Threatpost: Security News Service*. 3 October 2018. Woburn.

> The way Apple handles [the Gatekeeper] process has a hole in it. Apps are essentially quarantined when they're downloaded by a Mac user; any executable is given an initial caution flag. The system then checks the code signature, and makes sure the application is not a known piece of malware. If it passes, the app is given clearance on the machine as a piece of trusted software. That's where the issue lies. At that point, macOS stops checking that application, once the quarantine flag is wiped out. […] That means that malefactors can infect almost any application already running on the machine […].

As an alternative, you might also want to take a look at the beta version of Google's upcoming **[Santa](https://github.com/google/santa)** security software. I haven't yet tested it, but it looks very promising.

To initially scan application bundles after download or installation, you can also use the separate [**wys** shell script](https://github.com/JayBrown/wys-WhatsYourSign-shell-script-version) with additional functionality like validations of checksums and GPG signatures, embedded anti-malware scans using clamav/ClamXAV and VirusTotal, support for installer package signatures, quarantine checks etc.

## ALM Features
* The listener interrupts every application launch with `SIGSTOP`, and sends the application info (bundle ID, filepath, application name, and process ID) to the shell script.
* The shell script re-evaluates the application bundle, i.a. by
  * verifying the code signature integrity (deep scan with `codesign`),
  * comparing the SHA-256 hashes of the main executable,
  * running a qualitative assessment in relation to the whitelist status (*see below*),
  * checking for unsigned or ad-hoc-signed bundles or bundles signed with old Apple developer certificates,
  * specifically checking for `anchor apple` in the signature requirements,
  * detecting when the subject key identifier (SKID) embedded in the code signing certificate has changed,
  * validating the code signing certificate itself (with `security`), not only the bundle's code signature,
  * comparing the bundle ID in the `Info.plist` with those in the code signing certificate (signature),
  * checking for Team IDs in the code signature, and
  * detecting when the filepath or application name has changed.
* **ALM** auto-whitelists applications that pass all tests (setting `1`); if there are errors, a prompt is displayed, and the user has to choose how to proceed; the options are:
  * **whitelist** the application manually (setting `2`), e.g. for applications that are unsigned like **VirtualC64** or self-signed like **Skim** (*see below*; screengrabs);
  * **launch once** or **abort launch** (setting `0` = not whitelisted).
* For later comparison **ALM** saves the following information in an sqlite database: the bundle ID in the `Info.plist`, the absolute filepath, the application name, the Team ID from the code signature, the code signing anchor, the code signing certificate's subject key identifier, the bundle ID embedded in the code signature, the certificate's team identifier, the SHA-256 hash of the main executable, the whitelist status, the `codesign` validation results, and the certificate's `security` validation results.
* You can blacklist previously whitelisted applications (i.e. remove them from the **ALM** database) by running the `almonwatch` shell script directly with options (*see below*).
* You can perform an additional scan independent of ALM: if you copy a script called `run` into `/Library/Application\ Support/ALM/bin`, **ALM** will execute it while passing the original `NSWorkspace` notification (including process ID) plus additional arguments: (a) the whitelisting status as arguments, and (b): hash change information (modified/updated executable).

## Installation
* Clone repository & `cd` into repo
* `gcc -Wall almon.m -o almon -lobjc -framework Cocoa`
  * alternative: use prebuilt CLI `almon` (built with Xcode 10 on macOS 10.13.6)
* `sudo chown root:wheel almon && sudo chmod +ux almon && ln -s almon /usr/local/bin/almon``
* `sudo chown root:wheel almonwatch && sudo chmod +ux almonwatch && ln -s almonwatch /usr/local/bin/almonwatch`
* `sudo cp local.lcars.ALM.plist /Library/LaunchDaemons/local.lcars.ALM.plist`
* `sudo chown root:wheel /Library/LaunchDaemons/local.lcars.ALM.plist`
* `sudo launchctl load /Library/LaunchDameons/local.lcars.ALM.plist`

Please note that when building `almon` with **Xcode 10** or the associated **Developer Tools** on High Sierra, you will probably run into `ld` warnings; you can safely ignore them.

### Notes
* ***ALM** does not (yet?) work for background applications, e.g. menu bar apps.
* **ALM** runs as a LaunchAgent owned by root; if you `chown` the associated files as `root:wheel` (*see above*), the daemon, its files, and the sqlite database it creates in `/Library/Application\ Support/ALM` are safe against tampering without root escalation.
* On a modern Mac with fast processors and SSDs, you will only notice a small delay in application launches when dealing with larger bundles, e.g. Electron "apps"; on older Macs the eval scans will take a little longer.
  * Scans of extremely large bundles (more than 5 GB) will take too long even on modern Macs, so **ALM** is currently skipping `codesign` re-evaluation for **Xcode**, if the executable hasn't been modified/updated.
* The **ALM** database only ever stores the current version of an application; information on previous versions will be overwritten automatically.
* If you have two copies of the same application on your volume, you might run into **ALM** error prompts; please change one of the two applications' bundle IDs to avoid confusion.

## Command Line Options
Remove applications from the ALM whitelist by executing

* `sudo almonwatch blacklist name <Application Name>`, or
* `sudo almonwatch blacklist id <Application Bundle ID>`, or
* `sudo almonwatch blacklist path <Path to Application>`

Please note that blacklisting does not work with applications that have been auto-whitelisted; they will be auto-whitelisted again at their next launch.

## Uninstall
* `sudo launchctl unload local.lcars.ALM`
* `sudo killall almon`
* `sudo killall almonwatch`
* `sudo rm -f /Library/LaunchDaemons/local.lcars.ALM.plist /usr/local/bin/almon /usr/local/bin/almonwatch`
* `sudo rm -rf /Library/Application\ Support/ALM`

## Beta status
* still needs general and extensive real-world testing, lots of testing
* support for background applications etc. (if possible/feasible)
* find a solution for super-large bundles

## Screengrabs
![alm-screengrab-virtualc64](https://github.com/JayBrown/Application-Launch-Monitor--ALM-/tree/master/img/screengrab-VirtualC64.jpg)

![alm-screengrab-skim4](https://github.com/JayBrown/Application-Launch-Monitor--ALM-/tree/master/img/screengrab-Skim.jpg)
