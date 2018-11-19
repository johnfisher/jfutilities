#!/usr/bin/python
# Znyx Networks
# Notify script
###################################################
# This script will attempt to send an
# email to the address specified below.
# The zrecovery.py script tries to call this
# script to send mail when:
# recovery or failure of the main partition.
#
# NOTE: successful emailing depends on your network,
# consult your system administrator.
####################################################

# Customer should edit below this line
####################################################
local_smtp_server = "zimbra.znyx.com"
send_to = "john.fisher@znyx.com"

# OPTIONAL edit below this line ####################

# SAMPLE email script
# add other notification as needed
####################################################
## syntax: znotify.py "my subject" "example@customer.com" "text"
import argparse
import smtplib
import email.utils
from email.mime.text import MIMEText

parser = argparse.ArgumentParser(description='Send mail.')
parser.add_argument('subject', type=str,  help='subject...')
parser.add_argument('sender',  type=str, help='sender... usually hostname')
parser.add_argument('body',   type=str, help='body... msg text')

args = parser.parse_args()

# Create the message
msg = MIMEText(args.body)
msg['To'] = email.utils.formataddr(('Recipient', send_to))
msg['From'] = email.utils.formataddr((args.sender, args.sender))
msg['Subject'] = args.subject

server = smtplib.SMTP(local_smtp_server)
try:
    server.sendmail(args.sender, send_to, msg.as_string() )
finally:
    server.quit()



