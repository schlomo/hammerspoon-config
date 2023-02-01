# hammerspoon-config
My [Hammerspoon](https://www.hammerspoon.org/) Configuration. Influenced from https://github.com/cmsj/hammerspoon-config and others.

## Configuraton checklist

* System emails: Run `postconf` from `gss-all` `postinst` followed by `postconf -e smtp_tls_CAfile=/etc/ssl/cert.pem` for the different cert bundle path

## Hacks & Links

I found these hacks worth remembering:

* `defaults write -app Preview PVImagePrintingScaleMode 0` to set the Preview app to scale 100% by default instead of fitting the A4 PDF into the printer margins and thereby downscaling it to 97%.
* `defaults write -g ApplePressAndHoldEnabled -bool false` to enable key repeat with my bluetooth keyboard ([Source](https://www.howtogeek.com/267463/how-to-enable-key-repeating-in-macos/))
* [Time Machine Editor](https://tclementdev.com/timemachineeditor/) to limit backups to run at night
* [Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) from app store and https://github.com/x74353/Amphetamine-Enhancer
* [Use local directory for GnuPG sockets](https://wiki.archlinux.org/index.php/GnuPG#IPC_connect_call_failed) to allow storing GnuPG homedir elsewhere
* [Webcam Settings](https://apps.apple.com/app/webcam-settings/id533696630)
* [Color Slurp](https://apps.apple.com/de/app/colorslurp/id1287239339)
* [noTunes](https://github.com/tombonez/noTunes) to disable iTunes & Apple Music, `brew install --cask notunes`
* [Clock Screen Saver](https://github.com/soffes/Clock.saver) to show a clock while in meetings. `brew install clock-saver` failed with a checksum mismatch, had to compile myself via XCode
* [mos](https://mos.caldis.me/) to reverse the scroll direction for the mouse only. `brew install mos`
* [Open in Profile](https://hikmetcancelik.com/open-in-profile/) to automatically open work related links in the work Chrome profile
* [Shottr](https://shottr.cc/) for screenshots with annotations. `brew install shottr`
* [LensOCR](https://apps.apple.com/de/app/lensocr-extract-text-image/id1549961729) for screen OCR, QR/barcode (paid)
* [Fish Shell](https://fishshell.com/) has nice UI & completions. `brew install fish`
  * <https://github.com/jorgebucaran/fisher>
  * `fisher install ilancosman/tide@v5 lgathy/google-cloud-sdk-fish-completion FabioAntunes/fish-nvm edc/bass`
* [zClock](https://apps.apple.com/de/app/zclock-clock-countdown/id1478540997) overlay desktop clock (paid)
* [t2m Timer](https://apps.apple.com/de/app/t2m-timer/id1487946377) countdown timer
* [Hand Mirror](https://apps.apple.com/de/app/hand-mirror/id1502839586) webcam check
* [QR Journal](https://apps.apple.com/de/app/qr-journal/id483820530) QR scanner for screen and camera
* [MenuMeters](https://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/) show monitoring data in menu bar. `brew install menumeters`
* [ZoomHider](https://lowtechguys.com/zoomhider/) to hide the Zoom screen sharing controls
* [BetterDisplay Pro](https://betterdisplay.pro/) to control screen resolution and brightness, add dummy screens and more. `brew install 
betterdisplay` and paid license

---

* [QR Capture](https://apps.apple.com/de/app/qr-capture/id1369524274) QR scanner for screen and camera
* [Display Menu](https://apps.apple.com/de/app/display-menu/id549083868)
* [MonitorControl](https://github.com/MonitorControl/MonitorControl) to manage screen brightness and sync internal/external screen settings. `brew install monitorcontrol`
* [Virtual Camera Missing After Microsoft Teams Update](https://support.ecamm.com/en/articles/4343963-virtual-camera-missing-after-microsoft-teams-update)

