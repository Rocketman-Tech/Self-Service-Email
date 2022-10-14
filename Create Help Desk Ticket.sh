#!/bin/bash

: HEADER = <<'EOL'

██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗
██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║
██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║   ██╔████╔██║███████║██╔██╗ ██║
██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║
██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║
╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

      Name: Create Help Desk Ticket
Description: This script is designed to be deployed within Self Service as a policy.
             It will automatically. compose an email with the users Full Name from Jamf,
             their computer Model, and a link to the computers inventory record within Jamf.
Parameters: $1-$3 - Reserved by Jamf (Mount Point, Computer Name, Username)
               $4 - Base64 encoded API username/password
               $5 - Email 'To' field (comma separated list of email addresses)
               $6 - Email 'Subject' field
              $11 - Overrides - search "Optional Items for Override"

  Created By: Chris Schasse
     Version: 1.1
     License: Copyright (c) 2022, Rocketman Management LLC. All rights reserved. Distributed under MIT License.
   More Info: For Documentation, Instructions and Latest Version, visit https://www.rocketman.tech/jamf-toolkit

EOL

##
## Defining Parameters and Variables
##

APIHASH="$4" ## Base64 encoded 'USER:PASS' string for API computer record access
TO="$5" # This is setting the main recipients. Separate them by a comma if multiple
SUBJECT="$6" # This is the subject of the email. Spaces are fine.

## Email Body: This will set the body of the email. You may use multiple lines.
BODY="
Please answer all the following questions regarding your issue:
- What resource are you attempting to access?
- Are multiple users affected?
- Does this issue happen every time? Or is it intermittent?

Please attach a screenshot of the issue and any additional information about your issue.
"

##
## Optional Items for Override
##

## These set any CCs or BCCs. Separate them by a comma if multiple
CC=""
BCC=""

## Overrides of above as needed
## Ex. "CC='experts@rocketman.tech';BCC='chad@rocketman.tech,chris@rocketman.tech'"
[[ "${11}" == *"="* ]] && eval ${11}

##
## SCRIPT CONTENTS, DO NOT MODIFY BELOW THESE LINES (Unless you know what you're doing)
##

## System variables
OSMAJOR=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}') # Major OS Version
SERIAL=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}') # Computer's Serial Number
JAMFURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url) # Jamf Pro URL

## API Call for computer information
COMPUTERXML=$(curl -s -H "Authorization: Basic ${APIHASH}" -H "accept: text/xml" ${JAMFURL}JSSResource/computers/serialnumber/${SERIAL} -X GET)
status=$?
if [ ${status} -gt 0 ]; then
  echo "Error connection to API: ${status}"
  exit ${status}
fi

## Depending on the OS version, xpath requires the -e flag
if [[ "$OSMAJOR" -ge 11 ]]; then
  opt='-e'
fi

## Extract fields from record
id=$(echo $COMPUTERXML | xpath ${opt} "//computer/general/id/text()")
computerModel=$(echo $COMPUTERXML | xpath ${opt} "//computer/hardware/model/text()" )
computerName=$(echo $COMPUTERXML | xpath ${opt} "//computer/general/name/text()" )
FullName=$(echo $COMPUTERXML | xpath ${opt} "//computer/location/realname/text()" )

## Put the body of the email and info from Jamf Pro into a file
cat > /tmp/EmailBody.txt <<EOF
$BODY

User Information (Do not edit or delete):
Name: $FullName
Model: $computerModel
Computer Name: $computerName
Jamf Pro Record: $JAMFURL/computers.html?id=$id
EOF

## Replacing any troublesome spaces and special characters with the proper HTML syntax
SUBJECT=${SUBJECT// /%20}
BODY=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/%0D%0A/g' /tmp/EmailBody.txt)
BODY=${BODY// /%20}

## Opening the email with a mailto command. Thanks to Dr Emily Kausalik-Whittle's blog post for the inspiration behind this: https://www.modtitan.com/2015/12/creating-email-link-in-self-service.html
open "mailto:${TO}?&cc=${CC}&bcc=${BCC}&subject=${SUBJECT}&body=${BODY}"
