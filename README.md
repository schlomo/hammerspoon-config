# hammerspoon-config
My [Hammerspoon](https://www.hammerspoon.org/) Configuration. Influenced from https://github.com/cmsj/hammerspoon-config and others.

## Hacks

I found these hacks worth remembering:

* `defaults write -app Preview PVImagePrintingScaleMode 0` to set the Preview app to scale 100% by default instead of fitting the A4 PDF into the printer margins and thereby downscaling it to 97%.
* `defaults write -g ApplePressAndHoldEnabled -bool false` to enable key repeat with my bluetooth keyboard ([Source](https://www.howtogeek.com/267463/how-to-enable-key-repeating-in-macos/))