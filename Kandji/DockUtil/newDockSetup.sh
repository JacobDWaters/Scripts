#!/bin/bash

daemonName="com.company.newdocksetup"
scriptPath="/tmp/newDockSetup.sh"

# Wait for Kandji Liftoff to Advance to Complete Screen
until [ ! -f /Library/LaunchAgents/io.kandji.Liftoff.plist ]
	do
	sleep 1
	echo "Liftoff is still running..."
	done

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# COLLECT IMPORTANT USER INFORMATION
# Get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# Get uid logged in user
uid=$(id -u "${currentUser}")

# Current User home folder - do it this way in case the folder isn't in /Users
userHome=$(dscl . -read /users/${currentUser} NFSHomeDirectory | cut -d " " -f 2)

# Path to plist
plist="${userHome}/Library/Preferences/com.apple.dock.plist"

# Convenience function to run a command as the current user
# usage: runAsUser command arguments...
runAsUser() {  
	if [[ "${currentUser}" != "loginwindow" ]]; then
		launchctl asuser "${uid}" sudo -u "${currentUser}" "$@"
	else
		echo "no user logged in"
		exit 1
	fi
}

# Check if dockutil is installed
if [[ -x "/usr/local/bin/dockutil" ]]; then
    dockutil="/usr/local/bin/dockutil"
else
    echo "dockutil not installed in /usr/local/bin, exiting"
    exit 1
fi

# Check if System Settings.app exists for devices running Ventura, if not, fallback to System Preferences.app
if [[ -x "/System/Applications/System Settings.app" ]]; then
    systemSettings="System Settings.app"
else
	systemSettings="System Preferences.app"
    echo "System Settings not found, set to System Preferences"
fi

# Create a clean dock
runAsUser "${dockutil}" --remove all --no-restart ${plist}
echo "clean-out the dock"

# Full path to Applications to add to the dock
apps=(
"/System/Applications/Launchpad.app"
"/Applications/Google Chrome.app"
"/Applications/Slack.app"
"/Applications/zoom.us.app"
"/Applications/Kandji Self Service.app"
"/System/Applications/${systemSettings}"
)

# Loop through Apps and check if App is installed, If Installed add App to the Dock.
for app in "${apps[@]}"; 
do
	if [[ -e ${app} ]]; then
		runAsUser "${dockutil}" --add "${app}" --no-restart ${plist};
	else
		runAsUser "${dockutil}" --add "${app}" --no-restart ${plist};
    fi
done

# Kill dock to use new settings
killall -KILL Dock
echo "Restarted the Dock"
echo "Finished creating default Dock"

# Remove launchdaemon and script to prevent rerun
echo "Unloading and deleting launchdaemon and script"
sudo launchctl bootout gui/${uid} "/tmp/${daemonName}.plist"
rm "/tmp/${daemonName}.plist"
rm "${scriptPath}"
echo "launchdaemon and script deleted"
