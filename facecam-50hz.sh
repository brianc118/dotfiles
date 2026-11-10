#!/bin/bash
# Force Elgato Facecam anti-flicker (UVC power-line-frequency) to 50Hz.
# The Facecam forgets this on every USB power cycle (replug, logout, reboot),
# and "Save" in Camera Hub doesn't persist it.
#
#   ./facecam-50hz.sh              set 50Hz now
#   ./facecam-50hz.sh --install    re-apply automatically every 15s (LaunchAgent)
#   ./facecam-50hz.sh --uninstall  remove the LaunchAgent
#
# Needs only clang (Xcode Command Line Tools). HZ=60 or HZ=0 (off) to override.
set -euo pipefail

SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
LABEL="com.$(id -un).facecam-50hz"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
CACHE="$HOME/Library/Caches/facecam-50hz"
BIN="$CACHE/plf"

case "${1:-}" in
  --install)
    cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$SELF</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>15</integer>
  <key>StandardOutPath</key><string>/tmp/facecam-50hz.log</string>
  <key>StandardErrorPath</key><string>/tmp/facecam-50hz.log</string>
</dict>
</plist>
EOF
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$PLIST"
    echo "Installed $PLIST (log: /tmp/facecam-50hz.log)"
    exit 0 ;;
  --uninstall)
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    rm -f "$PLIST"
    echo "Removed $PLIST"
    exit 0 ;;
esac

case "${HZ:-50}" in 0) WANT=0 ;; 50) WANT=1 ;; 60) WANT=2 ;; *) echo "HZ must be 0, 50 or 60" >&2; exit 2 ;; esac

# Compile the embedded helper once (and again whenever this script changes).
if [[ ! -x "$BIN" || "$SELF" -nt "$BIN" ]]; then
  mkdir -p "$CACHE"
  sed -n '/^#__C_BEGIN__$/,$p' "$SELF" | tail -n +2 > "$CACHE/plf.c"
  clang -O2 -o "$BIN" "$CACHE/plf.c" -framework IOKit -framework CoreFoundation
fi

cur=$("$BIN" get) || exit 0   # camera not connected
if [[ "$cur" != "$WANT" ]]; then
  "$BIN" set "$WANT"
  echo "$(date '+%F %T') power-line-frequency $cur -> $("$BIN" get)"
elif [[ -t 1 ]]; then
  echo "Already set (power-line-frequency=$cur)"
fi
exit 0

#__C_BEGIN__
// Get/set UVC Processing Unit POWER_LINE_FREQUENCY on the Elgato Facecam.
// Values: 0 = disabled, 1 = 50Hz, 2 = 60Hz.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

#define VID 0x0fd9
#define PID 0x0078
#define CS_INTERFACE 0x24
#define VC_HEADER 0x01
#define VC_PROCESSING_UNIT 0x05
#define PU_POWER_LINE_FREQUENCY_CONTROL 0x05
#define SET_CUR 0x01
#define GET_CUR 0x81

static int num(io_service_t s, const char *key) {
  CFStringRef k = CFStringCreateWithCString(NULL, key, kCFStringEncodingUTF8);
  CFTypeRef v = IORegistryEntryCreateCFProperty(s, k, NULL, 0);
  CFRelease(k);
  int n = -1;
  if (v && CFGetTypeID(v) == CFNumberGetTypeID()) CFNumberGetValue(v, kCFNumberIntType, &n);
  if (v) CFRelease(v);
  return n;
}

int main(int argc, char **argv) {
  int set = argc == 3 && !strcmp(argv[1], "set");
  if (!set && !(argc == 2 && !strcmp(argv[1], "get"))) {
    fprintf(stderr, "usage: %s get | set <0|1|2>\n", argv[0]);
    return 2;
  }

  // Find the Facecam's VideoControl interface (class 14, subclass 1).
  io_iterator_t it;
  if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostInterface"), &it)) return 1;
  io_service_t svc, found = 0;
  while ((svc = IOIteratorNext(it))) {
    if (!found && num(svc, "idVendor") == VID && num(svc, "idProduct") == PID &&
        num(svc, "bInterfaceClass") == 14 && num(svc, "bInterfaceSubClass") == 1)
      found = svc;
    else
      IOObjectRelease(svc);
  }
  IOObjectRelease(it);
  if (!found) { fprintf(stderr, "Facecam not found\n"); return 1; }

  IOCFPlugInInterface **plug = NULL;
  SInt32 score;
  IOUSBInterfaceInterface300 **intf = NULL;
  if (IOCreatePlugInInterfaceForService(found, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &plug, &score) || !plug)
    return 1;
  (*plug)->QueryInterface(plug, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID300), (LPVOID *)&intf);
  (*plug)->Release(plug);
  if (!intf) return 1;

  UInt8 ifnum = 0;
  (*intf)->GetInterfaceNumber(intf, &ifnum);

  // Walk the class-specific VC descriptors to find the Processing Unit ID.
  int unit = -1;
  UInt8 *hdr = (UInt8 *)(*intf)->FindNextAssociatedDescriptor(intf, NULL, CS_INTERFACE);
  if (hdr && hdr[2] == VC_HEADER) {
    UInt8 *p = hdr + hdr[0], *end = hdr + (hdr[5] | hdr[6] << 8);
    for (; p < end && p[0]; p += p[0])
      if (p[1] == CS_INTERFACE && p[2] == VC_PROCESSING_UNIT) { unit = p[3]; break; }
  }
  if (unit < 0) { fprintf(stderr, "no processing unit\n"); return 1; }

  IOReturn rc = (*intf)->USBInterfaceOpen(intf);
  int opened = rc == kIOReturnSuccess;

  UInt8 val = set ? (UInt8)atoi(argv[2]) : 0;
  IOUSBDevRequest req = {
    .bmRequestType = set ? 0x21 : 0xA1,
    .bRequest = set ? SET_CUR : GET_CUR,
    .wValue = PU_POWER_LINE_FREQUENCY_CONTROL << 8,
    .wIndex = (UInt16)(unit << 8 | ifnum),
    .wLength = 1,
    .pData = &val,
  };
  rc = (*intf)->ControlRequest(intf, 0, &req);
  if (opened) (*intf)->USBInterfaceClose(intf);
  (*intf)->Release(intf);
  IOObjectRelease(found);

  if (rc) { fprintf(stderr, "control request failed: 0x%x\n", rc); return 1; }
  if (!set) printf("%u\n", val);
  return 0;
}
