#!/bin/bash
tempfoo=`basename $0`
TMPDIR=`mktemp -d -t ${tempfoo}.XXXXXX` || exit 1
qpdf --stream-data=uncompress "$1" $TMPDIR/uncompressed.pdf
gsed -e 's/0 -22.5 131.05 0/0 -22.5 0      0/' $TMPDIR/uncompressed.pdf >$TMPDIR/patched.pdf
qpdf --stream-data=compress $TMPDIR/patched.pdf "$1"
rm -Rfv $TMPDIR
