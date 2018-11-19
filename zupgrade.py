#!/usr/bin/python
# Znyx Networks
# zupgrade.py  
# runs OA4 upgrade
#
###############################################################################
import sys
import re
import os
import os.path
import subprocess
import argparse
import logging
import logging.handlers
zlogger = logging.getLogger('Zlogger')
zlogger.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler(address = '/dev/log')
zlogger.addHandler(handler)
	# zlogger.debug('this is beginning')
	# zlogger.critical('this is critical')
 
from ConfigParser import SafeConfigParser


parser = argparse.ArgumentParser(description="no arguments: copy image file to disk with warnings")
parser.add_argument('-q',  action='store_true', required=False,  help="use -q to suppress warnings, -h for help")
parser.add_argument('file',  nargs='?',  help="use input bz2 disk filename")
parser.add_argument('device', nargs='?',   help="use output disk device name ")
args = parser.parse_args()

# added to allow upgrading from releases prior to 4.1.6
# after that, fabric is in all releases
try:
	from fabric.api import local, settings, hide
except ImportError:
	print "\n   ######### Installing: Python Fabric ##########\n"
	try:
		subprocess.check_call(["dpkg", "-i", "fabric_*.deb"])
		from fabric.api import local, settings, hide
	except:
		print "\n   Couldn't use deb file, trying apt-get...\n"
		try:
			subprocess.check_call(["apt-get", "update"])
			subprocess.check_call(["apt-get", "-q", "-y", "install", "fabric"])
			from fabric.api import local, settings, hide
			print "\n   ######### Finished: Python Fabric ##########\n"
		except:
			print "   Exiting - can't run without Python Fabric library."
			print "   if you have access to a repo: apt-get install fabric "
			sys.exit(-1)

	
	
	
	
	
	
from contextlib import contextmanager

########## defs ####################
def argtest():
	global QUIET, MODE
	if args.q is True:
		QUIET = True
		if args.file and args.device:
			MODE = "diskcopy"
		else:
			MODE = "upgrade"
			if args.file and not args.device:
				usage()
	else:
		if  args.file:
			usage()
			
def prepare():
	# make sure we have pbzip2 available, which was also introduced in 4.1.6
	try:
		runcmd_silent('dpkg -l | grep pbzip2')
	except:
		print_wrap("\n   ########## Installing: pbzip2 #########\n")
		try:
			runcmd_silent("apt-get update")
			runcmd_silent("apt-get -q -y install pbzip2")
			print_wrap("\n   ########## Finished: pbzip2 #########\n")
		except:
			try:
				runcmd_silent("dpkg -i pbzip2*.deb")
				print_wrap("\n   ########## Finished: pbzip2 #########\n")
			except:
				print "   You have no pbzip2 utility."
				print "   Substituting single-threaded bzip2. "
				NOPBZIP = True
				
			

def usage():
	# dont mess with uneven tabs in text
	print """
	Usage:
	copy disk images to disk; upgrade packages; upgrade firmware
	   # zupgrade.py	interactive upgrade or disk copy
	   # zupgrade.py -q 	non-interactive upgrade 
	   # zupgrade.py -q	<filename> <devicename>		non-interactive diskcopy
	   
	   Required in all cases,  supply the appropriate support files 
	   for the target release in the upgrade:
	   
	   Download and unpack the release tarball, and you will have all the 
	   files you need except the disk images. If you wish to do disk copying, 
	   Download the disk images separately from the Znyx server, also at: 
	   https://znyx-tech.com/ds/
	   
	   When unpacking the tarball to upgrade your release, be sure to run 
	   zupgrade.py from inside the upacked directory. This will ensure you have 
	   the latest files. During the upgrade, /opt/znyx/zupgrade.py 
	   and the /opt/znyx conf file will be updated too.
	   
	   Running on /dev/sda:
	   
	   With no parameters, zupgrade will ask the user if firmware or package 
	   upgrades or creation of bootable flashdrives are wanted. It will not 
	   upgrade the packages until the approriate firmware is installed. 
	   Otherwise, you may choose any or all of the three options when asked.
	   
	   When '-q' is entered, zupgrade will automatically perform both firmware 
	   and Debian package upgrades. No warnings or interaction will be 
	   presented. This mode is intended for scripted upgrades.
	   
	   When '-q file device' is entered, it will simply disk-copy with no warnings 
	   or checking to see if the release is correct, the file is correct, or 
	   the target is correct.
	   
	   Running on a flashdrive:
	   
	   When run from a bootable flashdrive, zupgrade behaves differently. 
	   Instead of offering to create a flashdrive, it offers to diskcopy to 
	   the main /dev/sda drive, and/or upgrade firmware, with no ability to 
	   do package upgrades.
	"""
	sys.exit(-1)

# generic error function
def error(text):
	print "\n   Error!"
	print "  "  +  text
	print " exiting..."
	sys.exit(-1)

def abort(text):
	print "   \nStopping...."
	print "  "  +  text
	print "   exiting..."
	sys.exit(-1)
	
def print_wrap(text):
	if QUIET:
		return
	else:
		print text
	
	
def runcmd_silent(text):
	# this command will not abort if there is error
	# it does not display errors or output
	# warning can return an error on 0 result
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

def runcmd_noisy(text):
	# this command will display everything
    with settings( hide('warnings')):
       local(text)

	
def installpart(file,part):
	if file and part:
		print_wrap( "...Copying new MAIN partition, this will take several minutes... ") 
		if re.match('.*.bz2$', file):
			print_wrap( "got bz2")
			if NOPBZIP:
				runcmd_noisy('bzip2 -kdc '  +  file  +  ' | dd bs=32M of='  +  part)
			else:
				runcmd_noisy('pbzip2 -kdc '  +  file  +  ' | dd bs=32M of='  +  part)
			resizepart(part)
		elif re.match('.*.[raw|qcow2]$', file):
			print_wrap( "got raw")
			runcmd_noisy('dd bs=32M if='  +  file  +  ' of='  +  part)
			resizepart(part)
	elif not file and not part:
		error( "Missing arguments to installpart")
	else:
		error("bad arguments to installpart")

		
def notify(subject, sender, text):
	# notify("subject text", "test.py@sender.com", " msg body text")
	runcmd_silent('./znotify.py \" %s \" \" %s \" \" %s\"' %(subject, sender, text  ))

##!!!!!!!! messed up fix this!!!!!!!!!!!!	
def getdevice(label):
	# checks for partition label
	# returns device with partition number "/dev/sda1"		
	result = runcmd_silent('blkid '  +  label)
	return result
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1

def checkpartexist(part):
	# check partition to see if it exists and is ext4
	with settings(warn_only=True):
		ptest = runcmd_silent('blkid -t TYPE=ext4 %s'%(part))
		if ptest == "error" :
			print_wrap( "   Something is so wrong with the main partition we can't do recovery.")
			error("The partition "  +  part  +  " isn't type ext4 or doesn't exist")
		mtest = runcmd_silent('grep \"%s\" /etc/mtab'%(part))
		if not mtest == "error":	
			error("A partition you are about to wipe clean"  +  part  +  " is still mounted. Umount the partition and run /opt/znyx/recovery.py again.")

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
	if QUIET is True:
		return True
	else:
		valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}
		if default is None:
			prompt = " [y/n] "
		elif default == "yes":
			prompt = " [Y/n] "
		elif default == "no":
			prompt = " [y/N] "
		else:
			raise ValueError("invalid default answer: '%s'" % default)

		while True:
			sys.stdout.write(question  +  prompt)
			choice = raw_input().lower()
			if default is not None and choice == '':
				return valid[default]
			elif choice in valid:
				return valid[choice]
			else:
				sys.stdout.write("Please respond with 'yes' or 'no' (or 'y' or 'n').\n")
			
def getbz2file(mode):
	# mode = "main" | "recovery" | "entire"
	# oa4-hv-b1c-main.raw.bz2    oa4-hv-b1c-recovery.raw.bz2
	if mode == "main":
		filename =  CONFOBJ.get('data', 'mainbz2')
	elif mode == "recovery":
		filename =  CONFOBJ.get('data', 'recoverybz2')	
	elif mode == "entire":
		filename =  CONFOBJ.get('data', 'entirebz2')

	# avoid runcmd because we want to catch the error
	myfile = os.path.isfile('./' + filename)
	if not myfile == "error":
		return  filename
	else:
		#reach out
		if NETSTATUS == False:
			error("GetFile: can't find compressed "  +  filename  +  " partition file")
		else:
			print_wrap( "\n   Trying to download the image file to /opt/znyx...")
			f = runcmd_silent('wget http://oa4.znyx.com/images/' + NEWRELEASE + '/' + filename.strip("/opt/znyx"))
			if f == "error":
				error( "Can't find or download the image file: " + filename)
				

def get_release(dev):
	# given a dev/device mount it and ask what the release is
	# returns "unknown" if fails to cover case of bad filesystem or new disk
	mounted = runcmd_silent('grep ' + dev + ' /etc/mtab')
	mntpoint = ''
	need_cleanup = False
	release = ''
	if mounted == "error":
		mntpoint = '/tmp/tmpmnt'
		runcmd_silent('mkdir -p ' + mntpoint + ' ; mount ' + dev +  ' ' + mntpoint)
		success =  runcmd_silent('grep ' + dev + ' /etc/mtab')
		if success == "error":
			release = "unknown"
		else:
			need_cleanup = True
	else:
		mntpoint = mounted.split(' ')[1]
	r = runcmd_silent('grep DISTRIB_OA_VERSION ' + mntpoint + '/etc/lsb-release')
	if r == "error":
		release = "unknown"
	else:
		release = r.split("=")[1] # sample data: DISTRIB_OA_VERSION=4.1.5
	if need_cleanup:
		runcmd_silent('umount ' + dev )
		not_clean = runcmd_silent('grep ' + dev + ' /etc/mtab')
		if not not_clean == "error":
			error("Can't unmount temp mounted device: " + dev )
	return release

			
def getboardname():
	# returns the znyx platform as used in filenames
	lbd = runcmd_silent('cat /var/lib/oa-vm/board')
	if lbd == "error":
		if runcmd_silent('grep 8100 /var/lib/oa-vm/info'):
			return "zx8100"
		else:
			error("Getboardname couldn't get the board from /var/lib/oa-vm/board")
	else: 
		if lbd == "B1compute":
			bd = "b1c"
		elif lbd == "B1net":
			bd = "b1n"
		elif lbd == "8100":
			bd = "zx8100"
		elif lbd == "2040":
			bd = "zx2040"
		elif lbd == "9210":
			bd = "zx9210"
		else:
			error("Could not get Board Name: "  +  lbd)
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
		return '/dev/'  +  ml.group(1)
	else:
		error("getmylocation: can't figure out what device this is booted on.")


def getconfig():
	if os.path.isfile(CONFFILE):
		confparser = SafeConfigParser()
		confparser.read(CONFFILE)
		# example: print confparser.get('data', <name>)
		return confparser
	else:
		error("Getconfig: no conf file found: <boardname>-upgrade.conf" )

#example>>>>>>>>>>>>>>>

		
		#[paths]
#path1           = /some/path/
#path2           = /another/path/
#...

#and using config.items( "paths" ) to get an iterable list of path items, like so:

#path_items = config.items( "paths" )
#for key, path in path_items:
    ##do something with path
    
   #example>>>>>>>>>>>>>>>
 
    
    
    
		
def get_installed_firmware():
	fw = ""
	if BOARDNAME == "b1c":
		fw = runcmd('ipmitool -I serial-basic -D /dev/ttyS1:115200 hpm check')
	else:
		fw = runcmd('ipmitool hpm check')
		
	if BOARDNAME == "b1c" or BOARDNAME == "b1n":
		fwa = fw.split('\n')
					# B1------------------------------------------------------
					#|ID | Name       |             Versions              |
					#|   |            |     Active      |     Backup      |
					#------------------------------------------------------
					#| 0 |IPMC FW     |   2.05 74657374 |   2.05 74657374 |
					#| 1 |IPMC BootLdr|   2.02 00000000 | ---.-- -------- |
					#| 2 |FRU Info    |   1.00 00000000 | ---.-- -------- |
					#| 3 |MAC EEPROMs |   3.00 00000000 | ---.-- -------- |
					#| 4 |FPGA Image  |   2.00 00000000 | ---.-- -------- |
					#| 5 |CPLD Image  |   3.00 00000000 | ---.-- -------- |
					#| 6 |Compute UEFI|   2.10 00000000 | ---.-- -------- |
					#| 7 |Network UEFI|   2.08 00000000 | ---.-- -------- |
					#-----------------------------------------------------
		exist_firmware = {'IPMC FW' : 0,  'IPMC BootLdr' : 0,  'FRU Info' : 0,  'MAC EEPROMs' : 0,  'FPGA Image' : 0,  'CPLD Image' :0,  'Compute UEFI' : 0, 
	'Network UEFI': 0 }
		# start at line 4 of output, split on |, take 4th section, strip whitespace
		l4 = fwa[4].split('|')[3].strip()
		# split two parts, save first; NOTE future custom version number in second part!
		exist_firmware['IPMC FW'] = l4.split(' ', 1)[0]	
		l5 = fwa[5].split('|')[3].strip()
		exist_firmware['IPMC BootLdr'] = l5.split(' ', 1)[0]	
		l6 = fwa[6].split('|')[3].strip()
		exist_firmware['FRU Info'] = l6.split(' ', 1)[0]		
		l7 = fwa[7].split('|')[3].strip()
		exist_firmware['MAC EEPROMs'] = l7.split(' ', 1)[0]		
		l8 = fwa[8].split('|')[3].strip()
		exist_firmware['FPGA Image'] = l8.split(' ', 1)[0]		
		l9 = fwa[9].split('|')[3].strip()
		exist_firmware['CPLD Image'] = l9.split(' ', 1)[0]
		l10 = fwa[10].split('|')[3].strip()
		exist_firmware['Compute UEFI'] = l10.split(' ', 1)[0]
		l11 = fwa[11].split('|')[3].strip()
		exist_firmware['Network UEFI'] = l11.split(' ', 1)[0]	
	elif BOARDNAME == "zx8100":
							#8100			------------------------------------------------------
				#|ID | Name       |             Versions              |
				#|   |            |     Active      |     Backup      |
				#------------------------------------------------------
				#| 0 |IPMC FWW    |   1.13 00000000 |   1.13 00000000 |
				#| 1 |IPMC BootLdr|   1.13 00000000 | ---.-- -------- |
				#| 2 |FRU Infoo   |   1.03 00000000 | ---.-- -------- |
				#| 3 |MAC EEPROMss|   2.00 00000000 | ---.-- -------- |
				#| 4 |FPGA Imagee |   7.00 00000000 | ---.-- -------- |
				#| 5 |CPLD Imagee |  11.00 00000000 | ---.-- -------- |
				#| 7 |UEFI FWW    |   2.06 00000000 | ---.-- -------- |
				#-----------------------------------------------------
		fwa = fw.split('\n')
		exist_firmware = {'IPMC FW' : 0,  'IPMC BootLdr' : 0,  'FRU Info' : 0,  'MAC EEPROMs' : 0,  'FPGA Image' : 0,  'CPLD Image' :0,  'UEFI FW' : 0 }
		# start at line 4 of output, split on |, take 4th section, strip whitespace
		l4 = fwa[4].split('|')[3].strip()
		# split two parts, save first; NOTE future custom version number in second part!
		exist_firmware['IPMC FW'] = l4.split(' ', 1)[0]	
		l5 = fwa[5].split('|')[3].strip()
		exist_firmware['IPMC BootLdr'] = l5.split(' ', 1)[0]	
		l6 = fwa[6].split('|')[3].strip()
		exist_firmware['FRU Info'] = l6.split(' ', 1)[0]		
		l7 = fwa[7].split('|')[3].strip()
		exist_firmware['MAC EEPROMs'] = l7.split(' ', 1)[0]		
		l8 = fwa[8].split('|')[3].strip()
		exist_firmware['FPGA Image'] = l8.split(' ', 1)[0]		
		l9 = fwa[9].split('|')[3].strip()
		exist_firmware['CPLD Image'] = l9.split(' ', 1)[0]
		l10 = fwa[10].split('|')[3].strip()
		exist_firmware['UEFI FW'] = l10.split(' ', 1)[0]

	return exist_firmware

def check_firmware():
	# compare new release with existing versions
	if BOARDNAME == "b1c":
		return
	exist = get_installed_firmware()  # a dictionary
				#[recipe]
				#IPMC FW     : 2.03  
				#IPMC BootLdr: 2.02  
				#FRU InfotLdr: 1.00  
				#MAC EEPROMsr: 2.00  
				#FPGA Imagesr: 1.00  
				#CPLD Imagesr: 2.00  
				#Compute UEFI: 2.06  
				#Network UEFI: 2.06 
	for n, name in enumerate(exist):
		if not CONFOBJ.get('recipe', name) == exist[name]:
			# at least one is not right; go upgrade
			if QUIET:
				firmware_upgrade()
				return
			else:
				answer = query_yes_no("\n   Your system requires a firmware upgrade for release " + NEWRELEASE + ". Do you want to upgrade firmware?", "no")
				if answer == True:
					print_wrap("\n   Depending on the changes to firmware your system may automatically power cycle after the firmware upgrade. \n   You must rerun zupgrade.py after the power cycle/reboot - \n   zupgrade.py will check to make sure the firmware upgrade completed and then offer more upgrade options.")
					firmware_upgrade()
				return
	
def check_network():
	# check to make sure we have Internet access | intranet access to the repository
	# gets each uncommented URL from sources.list and tries them
	urllist =  (runcmd('grep -h ^deb /etc/apt/sources.list')).split('\n')
	length = len(urllist)
	for i in range(0, length):
		url = urllist[i].split(' ')[1]
		if runcmd("wget --spider -S "  +  url  +  " 2>&1 | grep \"HTTP\/\" | awk '{print $2}'"):
			return True
		else:
			return False
		
def fix_sources_list():
	# upgrades to new platform-specific URLs
	oldurl =  (runcmd_silent("grep -h '/repo/4.1/' /etc/apt/sources.list"))
	if not oldurl  == "error":
		#answer = query_yes_no("Your system requires an update to /etc/apt/sources.list for release " + NEWRELEASE + ". Do you want to proceed?", "yes")
		for (key, command) in CONFOBJ.items('sources.list'):
			try:
				runcmd_noisy(command)
			except:
				error("Unable to update /etc/apt/sources.list.")
		print_wrap("\n   Updated your /etc/apt/sources.list file. Original version saved.\n")
				
def check_versions():
	# check to see that this version of zupgrade.py can be used on 
	# the local current version to get to the new version
	conf_zupdate_ver = CONFOBJ.get('data','zupdate_ver')
	if not conf_zupdate_ver == SCRIPTVER:
		# the conf file is out of sync with this script
		error("This script is version " + SCRIPTVER + " and the target version is " + NEWRELEASE + ". Use the matching zupgrade script to upgrade/reload " + NEWRELEASE + ". Check " + WIKIDOC_URL + " for the correct installation kit.")
	
	if OLDRELEASE == "unknown":
		# bad filesystem, fresh disk
		return "ok"
	
	for v in VALID_VERSIONS:
		# rule: if the installed release is listed in the conf file as valid FROM-release
		if v == OLDRELEASE:
			return "ok"
		# rule: allow any installed nightly release
		if re.search(r'.*nightly.*', OLDRELEASE):
			return "nightly"
		#rule: if the from equals the newrelease- recovery, new disk
		if v == NEWRELEASE:
			return "ok"
		
	# no valid FROM-release found, error out
	vers = " ".join(VALID_VERSIONS)
	error("This version of zupgrade.py " + SCRIPTVER + " cannot upgrade the " + BOARDNAME + " to " + NEWRELEASE + " from " + OLDRELEASE + ". Valid upgrade-from versions are " + vers +  " Call ZNYX Tech Support for information and consult the Release Notes at " + WIKIDOC_URL )
	   
def get_valid_versions():
	# get the list of valid upgrade-from versions from conf file
	vlist = []
	for key, version in CONFOBJ.items("valid-versions"):
		vlist.append(version)
	return vlist

	
			
def check_recoveryplan():
	# check to see if this is legacy or recovery
	# possible replies are: legacy-legacy; legacy-recovery; recovery-recovery; flashdrive; error
	is_part2 = getdevice('/dev/sda2')
	if MYLOC == '/dev/sda2':
		if MYLOC == CONFOBJ.get('data', 'mainpart'):
			# then its already a 2 part recovery system
			return "recovery-recovery"
		else:
			error("Something is wrong with this disk location: "  +  MYLOC  +  "\nand what we expect "  +  CONFOBJ.get('data', 'mainpart')  +  " not sure what to do.")
	elif MYLOC == '/dev/sda1':
		if CONFOBJ.get('data', 'recoveryplan') == "false":
			# no recovery
			return "legacy-legacy"
		elif CONFOBJ.get('data', 'recoveryplan') == "true":
			# check to see if there is an sda2, if not its legacy-recovery
			if is_part2 == "error":
				return "legacy-recovery"
			else:
				return "recovery-recovery"
	elif check_usb_disk(MYLOC):
		if MYLOC == '/dev/sdb1' or '/dev/sdc1':
			return "flashdrive"
		else:
			error(" Doesn't look like we are on a USB flashdrive: " + MYLOC + " not sure what to do.")
	elif re.search('v/v', MYLOC):
		return "vm"
			
def check_usb_disk(dev):
	#check to see if a disk is usb, i.e. flashdrive
	# dev matches MYLOC i.e. /dev/sdc1 or /dev/sdc
	shortdev = re.sub('/dev/', '', dev)
	usblines = runcmd_silent('ls -l /dev/disk/by-id/* | grep ' + shortdev + ' | grep usb ')
	# typ result =
	# lrwxrwxrwx 1 root root  9 Dec  8 16:22 /dev/disk/by-id/usb-hp_v125w_002354C611A8AC4182CF004F-0:0 -> ../../sdd
	# lrwxrwxrwx 1 root root  9 Dec  8 16:22 /dev/disk/by-id/usb-SanDisk_Extreme_AA010610140717164112-0:0 -> ../../sdc
	if usblines == "error":
		return False
	else:
		return True
	
def get_usb_disks():
	# list the devices for flashdrive use
	usbdisks = list()
	shortusbdisks = list()
	# get line-by-line list from output
	usbdisks = runcmd_silent('ls -l /dev/disk/by-id/* | grep -v part | grep usb ').split('\n')
	for item in usbdisks:
		# clean up each line to make readable
		shortusbdisks.append(re.sub('.*by-id\/','', item))
	return shortusbdisks
		
def get_disk_info():
	# displays info about whats here and what we are booted on
	disk_info = []
	vmdisk = runcmd_silent('fdisk -l | grep "Disk /dev/v" | cut -d " "  -f 2').rstrip(':')
	if not vmdisk == "error":
		disk_info.append(vmdisk)
	else:
		disks = runcmd_silent('ls -l /dev/disk/by-id/*  ').split('\n')
		for i in disks:
			if re.match('.*usb.*', i):
				disk_info.append("   USB: " + re.sub('.*by-id\/usb-','', i))
			elif re.match('.*ata.*', i):
				disk_info.append("   SSD: " + re.sub('.*by-id\/ata-','', i))
	return disk_info
	
def get_disk_size(dev):
	# runs fdisk to see if disks are big enough
	#"Disk /dev/sdb: 62.7 GB, 62742792192 bytes"
	shortdev = re.sub('/dev/', '', dev) # "sdb"
	lines = runcmd_silent('ls -l /dev/disk/by-id/* | grep ' + shortdev )
	# typ result =
	# lrwxrwxrwx 1 root root  9 Dec  8 16:22 /dev/disk/by-id/usb-hp_v125w_002354C611A8AC4182CF004F-0:0 -> ../../sdd
	# lrwxrwxrwx 1 root root  9 Dec  8 16:22 /dev/disk/by-id/usb-SanDisk_Extreme_AA010610140717164112-0:0 -> ../../sdc
	if lines == "error":
		return "error" # wth go ahead and fail later
	else:
		disk = runcmd_silent('fdisk -l ' + dev + ' | grep GB')
		if disk == "error":
			error("Could not get fdisk data for get_disk_size using " + dev)
		m = re.match(r'(Disk.*:) (.*) (GB,.*)',  disk)
		if m == "error":
			error("Could not get fdisk size from fdisk data, get_disk_size using " + dev)
		# returns in format like "78" or "67.2"
		size = m.group(2)
	if size:
		return size
	else:
		error("Couldn't get disk size of " + dev)


def resizepart(part):
	# resize the partition to full size after recovery
	ptest = runcmd_silent('blkid -t TYPE=ext4 %s'%(part) )
	if ptest == "error":
		print_wrap( "   Something is wrong with the main partition and can't be resized.")
		error("Failure of the partition "  +  part )
	mtest = runcmd_silent('grep \"%s\" /etc/mtab'%(part))
	# testing for mount
	if not mtest == "error":	
		runcmd_silent('umount '  +  part)
		runcmd_silent('e2fsck -f '  +  part)
	resized = runcmd("resize2fs -f "  +  part)
	if resized == "error":
		error("There was a problem resizing "  +  part)

#def check_rerun_on_reboot():
	## if firmware upgrade was successful then a power-cycle was forced
	## firmware_upgrade wrote to bashrc; we need to delete that.
	#try: 
		#runcmd_silent('grep zupgrade /root/.bashrc')
	#except:
		#return
	#runcmd_silent('mv /root/.bashrc.orig /root/.bashrc')
		
def firmware_upgrade():
	# On the zx8100 there are now (4.1.7) two bundles.
	# To figure out which one to use (PAM vs mezzanine)
	# we grep the hpm check in the conf file command list.
	# The PAM has an extra CPLD.
			#-----------PAM model ZX8100----------------------
		#|ID | Name       |             Versions              |
		#|   |            |     Active      |     Backup      |
		#------------------------------------------------------
		#| 0 |IPMC FWW    |   1.13 00000000 |   1.13 00000000 |
		#| 1 |IPMC BootLdr|   1.13 00000000 | ---.-- -------- |
		#| 2 |FRU Infoo   |   1.03 00000000 | ---.-- -------- |
		#| 3 |MAC EEPROMss|   2.00 00000000 | ---.-- -------- |
		#| 4 |FPGA Imagee |   7.00 00000000 | ---.-- -------- |
		#| 5 |CPLD Imagee |  10.00 01020304 | ---.-- -------- |
		#| 6 |CPLD2 Imagee|   2.00 00000000 | ---.-- -------- |
		#| 7 |UEFI FWW    |   2.02 00000000 | ---.-- -------- |
		#----------------------------------------------------- 
	if BOARDNAME == "b1c":
		return
	print_wrap( "\n   Starting firmware upgrade...")
	tarballdir = CONFOBJ.get('data', 'tarball dir')
	mydir = os.path.isdir('../' + tarballdir)
	if mydir == "error":
		error("Unable to upgrade firmware. Did you unpack the tarball in /opt/znyx?")
	this_eth = CONFOBJ.get('data', 'os-to-ipmi-eth')
	this_eth_addr = CONFOBJ.get('data', 'os-to-ipmi-eth-addr')
	ipmi_add = CONFOBJ.get('data', 'ipmi-lan-addr')
	ipmi_channel = CONFOBJ.get('data', 'ipmi-lan-channel')
	orig_ipmi_add = runcmd_silent('ipmitool lan print ' + ipmi_channel + ' | grep "IP Address  " | cut -d: -f2').lstrip()
	orig_this_eth_addr = get_ip(this_eth)
	# clean up bridge
	this_br = CONFOBJ.get('data', 'os-to-ipmi-br')
	runcmd_silent('ifdown ' + this_br )

	print_wrap("   Temporarily setting channel " + ipmi_channel + " on IPMI Lan to " + ipmi_add)
	try:
		runcmd('ipmitool lan set ' + ipmi_channel + ' ipaddr ' + ipmi_add)
		runcmd('ipmitool lan set ' + ipmi_channel + ' netmask 255.255.255.0')
	except:
		error("Unable to upgrade firmware. Can't get or set IP address for IPMI.")
		
	print_wrap("   Temporarily setting " + this_eth + " to " + this_eth_addr)
	try:
		runcmd_silent('ifconfig ' + this_eth + ' up ' + this_eth_addr + ' netmask 255.255.255.0')
	except:
		print_wrap("    Re-setting channel " + ipmi_channel + " on IPMI Lan to " + orig_ipmi_add)
		runcmd('ipmitool lan set ' + ipmi_channel + ' ipaddr ' + orig_ipmi_add)
		error("Unable to upgrade firmware. Can't set IP address for " + this_eth + " the OS-IPMI eth device.")
		
	try:
		runcmd('ping -c 3 ' + ipmi_add  )
	except:
		print_wrap("    Re-setting channel " + ipmi_channel + " on IPMI Lan to original " + orig_ipmi_add)
		runcmd('ipmitool lan set ' + ipmi_channel + ' ipaddr ' + orig_ipmi_add)
		print_wrap("    Re-setting " + this_eth + " to original address " + orig_ipmi_add)
		runcmd_silent('ifconfig ' + this_eth + ' up ' + orig_this_eth_addr + ' netmask 255.255.255.0')
		error("Unable to ping the IPMI LAN address.")

	## make post-reboot line in bashrc; check_rerun_on_reboot() will clean this up
	#addline = 'cd ' + CURRDIR + ' && ' + 'zupgrade.py'
	#print "\n" + addline + "\n"
	#runcmd_silent("cp /root/.bashrc /root/.bashrc.orig")
	#resetlan = 'ipmitool lan set ' + ipmi_channel + ' ipaddr ' + orig_ipmi_add
	#runcmd_silent('echo "' + resetlan + ' >> /root/.bashrc"')
	#runcmd_silent('echo "' + addline + ' >> /root/.bashrc"') 
	#runcmd_noisy('tail /root/.bashrc')

	for (key, command) in CONFOBJ.items('firmware-jobs'):
		try:
			# must change "XsemiX" back to semi-colons
			# due to bug in configparser 2.7
			mycommand = re.sub("XsemiX", ';', command)
			runcmd_silent(mycommand)
		except:
			print_wrap("    Error- Re-setting channel " + ipmi_channel + " on IPMI Lan to original " + orig_ipmi_add)
			runcmd('ipmitool lan set ' + ipmi_channel + ' ipaddr ' + orig_ipmi_add)
			error("Unable to update firmware.")
	# clean up 	
	print_wrap("    Complete. Re-setting channel " + ipmi_channel + " on IPMI Lan to " + orig_ipmi_add)
	runcmd('ipmitool lan set ' + ipmi_channel + ' ipaddr ' + orig_ipmi_add)
	# this is only likely to stick if the system does not reboot; it it reboots, then the init scripts will change it again
	print_wrap("    Re-setting " + this_eth + " to original address " + orig_ipmi_add)
	runcmd_silent('ifconfig ' + this_eth + ' up ' + orig_this_eth_addr + ' netmask 255.255.255.0')
		
def get_ip(iface):
	import socket, fcntl, struct
	sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	sockfd = sock.fileno()
	SIOCGIFADDR = 0x8915
	ifreq = struct.pack('16sH14s', iface, socket.AF_INET, '\x00'*14)
	try:
		res = fcntl.ioctl(sockfd, SIOCGIFADDR, ifreq)
	except:
		return None
	ip = struct.unpack('16sH2x4s8x', res)[2]
	return socket.inet_ntoa(ip)		
		
		
def apt_upgrade():
	global MYLOC, CONFOBJ, BOARDNAME, OLDRELEASE, NEWRELEASE, NETSTATUS
	if not CONFOBJ.get('data', 'apt-get-available'):
		abort("Sorry, upgrading via Debian/Ubuntu packages is not available for this release: " + NEWRELEASE +  " ...")
	if NETSTATUS:
		# when we set NETSTATUS we checked the URLs in sources.list
		logmsg = "Upgrading your "  +  BOARDNAME  +  " currently at OA4 release "  +  OLDRELEASE  +  " to "  +  NEWRELEASE  +  " ..."
		# now upgrade HVs and VMs
		for (key, command) in CONFOBJ.items('apt-jobs'):
			with settings(DEBIAN_FRONTEND='noninteractive'):
				runcmd_noisy(command)
		# add any special VM stuff thats appeared in this release
		if RPLAN == "vm":
			if BOARDNAME == "zx8100":
				if runcmd_silent('grep fab /etc/hostname'):
					for (key, command) in CONFOBJ.items('apt-jobs-vm-fab'):
						with settings(DEBIAN_FRONTEND='noninteractive'):
							runcmd_silent(command)				
				elif runcmd_silent('grep base /etc/hostname'):
					for (key, command) in CONFOBJ.items('apt-jobs-vm-base'):
						with settings(DEBIAN_FRONTEND='noninteractive'):
							runcmd_silent(command) 
		if (NEWRELEASE == "4.1.7") and BOARDNAME == "zx8100" or BOARDNAME == "b1c" or BOARDNAME == "b1n" :
			print_wrap("\n   If you didn't get any errors, reboot, and run the following command to clean up old packages:\n   apt-get purge  -q -y linux-zx9210-headers-3.2.16-4.1.5 linux-zx9210-image-3.2.16-4.1.5 \n")
	else:
		print_wrap("We can't connect to the URLs in /etc/apt/sources.list . You can connect to the Internet or change the URLs and re-run this script, or you can access package *.deb files directly.")
		answer = query_yes_no("   Do you want to upgrade by accessing package files directly?", "no")
		if not answer:
			print_wrap("Exiting to allow you to connect to the Internet or edit sources.list and try again.")
		else:
			abort("dpkg -i package upgrade not designed yet. bye.")
		
def disk_upgrade():
	if RPLAN == "legacy-legacy":
		if MYLOC == '/dev/sda1':
			answer = query_yes_no("   Disk upgrades require you to boot on a USB flashdrive. Do you want to make a bootable USB flashdrive?", "no")
			if answer == False:
				abort("Reboot on your USB flashdrive and run this script there.")
			else:
				create_flashdrive()
				abort("Reboot on your new USB flashdrive, and run this script there.")
	elif RPLAN == "flashdrive":
		if not MYLOC == '/dev/sda1':
			# do it
			ptarget = '/dev/sda1'
			dtarget = '/dev/sda'
			diskfile = getbz2file("entire")
			if os.path.isfile(diskfile) == False:
				error("Can't find the disk image file: " + diskfile + " in this directory.")
			if os.path.isfile('resize-drive') == False:
				error("Can't find the resizing script: resize-drive in this directory.")
			date1 = runcmd('date')
			print_wrap( "\n...Copying the disk image over your main disk with release " + NEWRELEASE + " .     \nTakes about ten minutes...\n   Starting disk copy at: " + date1)
			if NOPBZIP:
				runcmd_noisy('bzip2 -dc '  + CURRDIR + '/' + diskfile + ' | dd bs=32M of=' + dtarget)
			else:
				runcmd_noisy('pbzip2 -dc '  + CURRDIR + '/' + diskfile + ' | dd bs=32M of=' + dtarget)
			print_wrap( "\n   Resizing the drive and resetting UUID...")
			# check for mounted; resize-drive script will fail with error, but this gives better message
			mounted = runcmd_silent('grep ' + ptarget + ' /etc/mtab')
			if not mounted  == "error":
				# actually means "is mounted" ... try umount
				runcmd_noisy('umount ' + ptarget)
				stillmounted = runcmd_silent('grep ' + ptarget + ' /etc/mtab')
				if not stillmounted == "error":	
					## actually means "is mounted" 
					error("The new partition you just copied " + ptarget + " is still mounted. resize-drive can't operate on a mounted partition. Please manually attempt to unmount it or reboot, and run resize-drive manually.")

			runcmd_noisy('./resize-drive ' + dtarget)
			target_release = get_release(ptarget)
			if not NEWRELEASE == target_release:
				if not re.search(r'.*nightly.*', target_release):
					error("Main disk is not at the correct release: " + NEWRELEASE + " \nThe main disk is at " + target_release + " . \nStart the process over with zupgrade.py and make sure you have the correct disk image file in this directory.")
			copy_image_upgrade_files(ptarget)
			print_wrap( "\n   If you got no errors from resizing, you can now reboot on your main hard disk.\n   During the initial boot the drivers will build.\n   This is a one-time event.")
		else:
			error("Unfamiliar location " + MYLOC + " for disk upgrade.")
	else:
		error("Disk_upgrade: disk upgrade for recovery not implemented yet")
		
def create_flashdrive():
	# while on the main partition, create an OA4 flashdrive
	if check_usb_disk(MYLOC) == True: 
		abort("Already running on USB flashdrive: " + MYLOC + " Reboot on the main partition to create a USB flashdrive.")
	usbdisks = get_usb_disks()
	if len(usbdisks) == 0:
		answera = query_yes_no("   No target USB flashdrive device. Insert a USB flashdrive and answer y to continue." , "no")
		if answera == False:
			abort("You chose not to insert a USB flashdrive.")
		else:
			create_flashdrive()
	if not MYLOC == CONFOBJ.get('data', 'mainpart'):
		if  MYLOC == CONFOBJ.get('data', 'recoverpart'):
			error("Reboot to the MAIN partition to create a USB flashdrive. Running on recovery " + MYLOC)
		else:
			error("You are running on an unknown disk: " + MYLOC + " Reboot on the main partition to create a USB flashdrive.")		
	if RPLAN == "legacy-legacy":	
		diskfile = getbz2file("entire")	
	elif RPLAN == "recovery-recovery":
		diskfile = getbz2file("main")
	elif RPLAN == "flashdrive":
		error("Cant run create_flashdrive while booted on the USB flashdrive")
	usbdrive = ''
	target = ''
	if len(usbdisks) > 1:	
		print_wrap( "   You have the following USB flashdrives available:\n")
		for i in usbdisks:
			print_wrap( i )
		print_wrap( "   Please choose which USB flashdrive to create:\n")
		for p in usbdisks:
			answerf = query_yes_no("   Would you like to write over " + p + " to make a bootable USB flashdrive? answer y to choose, n to continue." , "no")	
			if answerf == True:
				usbdrive == p
				break
		if usbdrive == '':
			create_flashdrive()
	else:		
		usbdrive = usbdisks[0]
		if usbdrive == "error":
			error("Can't find a USB flashdrive to use. Did you insert one?")
	# refactor this one! ick.
	tt = re.sub('.*\.\.\/\.\.\/','', usbdrive) # reduce to sdb | sdc
	ts = re.search('.*\/sd\w(\d)', tt)
	dtarget = '' # disk
	ptarget = '' # partition
	if not ts:
		ptarget = '/dev/' + tt + '1'
		dtarget = '/dev/' + tt
	else:
		ptarget = '/dev/' + tt
		dtarget = '/dev/' + tt.rstrip('\d')
	size = get_disk_size(dtarget)
	if not size == "error":
		smaller = alphasort(MINFLASHDRSIZE, size)
		if smaller == size:
			abort( "Your USB flashdrive at " + dtarget + " was not big enough at " + size + "G. \n  ")
	else:
		error("Could not determine USB flashdrive capacity. Check for a USB flashdrive at " + dtarget )
	answer = query_yes_no("   This step will DELETE ALL DATA and partitions on your USB flashdrive at " + ptarget + "\n   are you sure?", "no")
	if answer == False:
		abort( "You decided not to copy over your USB flashdrive.")
	if os.path.isfile(diskfile) == False:
		error("Can't find the disk image file: " + diskfile + " in this directory.")
	if os.path.isfile('resize-drive') == False:
		error("Can't find the resizing script: resize-drive in this directory.")
	date = runcmd('date')
	print_wrap( '\n   * Starting time-consuming procedure at: ' + date + ' *')
	print_wrap( "   Copying over your USB flashdrive with OA4 release " + NEWRELEASE + ".... \n   this will take many minutes...\n\n   * Do not remove your USB flashdrive before copying is complete. *\n")
	if NOPBZIP:
		runcmd_noisy('bzip2 -dc ' + CURRDIR + '/' + diskfile + ' | dd bs=32M of=' + dtarget)
	else:
		runcmd_noisy('pbzip2 -dc ' + CURRDIR + '/' + diskfile + ' | dd bs=32M of=' + dtarget)
	umounted = runcmd_silent('grep ' + ptarget + ' /etc/mtab')
	if not umounted  == "error":
		# actually means "is mounted" ... try umount
		runcmd_noisy('umount ' + ptarget)
		stillmounted = runcmd_silent('grep ' + ptarget + ' /etc/mtab')
		if not stillmounted == "error":	
			## actually means "is mounted" 
			error("The new partition you just copied is still mounted. resize-drive can't operate on a mounted partition. Please manually attempt to unmount it or reboot, and run resize-drive manually.")	
	runcmd_noisy('./resize-drive ' + dtarget)
	target_release = get_release(ptarget)	
	if not NEWRELEASE == target_release:
		if not re.search(r'.*nightly.*', target_release):
			error("USB flashdrive is not at the correct release: " + NEWRELEASE + " \n   The newly-copied USB flashdrive is now at " + target_release + " . \n   Start the process over with zupgrade.py and make sure you have the correct disk image file in this directory.")
	copy_image_upgrade_files( ptarget)
	
	print_wrap( "   You should be able to boot onto the USB flashdrive now.")
	print_wrap( "   The USB flashdrive has a default OA4 install of release " + NEWRELEASE)
	print_wrap( "   You can use the USB flashdrive to disk copy the entire sda disk, or as a staging system when booted elsewhere such as on your PC.")

def alphasort(arg1, arg2):
	#sorts alphanum descending for dates like D140904
	# and versions like 4.5.6
	sortlist=[arg1, arg2]
	sortlist.sort()
	if arg1 == arg2:
		return "equal"	# so we don't eval this case
	if sortlist[0] == arg1:
		return arg1
	else:
		return arg2

	
def copy_image_upgrade_files(dev):
	# copy in needed files when we made a flashdrive from a happy meal
	#Test to see if mounted
	mountpoint = ''
	m = runcmd_silent('grep ' + dev + ' /etc/mtab')
	if m == "error":
		# temp mount it
		runcmd_silent('mkdir -p /tmp/tmpmount')
		runcmd_silent('mount ' + dev + ' /tmp/tmpmount')
		mountpoint = '/tmp/tmpmount'
	else:
		mountpoint = m.split(" ")[1]
	
	if RPLAN == "legacy-legacy":	
		diskfile = getbz2file("entire")	
	elif RPLAN == "recovery-recovery":
		diskfile = getbz2file("main")
	elif RPLAN == "flashdrive":
		diskfile = getbz2file("entire")	
		
	is_there1 = os.path.isfile(mountpoint + '/opt/znyx/' + CONFFILE)	
	if is_there1 == False:
		runcmd_silent('cp ' + CONFFILE + ' ' + mountpoint + '/opt/znyx/')
	is_there2 = os.path.isfile(mountpoint + '/opt/znyx/' + diskfile)	
	if is_there2 == False:
		runcmd_silent('cp ' + diskfile + ' ' + mountpoint + '/opt/znyx/')		
	is_there3 = os.path.isfile(mountpoint + '/opt/znyx/zupgrade.py' )	
	if is_there3 == False:
		runcmd_silent('cp zupgrade.py ' + mountpoint + '/opt/znyx/')	
	if m == "error":	
		runcmd_silent('umount ' + dev)
		
		
def write_recovery():
	if MYLOC == CONFOBJ.get('data', 'mainpart'):
		part1 = getdevice('/dev/sda1')
		if not part1:
			error("No recovery partition /dev/sda1")
		recoverybz2 = getbz2file("recovery")
		print_wrap( "Copying new recovery partition. \nThis will take several minutes...")
		#runcmd("dd bs=32M if="  +  recoverybz2  +  " of=/dev/sda1")
		print_wrap( " cowardly not attempting dd command yet")
	else:
		error("Not running on main partition.")

	
def main():
	global MYLOC, CONFOBJ, BOARDNAME, OLDRELEASE, NEWRELEASE, RPLAN, NETSTATUS, QUIET, MODE
	logmsg = "\nZNYX OA4 upgrade:\n...You are on a ZNYX " +  BOARDNAME  + " \n...booted on this partition: " +  MYLOC  + " \n...and your current release on the main drive is " +  OLDRELEASE  + "\n...and this script can upgrade the " + BOARDNAME + " to the new release " + PDRNUM + " which includes the OA4 release " +  NEWRELEASE  + " \n   See the Release Notes for further information and details.\n"
	print_wrap( logmsg)
	print_wrap( "   Your disks are:\n")
	d = get_disk_info()
	for i in d:	
		print_wrap( i)
	# next figure out what the disk design is 
	if RPLAN == "legacy-recovery":
		msglr = "   An upgrade of the " + BOARDNAME + " to " + NEWRELEASE + " will completely wipe out your entire " + CONFOBJ.get('data', 'mainpart') + " disk in order to install a two-partition system for recovery.\n   ALL DATA WILL BE DELETED. \n   Backup anything you need from here and reboot on the OA4 USB flashdrive. Run this script again from there."
		print_wrap( msglr)
		answer1 = query_yes_no("\n   Do you need to create an OA4 USB flashdrive?", "no")
		if answer1 == False:
			abort( "You decided not to create a USB flashdrive")
		else:
			create_flashdrive()		
	elif RPLAN == "legacy-legacy":
		# added checkfirmware for 4.1.7 because we are doing apt-get now
		answer4 = False
		answer7 = False
		check_firmware()
		if CONFOBJ.get('data', 'apt-get-available'):
			answer7 = query_yes_no("\n   Do you want to upgrade via Debian/Ubuntu packages?", "yes")
			if answer7:
				apt_upgrade()
		if not QUIET:
			answer4 = query_yes_no("\n   Do you want to create an OA4 USB flashdrive?", "no")
			if answer4 == False and answer7 == False:
			# for leagcy-legacy 4.1.5 - 4.1.6 must use disk copy from flashdrive
				abort("To upgrade/reload your main drive, consult the release Notes document. Then run this script again.")
			elif answer4 == False and answer7 == True:	
				return
			elif answer4:
				create_flashdrive()
				return
	elif RPLAN == "flashdrive":
		# first check to see if firmware is correct; error out if not
		if not QUIET:
			check_firmware()
		disk_msg = "\n   Do you wish to disk copy over your entire " + BOARDNAME + " main disk " + CONFOBJ.get('data', 'mainpart') + "? \n   ALL DATA WILL BE DELETED on the main disk, are you sure?"
		if NEWRELEASE == "4.1.6.1":
			print_wrap( "\n...For new release " + NEWRELEASE + " You can upgrade the " + BOARDNAME + " by copying an entire new image over the main disk." + MAINPART + " \n")
			answer6 = query_yes_no(disk_msg, "no")
			if answer6 == True:
				disk_upgrade()
			elif answer6 == False:
				abort("You decided not to upgrade yet.")
		else:
			if MODE == "upgrade":
				error("Quiet mode not available for use on bootable flashdrive")
			print_wrap( "\n...You can upgrade/reload the main disk " + MAINPART + " for the " + BOARDNAME + " by copying an entire new image over it. \n...But, if you want to upgrade an existing " + BOARDNAME + " using packages, without the destructive disk copy, \n   reboot on the main partition, " + MAINPART + " and run this script there.\n")
			answer8 = query_yes_no(disk_msg, "no")
			if answer8 == True:
				disk_upgrade()
			elif answer8 == False:
				abort("You decided not to do a disk copy upgrade.")
	elif RPLAN == "recovery-recovery":
		error(" Two-partition recovery not implemented yet.")
		print_wrap( RPLAN)
		apt_upgrade()	
		write_recovery()
	elif RPLAN == "vm":
		if CONFOBJ.get('data', 'apt-get-available'):
			answer9 = query_yes_no("\n   Do you want to upgrade via Debian/Ubuntu packages?", "yes")
			if answer9:
				apt_upgrade()
	
########## constants ###############
CURRDIR = os.getcwd()
BOARDNAME = getboardname()
CONFFILE = BOARDNAME  +  '-upgrade.conf'
CONFOBJ = getconfig()
MYLOC = getmylocation()
NEWRELEASE = CONFOBJ.get('data', 'release')
PDRNUM = CONFOBJ.get('recipe', 'pdr')
MAINPART = CONFOBJ.get('data', 'mainpart')
VALID_VERSIONS = get_valid_versions()
RPLAN = check_recoveryplan()
NETSTATUS = check_network()
MINFLASHDRSIZE = 13  #  drives show up a little smaller
WIKIDOC_URL = 'https://znyx-tech.com/ds/'
SCRIPTVER = '1'
CURRDIR = os.getcwd()  # cf "/opt/znyx"
OLDRELEASE = get_release(MAINPART) 
MODE = ""		# if -q is used are we upgrading or copying
QUIET = False	# -q
NOPBZIP = False	# whether pbzip2 is available
########### execution begins here ############

if not os.geteuid() == 0:
	error("Script must be run as root")

if not CONFOBJ.get('data', 'platform') == BOARDNAME:
	error("There is a problem with "  +  CONFFILE  +  " file: bad platform.")
	

prepare()

fix_sources_list()
argtest()
check_versions()

main()







print_wrap( "\n   ... End ...")
sys.exit(-1)	
