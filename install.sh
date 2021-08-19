#!/bin/bash
swift build -c release

if [[ `uname -m` == 'arm64' ]]; then
  file="/opt/homebrew/bin/slox"
  if [ -f "$file" ] ; then rm "$file"; fi
  cp .build/release/slox $file
else
   cp .build/release/slox /usr/local/bin/slox
fi
echo "slox was installed. Run 'slox --version' and try it out"
