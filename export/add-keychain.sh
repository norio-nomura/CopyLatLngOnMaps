#!/bin/sh

[ -z "$KEY_PASSWORD" ] && exit 0

export KEYCHAIN=export.keychain

curl 'https://developer.apple.com/certificationauthority/DeveloperIDCA.cer' -o export/DeveloperIDCA.cer
security create-keychain -p "" $KEYCHAIN
security import export/DeveloperIDCA.cer -k $KEYCHAIN -T /usr/bin/codesign
security import export/DeveloperID.p12 -k $KEYCHAIN -P $KEY_PASSWORD -T /usr/bin/codesign
security default-keychain -s $KEYCHAIN
