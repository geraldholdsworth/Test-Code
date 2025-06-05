#!/bin/sh
#
echo "========================================================"
echo "    Bundle and DMG creation script"
echo "========================================================"
echo "64 bit version"
folder='OneDrive/Programming/Lazarus/DFSFileCleaver'
gitfolder='/./Users/geraldholdsworth/Documents/GitHub/DFSFileCleaver'
appname='DFS File Cleaver'
appfile='DFSFileCleaver'
iconfile='Icon'
if [ -e "$folder" ]
 then
  cd "$folder"
 else
  echo "$folder does not exist"
  exit
fi
#
# Creates the bundle
#
echo "Enter your application version"
read appversion
#
# Ask the user for the icon filename
if ! [ -e "$iconfile.icns" ]
 then
  echo "$iconfile.icns does not exist"
  exit
fi
#
# Application folder name
appfolder="$appname.app"
# If it already exists, remove it
if [ -e "$appfolder" ]
 then
  rm -r "$appfolder"
fi
#
# macOS folder name
macosfolder="$appfolder/Contents/MacOS"
#
# macOS plist filename
plistfile="$appfolder/Contents/Info.plist"
#
# Make sure it exists
if ! [ -e "lib/x86_64-darwin/$appfile" ]
 then
  echo "$appfile does not exist"
  exit
fi

echo "Creating $appfolder..."
mkdir "$appfolder"
mkdir "$appfolder/Contents"
mkdir "$appfolder/Contents/MacOS"
mkdir "$appfolder/Contents/Frameworks"  # optional, for including libraries or frameworks
mkdir "$appfolder/Contents/Resources"

PkgInfoContents="APPLMAG#"

cp "lib/x86_64-darwin/$appfile" "$macosfolder/$appname"

# Copy the resource files to the correct place
cp "$iconfile.icns" "$appfolder/Contents/Resources"
#
# Create PkgInfo file.
echo $PkgInfoContents >"$appfolder/Contents/PkgInfo"
#
# Create information property list file (Info.plist).
echo '<?xml version="1.0" encoding="UTF-8"?>' >"$plistfile"
echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >>"$plistfile"
echo '<plist version="1.0">' >>"$plistfile"
echo '<dict>' >>"$plistfile"
echo '  <key>CFBundleDevelopmentRegion</key>' >>"$plistfile"
echo '  <string>English</string>' >>"$plistfile"
echo '  <key>CFBundleExecutable</key>' >>"$plistfile"
echo '  <string>'$appname'</string>' >>"$plistfile"
echo '  <key>CFBundleIconFile</key>' >>"$plistfile"
echo '  <string>'$iconfile'.icns</string>' >>"$plistfile"
echo '  <key>CFBundleIdentifier</key>' >>"$plistfile"
echo '  <string>com.geraldholdsworth.'$appname'</string>' >>"$plistfile"
echo '  <key>CFBundleInfoDictionaryVersion</key>' >>"$plistfile"
echo '  <string>6.0</string>' >>"$plistfile"
echo '  <key>CFBundlePackageType</key>' >>"$plistfile"
echo '  <string>APPL</string>' >>"$plistfile"
echo '  <key>CFBundleSignature</key>' >>"$plistfile"
echo '  <string>MAG#</string>' >>"$plistfile"
echo '  <key>CFBundleVersion</key>' >>"$plistfile"
echo '  <string>'$appversion'</string>' >>"$plistfile"
echo '</dict>' >>"$plistfile"
echo '</plist>' >>"$plistfile"

echo "Application $appname created"
echo "Creating DMG"
#
# Create DMG
APP=`echo "$appfolder" | sed "s/\.app//"`
DATE=`date "+%d%m%Y"`
VOLUME="${APP}" #_${DATE}"

echo "Application name: ${APP}"
echo "Volume name: ${VOLUME}"

if [ -r "${APP}*.dmg.sparseimage" ]
 then
  rm "${APP}*.dmg.sparseimage"
fi

if [ -e "${VOLUME}.dmg" ]
 then
  rm "${VOLUME}.dmg"
fi

hdiutil create -size 45M -type SPARSE -volname "${VOLUME}" -fs HFS+ "${VOLUME}.dmg"

hdiutil attach "${VOLUME}.dmg.sparseimage"
cp -R "${APP}.app" "/Volumes/${VOLUME}/"
cp README_FIRST.TXT "/Volumes/${VOLUME}/"
hdiutil detach -force "/Volumes/${VOLUME}"

hdiutil convert "${VOLUME}.dmg.sparseimage" -format UDBZ -o "${VOLUME}.dmg" -ov -imagekey zlib-level=9
rm "${VOLUME}.dmg.sparseimage"

#Now we move the files
#
echo "Moving the 64 bit macOS files"
mv -v "$appfolder" "lib/x86_64-darwin/$appfolder"
mv -v "${VOLUME}.dmg" "$gitfolder/binaries/macOS"

# 32 bit version
#
# Creates the bundle
#
echo "32 bit version"

# Make sure it exists
if [ -e "lib/i386-darwin/$appfile" ]
 then

echo "Creating $appfolder..."
mkdir "$appfolder"
mkdir "$appfolder/Contents"
mkdir "$appfolder/Contents/MacOS"
mkdir "$appfolder/Contents/Frameworks"  # optional, for including libraries or frameworks
mkdir "$appfolder/Contents/Resources"

PkgInfoContents="APPLMAG#"

cp "lib/i386-darwin/$appfile" "$macosfolder/$appname"

# Copy the resource files to the correct place
cp "$iconfile.icns" "$appfolder/Contents/Resources"
#
# Create PkgInfo file.
echo $PkgInfoContents >"$appfolder/Contents/PkgInfo"
#
# Create information property list file (Info.plist).
echo '<?xml version="1.0" encoding="UTF-8"?>' >"$plistfile"
echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >>"$plistfile"
echo '<plist version="1.0">' >>"$plistfile"
echo '<dict>' >>"$plistfile"
echo '  <key>CFBundleDevelopmentRegion</key>' >>"$plistfile"
echo '  <string>English</string>' >>"$plistfile"
echo '  <key>CFBundleExecutable</key>' >>"$plistfile"
echo '  <string>'$appname'</string>' >>"$plistfile"
echo '  <key>CFBundleIconFile</key>' >>"$plistfile"
echo '  <string>'$iconfile'.icns</string>' >>"$plistfile"
echo '  <key>CFBundleIdentifier</key>' >>"$plistfile"
echo '  <string>com.geraldholdsworth.'$appname'</string>' >>"$plistfile"
echo '  <key>CFBundleInfoDictionaryVersion</key>' >>"$plistfile"
echo '  <string>6.0</string>' >>"$plistfile"
echo '  <key>CFBundlePackageType</key>' >>"$plistfile"
echo '  <string>APPL</string>' >>"$plistfile"
echo '  <key>CFBundleSignature</key>' >>"$plistfile"
echo '  <string>MAG#</string>' >>"$plistfile"
echo '  <key>CFBundleVersion</key>' >>"$plistfile"
echo '  <string>'$appversion'</string>' >>"$plistfile"
echo '</dict>' >>"$plistfile"
echo '</plist>' >>"$plistfile"

echo "Application $appname created"
echo "Creating DMG"
#
# Create DMG
APP=`echo "$appfolder" | sed "s/\.app//"`
DATE=`date "+%d%m%Y"`
VOLUME="${APP} 32 bit" #_${DATE}"

echo "Application name: ${APP}"
echo "Volume name: ${VOLUME}"

if [ -r "${APP}*.dmg.sparseimage" ]
 then
  rm "${APP}*.dmg.sparseimage"
fi

if [ -e "${VOLUME}.dmg" ]
 then
  rm "${VOLUME}.dmg"
fi

hdiutil create -size 45M -type SPARSE -volname "${VOLUME}" -fs HFS+ "${VOLUME}.dmg"

hdiutil attach "${VOLUME}.dmg.sparseimage"
cp -R "${APP}.app" "/Volumes/${VOLUME}/"
cp README_FIRST.TXT "/Volumes/${VOLUME}/"
hdiutil detach -force "/Volumes/${VOLUME}"

hdiutil convert "${VOLUME}.dmg.sparseimage" -format UDBZ -o "${VOLUME}.dmg" -ov -imagekey zlib-level=9
rm "${VOLUME}.dmg.sparseimage"
fi

#Now we move the files
#
echo "Moving the 32 bit macOS files"
mv -v "$appfolder" "lib/i386-darwin/$appfolder"
mv -v "${VOLUME}.dmg" "$gitfolder/binaries/macOS"

# Zip up the other binaries
#
echo "Creating and moving ZIP files"
# 64 bit Linux
#
echo "Linux 64 bit"
if [ -e "lib/x86_64-linux/$appname.zip" ]
 then
  rm "lib/x86_64-linux/$appname.zip"
fi
if [ -e "lib/x86_64-linux/$appfile" ]
 then
  zip "lib/x86_64-linux/$appname.zip" "lib/x86_64-linux/$appfile"
  mv -v "lib/x86_64-linux/$appname.zip" "$gitfolder/binaries/Linux"
fi
# 32 bit Linux
#
echo "Linux 32 bit"
if [ -e "lib/i386-linux/$appname 32 bit.zip" ]
 then
  rm "lib/i386-linux/$appname 32 bit.zip"
fi
if [ -e "lib/i386-linux/$appfile" ]
 then
  zip "lib/i386-linux/$appname 32 bit.zip" "lib/i386-linux/$appfile"
  mv -v "lib/i386-linux/$appname 32 bit.zip" "$gitfolder/binaries/Linux"
fi
# 32 bit ARM Linux
#
echo "Linux 32 bit ARM"
if [ -e "lib/arm-linux/$appname ARM 32 bit.zip" ]
 then
  rm -v "lib/arm-linux/$appname ARM 32 bit.zip"
fi
if [ -e "lib/arm-linux/$appfile" ]
 then
  zip "lib/arm-linux/$appname ARM 32 bit.zip" "lib/arm-linux/$appfile"
  mv -v "lib/arm-linux/$appname ARM 32 bit.zip" "$gitfolder/binaries/Linux"
fi
# 64 bit Windows
#
echo "Windows 64 bit"
if [ -e "lib/x86_64-win64/$appname.zip" ]
 then
  rm "lib/x86_64-win64/$appname.zip"
fi
if [ -e "lib/x86_64-win64/$appfile.exe" ]
 then
  zip "lib/x86_64-win64/$appname.zip" "lib/x86_64-win64/$appfile.exe"
  mv -v "lib/x86_64-win64/$appname.zip" "$gitfolder/binaries/Windows"
fi
# 32 bit Windows
#
echo "Windows 32 bit"
if [ -e "lib/i386-win32/$appname 32 bit.zip" ]
 then
  rm "lib/i386-win32/$appname 32 bit.zip"
fi
if [ -e "lib/i386-win32/$appfile.exe" ]
 then
  zip "lib/i386-win32/$appname 32 bit.zip" "lib/i386-win32/$appfile.exe"
  mv -v "lib/i386-win32/$appname 32 bit.zip" "$gitfolder/binaries/Windows"
fi
# Now copy the source files to GIT
#
echo "Copying source files to GIT"
cp -v *\.pas "$gitfolder/LazarusSource"
cp -v *\.lfm "$gitfolder/LazarusSource"
cp -v "$appfile.lpi" "$gitfolder/LazarusSource"
cp -v "$appfile.lpr" "$gitfolder/LazarusSource"
cp -v "$appfile.lps" "$gitfolder/LazarusSource"
cp -v "$appfile.res" "$gitfolder/LazarusSource"
cp -v -R "Graphics" "$gitfolder"
