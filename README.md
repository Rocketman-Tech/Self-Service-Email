# Self Service Email Form
Allows users to easily create an email through Self Service allowing you to customize the Subject, Recipients, and Body.

## History
The inspiration for this workflow was first created in 2016 by Dr. Emily Kausalik-Whittle via her blog: [https://www.modtitan.com/2022/02/jamf-binary-self-heal-with-jamf-api.html](https://www.modtitan.com/2015/12/creating-email-link-in-self-service.html). The idea behind this workflow was to allow users to create a email straight through a Self Service policy. 

This script takes the workflow a couple steps further by allowing the users to set a body of the email through an easy to read multi-line varaible (normally, you'd have to add %20 to each space). It is also configurable through the built in parameters within Jamf Pro. 

## How it Works
This workflow is deployed through a policy through Self Service. When run, it opens their default email client and composes an email template for them, allowing them to fill out additional information before sending it to the recipients. It will also use the Jamf API to grab additional information about the computer and put it in the email. 

## Parameters/Variables

### Parameters

- Parameter 4: This string will be used in an API call to file upload the logs at the end
  - Label: API Basic Authentication
  - Type: String (must be a base64 hash)
  - Requirements: API User with the following permissions
    - Computers - Read
    - Instructions: Generate a hash for parameter 4 with a command like:
    - echo -n 'jamfapi:Jamf1234' | base64 | pbcopy
    - Example: YXBpdXNlcm5hbWU6cGFzc3dvcmQK
- Parameter 5: Email Recipients
  - Label: TO: 
  - Type: String
  - Notes: Separate each recipient by a comma
- Parameter 6: Email Subject
  - Label: Subject:
  - Type: String
- Parameter 11: Overrides
  - Label: Overrides
  - Notes: CC and BCC recipients can be set via the overrides 
  - Example: CC='experts@rocketman.tech';BCC='chad@rocketman.tech,chris@rocketman.tech'

### Variables
- BODY
  - This variable is the body of the email. It allows for multiple lines and special characters. An example of what you can do is inside the script.

## Deployment Instructions
This workflow must be created and deployed through Jamf Pro using the following steps:
- Add CreateHelpDeskTicket.sh to Jamf Pro with the parameter labels above
- Create an API User with the following permissions and generate its hash
  - Computers - Create
- Create a Policy deploying CreateHelpDeskTicket.sh through Self Service with the parameters set above


