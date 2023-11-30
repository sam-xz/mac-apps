#!/bin/bash
# Samuel Marino 29/Nov/2023
# Download the latest version of 1Password 8 from the web and install

# Some vars
APP="1Password"
URL="https://downloads.1password.com/mac/1Password-latest-aarch64.zip"
CurrUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
killall=/usr/bin/killall
# Check if the script has already been run for the current user
if [ -f "/Users/$CurrUser/jumpcloud/.1P8_setup_completed" ]; then
    echo "[EXIT] 1P8 setup already completed for this user. Exiting..."
    exit 0
fi

# check if dockutil is installed, install if it's not.
dockutil="/usr/local/bin/dockutil"
if [[ -x $dockutil ]]; then
    echo "[OK] DockUtil already installed, continuing... "
else
    echo "[INSTALL] Dockutil not found...installing now..."
    curl -L --silent --output "/tmp/dockutil.pkg" "https://github.com/kcrawford/dockutil/releases/download/3.0.2/dockutil-3.0.2.pkg" >/dev/null
    # install dockutil
    installer -pkg "/tmp/dockutil.pkg" -target /
fi


# Check if 1P7 is installed and clean up
if [[ -d /Applications/"$APP 7".app ]]; then
    echo [CLEAN] 1Password 7 is currently installed...Removing...
    $killall "1Password 7"
    rm -rf "/Applications/1Password 7.app"
    rm -rf "1Password 7.app.zip"
else
    echo "[OK] 1Password 7 not installed. Continuing."
fi

# Check if 1P8 is installed already
#if [[ -d /Applications/"$APP".app ]]; then
#    echo "[OK] 1Password 8 is already instaled."
#    echo "[EXIT]"
#    exit 0
#else
#    echo "[OK] 1Password 8 not installed. Continuing."
#fi

rm -rf "/Applications/$APP.app"

#Preinstall CleanUp
rm -rf "/Users/Shared/1P8/"
sleep 3

#Download 1P8
mkdir "/Users/Shared/1P8"
curl -o "/Users/Shared/1P8/1Password.zip" "$URL"
sleep 2
chmod 777 "/Users/Shared/1P8/1Password.zip"
sleep 1
/usr/bin/unzip -o "/Users/Shared/1P8/1Password.zip" -d "/Users/Shared/1P8/"

mv "/Users/Shared/1P8/1Password.app/" "/Applications/1Password.app"

echo "[OK] Cleaning up..."
#rm -Rf "/Users/Shared/1P8/"

$dockutil --remove "/Applications/1Password 7.app" --no-restart --allhomes
$dockutil --add "/Applications/1Password.app" --before "com.apple.systempreferences" --no-restart --allhomes
sudo -u $CurrUser $killall Dock

# Create a file to mark that the script has been run for this user
mkdir -p "/Users/$CurrUser/jumpcloud"
touch "/Users/$CurrUser/jumpcloud/.1P8_setup_completed"

echo "[OK] 1Password 8 has been installed and added to the Dock."
echo "[EXIT]"
exit 0