#!/bin/bash
#
# Creates a self-signed code signing certificate in the login keychain and leaves it
# there for build_app.sh to use. Run once per machine.
#
# Why this exists
# ---------------
# Keychain ACLs and TCC (Accessibility) permissions bind to an app's *designated
# requirement*. Ad-hoc signing (`codesign --sign -`) produces:
#
#     designated => cdhash H"8c6a3164..."
#
# The cdhash is a hash of the built code, so it changes on every rebuild. macOS then
# sees a different app each time: it re-prompts for the login keychain password and
# Accessibility access has to be granted again. "Always Allow" never sticks.
#
# Signing with a certificate produces:
#
#     designated => identifier "com.pilwonhur.MacIntelligence" and certificate root = H"4544..."
#
# Both halves are stable across rebuilds, so permissions granted once stay granted.
#
# This certificate is for local permission stability only. It is not from Apple, so it
# does nothing for Gatekeeper or for distributing the app to anyone else.

set -euo pipefail

IDENTITY="Mac Intelligence Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
    echo "✅ '$IDENTITY' already exists in the login keychain — nothing to do."
    echo "   To replace it, delete it in Keychain Access and run this again."
    exit 0
fi

WORK="$(mktemp -d)"
# The private key must never outlive this script: it is imported into the keychain,
# and the copy on disk is a liability.
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/openssl.cnf" <<'CNF'
[ req ]
distinguished_name = dn
prompt             = no
x509_extensions    = codesign_ext

[ dn ]
CN = Mac Intelligence Local Signing
O  = Pilwon Hur
C  = KR

[ codesign_ext ]
basicConstraints     = critical, CA:false
keyUsage             = critical, digitalSignature
extendedKeyUsage     = critical, codeSigning
subjectKeyIdentifier = hash
CNF

echo "🔑 Generating a 20-year self-signed code signing certificate..."
# The extensions come from the config file rather than -addext: with -x509, -addext
# basicConstraints is *added to* the implicit CA:TRUE rather than replacing it, which
# produces a certificate with duplicate critical extensions.
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" \
    -days 7300 -config "$WORK/openssl.cnf" 2>/dev/null

# macOS's PKCS#12 reader rejects OpenSSL 3's defaults ("MAC verification failed"),
# so pin the legacy algorithms it understands.
PKCS12_ARGS=(-macalg sha1 -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES)
if openssl version | grep -q "OpenSSL 3"; then
    PKCS12_ARGS+=(-legacy)
fi

PASS="$(openssl rand -hex 16)"
openssl pkcs12 -export -out "$WORK/cert.p12" \
    -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
    -name "$IDENTITY" "${PKCS12_ARGS[@]}" -passout "pass:$PASS" 2>/dev/null

echo "📥 Importing into the login keychain..."
# -T grants codesign access without a prompt on every build. No trust settings are
# needed: codesign locates the identity in the keychain directly, so this never asks
# for an administrator password.
security import "$WORK/cert.p12" -k "$KEYCHAIN" -P "$PASS" \
    -T /usr/bin/codesign -T /usr/bin/security >/dev/null

echo
echo "✅ Done. './build_app.sh' will now sign with '$IDENTITY'."
echo
echo "⚠️  The identity changes once, right now, so on the next launch macOS will ask"
echo "   one final time to:"
echo "     • allow keychain access  → click \"Always Allow\" (it will stick from now on)"
echo "     • re-grant Accessibility → System Settings ▸ Privacy & Security ▸ Accessibility"
echo "   Remove the old entry there and re-add the rebuilt app."
