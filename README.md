# hammerspoon-config

My [Hammerspoon](https://www.hammerspoon.org/) Configuration. Influenced from <https://github.com/cmsj/hammerspoon-config> and others.

## Configuraton checklist

* System emails: Run `postconf` from `gss-all` `postinst` followed by `postconf -e smtp_tls_CAfile=/etc/ssl/cert.pem` for the different cert bundle path

## Hacks & Links

I found these hacks worth remembering:

* `defaults write -app Preview PVImagePrintingScaleMode 0` to set the Preview app to scale 100% by default instead of fitting the A4 PDF into the printer margins and thereby downscaling it to 97%.
* `defaults write -g ApplePressAndHoldEnabled -bool false` to enable key repeat with my bluetooth keyboard ([Source](https://www.howtogeek.com/267463/how-to-enable-key-repeating-in-macos/))
* [Time Machine Editor](https://tclementdev.com/timemachineeditor/) to limit backups to run at night
* [Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) from app store and <https://github.com/x74353/Amphetamine-Enhancer>
* [Use local directory for GnuPG sockets](https://wiki.archlinux.org/index.php/GnuPG#IPC_connect_call_failed) to allow storing GnuPG homedir elsewhere
* [Webcam Settings](https://apps.apple.com/app/webcam-settings/id533696630)
* [Color Slurp](https://apps.apple.com/de/app/colorslurp/id1287239339)
* [noTunes](https://github.com/tombonez/noTunes) to disable iTunes & Apple Music, `brew install --cask notunes`
* [Clock Screen Saver](https://github.com/soffes/Clock.saver) to show a clock while in meetings. `brew install clock-saver`
* [mos](https://mos.caldis.me/) to reverse the scroll direction for the mouse only. `brew install mos`
* [Open in Profile](https://hikmetcancelik.com/open-in-profile/) to automatically open work related links in the work Chrome profile
* [Shottr](https://shottr.cc/) for screenshots with annotations. `brew install shottr` and I paid for the licence
* [LensOCR](https://apps.apple.com/de/app/lensocr-extract-text-image/id1549961729) for screen OCR, QR/barcode (paid)
* [Fish Shell](https://fishshell.com/) has nice UI & completions. `brew install fish`
  * <https://github.com/jorgebucaran/fisher>
  * `fisher install ilancosman/tide@v6 lgathy/google-cloud-sdk-fish-completion FabioAntunes/fish-nvm edc/bass`
* [zClock](https://apps.apple.com/de/app/zclock-clock-countdown/id1478540997) overlay desktop clock (paid)
* [t2m Timer](https://apps.apple.com/de/app/t2m-timer/id1487946377) countdown timer
* [Hand Mirror](https://apps.apple.com/de/app/hand-mirror/id1502839586) webcam check
* [QR Journal](https://apps.apple.com/de/app/qr-journal/id483820530) QR scanner for screen and camera
* [MenuMeters](https://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/) show monitoring data in menu bar. `brew install menumeters`
* [ZoomHider](https://lowtechguys.com/zoomhider/) to hide the Zoom screen sharing controls
* [BetterDisplay Pro](https://betterdisplay.pro/) to control screen resolution and brightness, add dummy screens and more. `brew install
betterdisplay` and I paid for licence
* [coconutBattery](https://www.coconut-flavour.com/coconutbattery/) to show detailed battery charging infos. `brew install coconutbattery`
* [pdfGear](https://www.pdfgear.com/) for free but simple PDF editing, filling, signing.

---
*older stuff*:

* [QR Capture](https://apps.apple.com/de/app/qr-capture/id1369524274) QR scanner for screen and camera
* [Display Menu](https://apps.apple.com/de/app/display-menu/id549083868)
* [MonitorControl](https://github.com/MonitorControl/MonitorControl) to manage screen brightness and sync internal/external screen settings. `brew install monitorcontrol`
* [Virtual Camera Missing After Microsoft Teams Update](https://support.ecamm.com/en/articles/4343963-virtual-camera-missing-after-microsoft-teams-update)
* [Pock](https://pock.dev/) to show the dock on the touchbar. `brew install pock`

## Configs

### Bash

goes into `~/.bash_profile`:

```shell
eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

alias ll="ls -lGF"

# https://stackoverflow.com/questions/23620827/envsubst-command-not-found-on-mac-os-x-10-8
alias envsubst=/usr/local/opt/gettext/bin/envsubst

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

alias vncviewer='/Applications/TigerVNC\ Viewer\ 1.9.0.app/Contents/MacOS/TigerVNC\ Viewer'

source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"

# from https://github.com/mozilla/sops/issues/304
GPG_TTY=$(tty)
export GPG_TTY

export VISUAL="code -nw"

function youtube-watch {
    open "$(youtube-dl -g "$1")"
}

function webcam {
    ffplay -v error  -f avfoundation -framerate 30 -video_size 1280x720 -pixel_format uyvy422 -fflags nobuffer -an -video_device_index ${1:-0} -i desk
}

source <(kubectl completion bash)
alias k=kubectl
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# https://github.com/phiresky/ripgrep-all
rga-fzf() {
 RG_PREFIX="rga --files-with-matches"
 local file
 file="$(
  FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
   fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
    --phony -q "$1" \
    --bind "change:reload:$RG_PREFIX {q}" \
    --preview-window="70%:wrap"
 )" &&
 echo "opening $file" &&
 open "$file"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# https://cloud.google.com/iap/docs/using-tcp-forwarding#increasing_the_tcp_upload_bandwidth
export CLOUDSDK_PYTHON_SITEPACKAGES=1

function jwt { jq -R 'split(".",.)[] | try @base64d | fromjson' ; }

```

### Fish

goes into `~/.config/fish/config.fish`:

```fish
fish_add_path /opt/homebrew/sbin /opt/homebrew/bin

source /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc

if status is-interactive
    # Commands to run in interactive sessions can go here
    test -e {$HOME}/.iterm2_shell_integration.fish; and source {$HOME}/.iterm2_shell_integration.fish
end

```

### Git

goes into `~/.gitconfig`:

```toml
# This is Git's per-user configuration file.
[user]
  name = Schlomo Schapiro
  email = XXXX

[core]
  quotepath = false
  excludesfile = /Users/schlomoschapiro/.gitignore_global

[push]
  followTags = true
  autoSetupRemote = true

[pull]
  rebase = true

[includeIf "gitdir:~/XXXX/"]
  path = ~/XXXX/.gitconfig

[filter "lfs"]
  required = true
  clean = git-lfs clean -- %f
  smudge = git-lfs smudge -- %f
  process = git-lfs filter-process

[init]
  defaultBranch = main

[diff "sopsdiffer"]
  textconv = sops -d --config /dev/null

[sendpack]
  sideband = false

[tig "bind"]
    main = = !git commit --fixup=%(commit)
    main = <Ctrl-r> !git rebase --autosquash -i %(commit)

[commit]
  template = /Users/schlomoschapiro/.stCommitMsg

```
