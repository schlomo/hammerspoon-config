# hammerspoon-config
My [Hammerspoon](https://www.hammerspoon.org/) Configuration. Influenced from https://github.com/cmsj/hammerspoon-config and others.

## Configuraton checklist

* System emails: Run `postconf` from `gss-all` `postinst` followed by `postconf -e smtp_tls_CAfile=/etc/ssl/cert.pem` for the different cert bundle path


## Hacks & Links

I found these hacks worth remembering:

* `defaults write -app Preview PVImagePrintingScaleMode 0` to set the Preview app to scale 100% by default instead of fitting the A4 PDF into the printer margins and thereby downscaling it to 97%.
* `defaults write -g ApplePressAndHoldEnabled -bool false` to enable key repeat with my bluetooth keyboard ([Source](https://www.howtogeek.com/267463/how-to-enable-key-repeating-in-macos/))
* https://tclementdev.com/timemachineeditor/ to limit backups to run at night
* Amphetamine from app store and https://github.com/x74353/Amphetamine-Enhancer
* [Virtual Camera Missing After Microsoft Teams Update](https://support.ecamm.com/en/articles/4343963-virtual-camera-missing-after-microsoft-teams-update)
* [Use local directory for GnuPG sockets](https://wiki.archlinux.org/index.php/GnuPG#IPC_connect_call_failed) to allow storing GnuPG homedir elsewhere
* [Webcam Settings](https://apps.apple.com/app/webcam-settings/id533696630)
* [Display Menu](https://apps.apple.com/de/app/display-menu/id549083868)
* [Color Slurp](https://apps.apple.com/de/app/colorslurp/id1287239339)

Missing / Discontinued:
* [Annotate](https://www.macupdate.com/app/mac/48844/annotate), 