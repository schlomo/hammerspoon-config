#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
if ! diskutil quiet unmount A94778BC-09AE-328A-9EF9-FC1E4C79B6D7 ; then
  sleep 30
  diskutil unmount force A94778BC-09AE-328A-9EF9-FC1E4C79B6D7
fi
