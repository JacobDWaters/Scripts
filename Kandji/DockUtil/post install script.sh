#!/bin/bash

#Variables
daemonName="com.company.newdocksetup"
scriptPath="/tmp/newDockSetup.sh"

 # Set correct permissions on launchdaemon
echo "Setting permissions on launchdaemon..."
/usr/sbin/chown root:wheel "/tmp/${daemonName}.plist"
/bin/chmod 644 "/tmp/${daemonName}.plist"
/bin/chmod +x "${scriptPath}"

# Load launchdaemon
echo "Loading launchdaemon..."
/bin/launchctl load "/tmp/${daemonName}.plist"

exit