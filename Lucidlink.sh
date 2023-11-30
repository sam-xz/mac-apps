#!/bin/bash

# Variables
APP="Lucid"
ICNS="AppIcon"
URL="https://www.lucidlink.com/download/latest/osx/stable/"
DL_EXT="pkg"

/Applications/Lucid.app/Contents/Resources/Lucid exit
sleep 30
# Get installed version
if [[ -d /Applications/"$APP".app ]]; then
    InstalledVersion=`defaults read /Applications/"$APP".app/Contents/Info CFBundleShortVersionString | sed -e 's/0 //g' -e 's/(//g' -e 's/)//g'`
else
    InstalledVersion="Not installed"
fi
echo "[CHECK] Installed version: $InstalledVersion"
echo "[CHECK] Latest version: $LatestVersion"

# Update if required
if [[ $LatestVersion == "$InstalledVersion" ]]; then
	echo [FINISH] Latest version already installed, alerting user...
	AlreadyInstalled=$(osascript << EOF
	
	set theDialogText to "Latest version of $APP already installed."

    	display dialog theDialogText buttons {"OK"} default button 1 giving up after 5 with icon file "Applications:$APP.app:Contents:Resources:$ICNS.icns"
EOF
)
else

# Quit and delete installed version if installed
	if [[ -d "/Applications/$APP.app" ]]; then
		echo "[UNINSTALL] Removing currently installed version..."
		osascript -e 'quit app '\"$APP\"
		rm -rf "/Applications/$APP.app"
	fi
	
# Let's do this in tmp
	mkdir "/private/tmp/Jamf Install"
	cd "/private/tmp/Jamf Install"

# Download latest
	echo "[INSTALL] Downloading latest..."
	curl --silent -L -o "$APP".$DL_EXT "$URL"

# What file have we downloaded?
	INSTALLER=$(ls)

#if .pkg, install
	if [[ $INSTALLER == *".pkg" ]]; then
		echo "[INSTALL] Installing..."
		installer -pkg "$APP".$DL_EXT -target /
	fi

# If .zip, unzip and update INSTALLER variable
	if [[ $INSTALLER == *".zip" ]]; then
		echo "[INSTALL] Unzipping..."
		unzip -q "$INSTALLER"
		rm -f "$INSTALLER"
		INSTALLER=$(ls)
		echo $INSTALLER
	fi

# If .app, copy to Applications
	if [[ $INSTALLER == *".app"* ]]; then
		echo "[INSTALL] Copying to Applications..."
		rsync -az "$APP.app/" "/Applications/$APP.app"

# If .dmg, mount it...
	elif [[ $INSTALLER == *".dmg" ]]; then
		echo "[INSTALL] Mounting DMG..."
		mountResult=`/usr/bin/hdiutil mount -private -noautoopen -noverify "$INSTALLER"`
		mountVolume=`echo "$mountResult" | grep Volumes | awk -F '\t' '{print $3}'`
		mountDevice=`echo "$mountResult" | grep disk | head -1 | awk '{print $1}'`
# ...install target in DMG...
		if [[ "$TARGETinDMG" == *".app" ]]; then
			echo "[INSTALL] Copying to Applications..."
			rsync -az "$mountVolume/$TARGETinDMG/" "/Applications/$APP.app"
		elif [[ "$TARGETinDMG" == *".pkg" ]]; then
			echo "[INSTALL] Installing package..."			
			installer -pkg "$mountVolume/$TARGETinDMG" -target "/"
		fi
# ...eject DMG
		hdiutil detach "$mountDevice"
	fi

# Cleanup
	echo "[FINISH] Cleaning up..."
	rm -Rf "/private/tmp/Jamf Install"

fi
