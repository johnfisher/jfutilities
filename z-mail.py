#!/usr/bin/python
# Znyx Networks
#  z-mail.py helper mailing script
#  ( using z-mail to avoid collision with zimbra zmail)
#
############################################################################
# syntax: thisfile "test of mail3" "hostname@customer.com" "support@znyx.com" "textfilename"
import argparse
# Import smtplib for the actual sending function
import smtplib
# Import the email modules we'll need
from email.mime.text import MIMEText

parser = argparse.ArgumentParser(description='Send mail.')
parser.add_argument('subject', type=str,  help='subject...')
parser.add_argument('sender',  type=str, help='sender... usually hostname')
parser.add_argument('to',   type=str,  help='to... usually support@znyx.com')
parser.add_argument('body',   type=str, help='body... a filename containing text')

args = parser.parse_args()

# Open a plain text file for reading.  For this example, assume that
# the text file contains only ASCII characters.
fp = open(args.body, 'rb')
# Create a text/plain message
msg = MIMEText(fp.read())
fp.close()

msg['Subject'] = args.subject
msg['From'] = args.sender
msg['To'] = args.to
# Send the message via our own SMTP server, but don't include the
# envelope header.
s = smtplib.SMTP('zimbra.znyx.com')
s.sendmail(args.sender, args.to, msg.as_string())
s.quit()