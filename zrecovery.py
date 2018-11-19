#!/usr/bin/python
# Znyx Networks
# zrecovery.py  
# flashes disk/partition
#
###############################################################################
import sys
import re
import os
import os.path
import logging
import logging.handlers
zlogger = logging.getLogger('Zlogger')
zlogger.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler(address = '/dev/log')
zlogger.addHandler(handler)
	# zlogger.debug('this is beginning')
	# zlogger.critical('this is critical')
 
from ConfigParser import SafeConfigParser
from fabric.api import local, settings, hide


########## defs ####################
# generic error function
def error(text):
	print "Error!"
	print "  " + text
	print " exiting..."
	sys.exit(-1)

def runcmd_silent(text):
	# this command will not abort if there is error
	# it does not display errors or output
    with settings( hide('warnings', 'running', 'stdout', 'stderr'), warn_only = True):
       result = local(text, capture = True)
       if result:
            return result
       else:
			return "error"		

def runcmd(text):
	# this command will display an error and abort the script
	# it does not display output
    with settings( hide('warnings', 'running',  'stderr')):
       result = local(text, capture = True)
       if result:
            return result
	
def installpart(file,part):
	if file and part:
		print "...Copying new MAIN partition, this will take several minutes... " 
		if re.match('.*.bz2$', file):
			print "got bz2"
			runcmd('bunzip2 -k -c ' + file + ' | dd of=' + part)
			resizepart(part)
		elif re.match('.*.[raw|qcow2]$', file):
			print "got raw"
			runcmd('dd if=' + file + ' of=' + part)
			resizepart(part)
	elif not file and not part:
		error( "Missing arguments to installpart")
	else:
		error("bad arguments to installpart")

		
def notify(subject, sender, text):
	# notify("subject text", "test.py@sender.com", " msg body text")
	runcmd_silent('./znotify.py \" %s \" \" %s \" \" %s\"' %(subject, sender, text  ))
	
def getdevice(label):
	# checks for partition label
	# returns device with partition number "/dev/sda1"
	print "checking device"
	result = runcmd_silent('blkid -L ' + label, capture = True)
	return result

def checkpartexist(part):
	# check partition to see if it exists and is ext4
	with settings(warn_only=True):
		ptest = runcmd_silent('blkid -t TYPE=ext4 %s'%(part))
		if ptest == "error" :
			print "Something is so wrong with the main partition we can't do recovery."
			error("The partition " + part + " isn't type ext4 or doesn't exist")
		mtest = runcmd_silent('grep \"%s\" /etc/mtab'%(part))
		if not mtest == "error":	
			error("A partition you are about to wipe clean" + part + " is still mounted. Umount the partition and run /opt/znyx/recovery.py again.")

def checkmain_is_alive(part):
	testmain = 0
	runcmd_silent('mkdir -p /tmp/tmpmount')
	runcmd_silent('mount %s /tmp/tmpmount'%(part))
	result = runcmd_silent('ls /tmp/tmpmount/boot/vmlinuz*')
	runcmd_silent('umount %s '%(part))
	runcmd_silent('rm -rf /tmp/tmpmount')
	if result == "error":
		return "not alive"
	else:
		return "alive"

# from the recipe: http://code.activestate.com/recipes/577058/
def query_yes_no(question, default):
    valid = {"yes": True, "y": True, "ye": True,
             "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        sys.stdout.write(question + prompt)
        choice = raw_input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' (or 'y' or 'n').\n")
			
def getfile():
	# 4.1.6-oa4-hv-b1c-main.raw.bz2    4.1.6-oa4-hv-b1c-recovery.raw.bz2
	release = getrelease()
	filename = release + "-oa4-hv-" + BOARDNAME + '-main.raw.bz2'
	print filename
	# avoid runcmd because we want to catch the error
	if os.path.isfile('/opt/znyx/' + filename):
		return '/opt/znyx/' + filename
	else:
		#print "getfile add interactive file chooser later"
		error("GetFile: can't find compressed Main partition file")
	
def getrelease():
	print "get release"
	line = runcmd_silent('grep DISTRIB_OA_VERSION /etc/lsb-release')
	if line == "error":
		error(" Getrelease unable to get the ZNYX OA4 release from /etc/lsb-release")
	else:
		release = line.split("=")[1] # sample: DISTRIB_OA_VERSION=4.1.5nightly-2014-10-06
		return release

def getboardname():
	# returns the znyx platform as used in filenames
	lbd = runcmd_silent('cat /var/lib/oa-vm/board')
	if lbd == "error":
		error("Getboardname couldn't get the board from /var/lib/oa-vm/board")
	else: 
		if lbd == "B1compute":
			bd = "b1c"
		elif lbd == "B1network":
			bd = "b1n"
		elif lbd == "ZX8100":
			bd = "zx8100"
		elif lbd == "ZX2040":
			bd = "zx2040"
		elif lbd == "ZX9210":
			bd = "zx9210"
		else:
			error("Could not get Board Name: " + lbd)
		return bd

# another way to getboardname
#def getplatform():
	## get which Znyx device this is
	## return well-known string as used elsewhere
	#st = runcmd_silent('ls /etc/rc2.d | grep S96')
	#if st == "error":
		#error("Getplatform couldn't get the platform ")
	#pl = re.search('S96(.*)-net', st )  #S96b1c-net
	#if pl:
		#return pl.group(1)
	#else:
		#error("getplatform: can't find platform script in rc2.d")

def getmylocation():
	#figure out where script is running
	# return error | recovery | main | usb
	# from conf file we know whats valid
	m = runcmd_silent('mount | grep \"on / type ext4\" ')
	if m == "error":
		error("Getmylocation couldn't get the device name for mounted root dir")
	# typ: /dev/sdb1 on / type ext4 (rw)
	ml = re.search('\/dev\/(.*)\son\s\/\stype.*', m )
	if ml:
		return '/dev/' + ml.group(1)
	else:
		error("getmylocation: can't figure out what device this is booted on.")

def getconfig():
	conffile = BOARDNAME + '-install.conf'
	if os.path.isfile(conffile):
		confparser = SafeConfigParser()
		confparser.read(conffile)
		# example: print confparser.get('data', <name>)
		return confparser
	else:
		error("Getconfig: no conf file found.")

def resizepart(part):
	# resize the partition to full size after recovery
	with settings(warn_only=True):
		ptest = runcmd_silent('blkid -t TYPE=ext4 %s'%(part) )
		if ptest == "error":
			print "Something is wrong with the main partition and can't be resized."
			error("Failure of the partition " + part )
		mtest = runcmd_silent('grep \"%s\" /etc/mtab'%(part))
		# testing for mount
		if not mtest == "error":	
			runcmd_silent('umount ' + part)
			runcmd_silent('e2fsck -f ' + part)
	resized = runcmd("resize2fs -f " + part)
	if resized == "error":
		error("There was a problem resizing " + part)

def main():
	global MYLOC, CONFOBJ

	if not CONFOBJ.get('data', 'recoverpart') == MYLOC:
		error("recovery.py: not running on recovery partition.")
		
	mainpart = CONFOBJ.get('data', 'mainpart')
	# check if exists; if mounted
	checkpartexist(mainpart)
	if checkmain_is_alive(mainpart) == "alive":
		answer = query_yes_no("Your main partition " + mainpart + " seems to be intact, are you sure you want to write over it? ", "no")
		if answer == False:
			print "You chose not to destroy the main partition and write a new one."
			print " exiting..."
			sys.exit(-1)
	print "    Starting recovery process........\n"
	lastchance = query_yes_no("Are you sure you want to write over your main partition, " + mainpart + " ? \n This will restore the factory default and destroy all data on it.", "no")
	if lastchance == False:
		print "You chose not to recover the main partition by writing over it."
		print " exiting..."
		sys.exit(-1)
	else:
		file = getfile()
		installpart(file,mainpart)
		if checkmain_is_alive(mainpart) == "alive":
			resizepart(mainpart)
			print " Recovery complete. \n Reboot and you should automatically come up in the main partition."
			print " The Main partition has ben installed with the factory default. You will have to re-install your local configuration there.\n"
			zlogger.debug("ZNYX " + mainpart + " has been overwritten with the recovery image")
		else:
			error (" Recovery did NOT succeed. Try checking " + mainpart + " manually.")
		
	
	
########## constants ###############
BOARDNAME = getboardname()
CONFOBJ = getconfig()
MYLOC = getmylocation()

########### execution begins here ############

if not os.geteuid() == 0:
	error("Script must be run as root")
	
main()
	
sys.exit(-1)	
