#!/bin/bash

# Assign the value "XYZ" to the password variable
rustdesk_password="XYZ"

# Get your config string from your Web portal and Fill Below.
rustdesk_config="configstring" 

####################################Please Do Not Edit Below This Line##########################################

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root."
	exit 1
fi

# Specify the path to the rustdesk.dmg file
dmg_file="/tmp/rustdesk-1.2.2-x86_64.dmg"

# Specify the mount point for the DMG (temporary directory)
mount_point="/Volumes/RustDesk"

# Download the rustdesk.dmg file
echo "Downloading RustDesk Now"
curl -L https://github.com/rustdesk/rustdesk/releases/download/nightly/rustdesk-1.2.2-x86_64.dmg --output "$dmg_file"

# Mount the DMG file to the specified mount point
hdiutil attach "$dmg_file" -mountpoint "$mount_point" &> /dev/null

# Check if the mounting was successful
if [ $? -eq 0 ]; then
	# Move the contents of the mounted DMG to the /Applications folder
	cp -R "$mount_point/RustDesk.app" "/Applications/" &> /dev/null
	
	# Unmount the DMG file
	hdiutil detach "$mount_point" &> /dev/null
else
	echo "Failed to mount the RustDesk DMG. Installation aborted."
	exit 1
fi

# Run the rustdesk command with --get-id and store the output in the rustdesk_id variable
cd /Applications/RustDesk.app/Contents/MacOS/
rustdesk_id=$(./RustDesk --get-id)

# Apply new password to RustDesk
./RustDesk --server &
/Applications/RustDesk.app/Contents/MacOS/RustDesk --password $rustdesk_password &> /dev/null

/Applications/RustDesk.app/Contents/MacOS/RustDesk --config $rustdesk_config

# Kill all processes named RustDesk
rdpid=$(pgrep RustDesk)
kill $rdpid &> /dev/null

echo "..............................................."
# Check if the rustdesk_id is not empty
if [ -n "$rustdesk_id" ]; then
	echo "RustDesk ID: $rustdesk_id"
else
	echo "Failed to get RustDesk ID."
fi

# Echo the value of the password variable
echo "Password: $rustdesk_password"
echo "..............................................."

echo "Please complete install on GUI, launching RustDesk now."
open -n /Applications/RustDesk.app
