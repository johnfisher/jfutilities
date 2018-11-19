##############################################################################
# Copyright 2013 ZNYX Networks, Inc
# All Rights Reserved.
#
#

# DEVELOPER'S NOTE:
# Do not start this script with "#! /bin/bash".
# Doing so makes the history output null.


# #############################################################################
#
# USER'S NOTE:
#
# This script is used for data collection on the HVs of switches and SBCs.
#
# For example if you have a scenario that can reproduce a problem then:
#       run this script and redirect to file called "before"
#       run your test
#       run this script again and redirect to file called "after"
# gzip the two files before and after and send them to ZNYX
#
# To see command line options supported by this script, specify the -u option:
#       support.sh -u
#
# #############################################################################


# DEVELOPER'S NOTE:
#
# THE SHORT FORM:
#
# To add a command, in the body of the script add a line such as
#       do_cmd [options] cmd parm1 parm2 ...
# or
#       do_rpt_cmd [options] cmd parm1 parm2 ...
#
# See the comments before do_cmd() or do_rpt_cmd() for a description of how to
# limit which platforms the command is executed on, how to change the comments
# printed to describe the command, etc.
#
# If a test is not a single command, or a command that can be run on a list of
# values, make a routine "cmd_xxx()" in the second section of this file, then
# invoke it such as:
#       do_cmd -c "running xxx commands" cmd_xxx
#
#
# MAINTENANCE NOTES:
#
# Identical copies of this script run on all INTEL ZNYX switch HVs and SBCs.
# When the file is changed, all the following files should be updated with
# the same changes. The file is in the package section of source code:
#
#       /opt/znyx/support/hv-support_script.sh

#
# THE LONG FORM
#
# This script runs on all ZNYX INTEL switches that use Broadcom networking chips.
# It is aware of the platform on which is running, and uses several global
# variables to modify behavior as needed.  See below for a description of
# these variables.
#
# This script is organized in to three sections.
#
# - First is a set of common support routines.  The two primary routines are:
#
#       do_cmd()        Runs a single command.  Output is followed by a line
#                       of minuses as a delimiter. The command may be the name
#                       of a routine in this file.
#
#
#   Most of the other routines are support routines for do_cmd().
#   They are not generally invoked in the body of the script.
#   The routines in this section are specified in alphabetical order by routine
#   name.
#
#   In general, routines in this section won't need to be modified as new
#   tests are added to this script.
#
# - Next is a set of routines that execute commands with more complex
#   requirements.  By making routines for these commands the body of the script
#   is simplified.
#
#   Each of the routines in this section is named "cmd_xxx".  They are arranged
#   in alphabetical order by routine name.
#
#   When tests are added that can't be specified as simply "do_cmd xxx" or
#   "do_rpt_cmd xxx", then a new cmd_xxx() routine will be added to this
#   section and invoked from the body of the script.
#
# - The last section is the main body of the script.  It gathers command line
#   options, initializes global variables and runs each of the tests.  The
#   order of tests basically follows the order of previous versions of
#   support.sh.
#
#
# GLOBAL VARIABLES:
#       (Unless otherwise noted, these are set in init_vars().)
#
# ############################################################################


me=${0##*/}                     # get appl name w/o leading path
let pr_dot_interval="3"         # how often print heartbeat dots
let sleep_time="60"             # default delay before rerunning script


# ############################################################################
# Functions
# ############################################################################

# General Support Functions


# chip_type
#       Set globals $chip and $filter based on Broadcom filter chip
#
chip_type()
{
        if [ -z "$chip" ]
        then
                chip=`zstats -i 0 | grep BCM | tr -s "\t" " " | \
                      cut -d " " -f 3 | sed -e "s/BCM//"`
        fi

        case "$chip" in
                56140    | \
                56840 )
                        # known chip type; do nothing
                        :
                        ;;
                * )
                        usage "Error: unknown chip type \"$chip\".\n"
                        ;;
        esac

        filter_type $chip
}

# do_cmd [options] cmd ...
#       Log and execute a command
#
# Options:
#  -c <cmnt>    Specify comment to be passed to pr_comment.  May be empty.
#               Default is "-", which generates "running $cmd".
#  -nc          Specify that null comment is to be passes to pr_comment().
#               Equivalent to "-c ''".
#  -err         Direct stderr to results file.  By default goes to tty.
#  -noerr       Ignore any error output; direct stderr to /dev/null
#  -q           Quiet.  If command generates no output, doesn't display
#               anything, not even that the command was executed.  Negates
#               -err or -noerr; any error output goes to tty.
#  -xc <chip>   Don't do this command on switches with the specified chip
#  -xs <switch> Don't do this command on the specified switch#

do_cmd()
{
        local   cmd
        local   comment
        local   opt_nc
        local   parms
        local   stderr
        local   tmp
        local   quiet

        comment="-"
        stderr=""
        opt_nc=""
        quiet=""
        parms="$*"

        while [ "${1:0:1}" = "-" ] ; do
                case "$1" in
                -c )
                        comment="$2"
                        shift
                        ;;
                -nc )
                        opt_nc="1"
                        comment=""
                        ;;
                -err )
                        stderr=1
                        ;;
                -noerr )
                        stderr=0
                        ;;
                -q )
                        quiet=1
                        stderr=""
                        ;;
                -xc )
                        if [ $2 = $chip ] ; then
                                return
                        fi
                        shift
                        ;;
                -xs )
                        if [ $2 = $switch ] ; then
                                return
                        fi
                        shift
                        ;;
                * )
                        warning "do_cmd $parms Unrecognized option '$1'\n"
                        ;;
                esac
                shift 1
        done

        cmd="$*"

        if [ -n "$quiet" ] ; then
                tmp=`$cmd`
                if [ -z "$tmp" ] ; then
                        return
                fi

                pr_comment "$comment" $cmd
                printf "$tmp\n"
        else
                pr_comment "$comment" $cmd

                case $stderr in
                "" )    $cmd                    ;;
                1 )     $cmd 2>&1               ;;
                0 )     $cmd 2> /dev/null       ;;
                esac
        fi

        if [ -n "$comment" ] ; then
                pr_sep
        elif [ -n "$opt_nc" ] ; then
                printf "\n"
        fi
        pr_dot
}


# init_vars
#       Initialize global variables depending on the switch.
#
init_vars()
{

        pr_dot          # prime timer values

}

# pr_comment "comment" cmd
#       Print a comment, which may be the command, and a secondary separator
#
# If comment is null, do nothing.
# If comment is "-", make comment be "running <cmd>", and print separator line.
# If comment is anything else, print it and separator line.
#
pr_comment()
{
        local   comment
        local   cmd

        comment="$1"
        shift
        cmd="$*"

        case "$comment" in
        "" )    return                          ;;
        "-" )   printf "\nrunning $cmd\n"       ;;
        * )     printf "\n$comment\n"           ;;
        esac

        pr_sep2
}

# pr_dot
#       print heartbeat dot every N seconds
#       (N is controlled by $pr_dot_interval, set above.)
#
# Note: The initial value of $pr_dot__count is set in the main body to be the
# length of the initial "this may take a while" message.  That lets the lines
# of dots all be nice, uniform lengths.
#
pr_dot()
{
        local now
        local x

        if [ -z "$pr_dot__last_time" ] ; then
                pr_dot__last_time=`date +%s`
                let pr_dot__lim="75"    # max dots per line
                return
        fi

        # get number of seconds since last dot
        now=`date +%s`
        let x="$now - $pr_dot__last_time"

        # if it's been a while, print another dot
        if [ $x -ge $pr_dot_interval ] ; then
                (( ++pr_dot__count ))
                if [ $pr_dot__count -gt $pr_dot__lim ] ; then
                        printf "\n" >&2
                        let pr_dot__count="1"
                fi
                printf "." >& 2
                pr_dot__last_time="$now"
        fi
}

# pr_msg message
#       Display message on console and in results file
#
# Message should not include trailing newline.
#
pr_msg()
{
        local   msg

        msg="\n$*\n"
        printf "$msg\n"
        #printf "$msg\n" >& 2
}

# pr_sep
#       print a separator line
#
pr_sep()
{
        printf "%s\n" "-------------------"
}

# pr_sep2
#       print a subordinaite (second level) separator line
#
pr_sep2()
{
        printf "%s\n" "- - - - - - - - - -"
}

# show_vars
#       display global switch-specific variables
#
show_vars()
{
        pr_sep
        printf "switch-specific variables:\n"
        pr_sep2
        printf "%-16s: $switch\n"       "switch"
        printf "%-16s: $chip\n"         "chip"
        printf "%-16s: $filter\n"       "filter"
        printf "%-16s: $sleep_time\n"   "sleep_time"
        printf "%-16s: $repeat\n"       "repeat"
        printf "%-16s: $cpu_list\n"     "cpu_list"
        pr_sep
        printf "\n"

}


# usage [error_message]
#       Display usage information and optional error message
#
# If provided, the error message should include trailing newline.
#
# DEVELOPER'S NOTE:
# usage() info is generated by grep'ing this file for "#usg2" lines.  If new
# options are added, comment them with that string so they will automatically
# be added to usage output.
#
usage()
{
        printf "$*Usage: $me [options]\n"                       >& 2
        printf "  options:\n"                                   >& 2
        grep "#usg2" $0 | grep -v "grep" | sed -e "s/#usg2/#/"  >& 2

        exit
}

# warning message
#       Add "WARNING" to message and display on console and in results file
#
# Message should not include trailing newline.
#
warning()
{
        local   x

        x="###################################################################"
        pr_msg "${x}\nWARNING: $*\n${x}"
}




cmd_ip_route_list()
{
        # show ip route for non-empty tables

        local   i

        i=255
        while [ $i -ge 1 ] ; do
                do_cmd -q ip route list table $i
                let i=$i-1
        done
}




# ############################################################################
# Main body starts here
# ############################################################################

cmd_line="$*"

# get command line options
while [ -n "$1" ] ; do

        # DEVELOPER'S NOTE:  If add more options, remember to append them to
        # $cmd_opts so they'll be passes on if we do a second pass.
        #
        # Any lines that contain "<hash>usg2" will be displayed by usage().
        # The "<hash>usg2" will be shown as simply "#".  ("<hash>" is "#";
        # can't type it directly, or this comment will show in help output.)

        case "$1" in
        -dots )         #usg2 seconds between progress dots (default is 3 secs)
                if [ -z "$2" -o -n "`echo $2 | sed -e 's/[0-9]//g'`" ] ; then
                        usage "Time for -dots missing or not decimal number\n"
                fi
                let pr_dot_interval="$2"
                shift
                cmd_opts="$cmd_opts -dots $pr_dot_interval"
                ;;
        -help | -u )    #usg2 display this usage information
                usage
                ;;
        * )
                usage "Unrecognized option '$1'\n"
                ;;
        esac
        shift 1
done

# do set-up

printf "\n"
printf "Starting at `date`\n"
printf "Command line: $0 $cmd_line\n"
printf "\n"

init_vars                               # set global variables


printf "$msg " >& 2

let pr_dot__count="${#msg} + 1"         # count is length of displayed message

# dump system information

do_cmd  cat /etc/lsb-release
do_cmd ipmitool hpm check
do_cmd uptime
do_cmd top -b -n 5
do_cmd -c "history output" history
do_cmd ifconfig -a
do_cmd ip addr show
do_cmd -c "running ip route list" cmd_ip_route_list
do_cmd route -en
do_cmd arp -an
do_cmd route -Cn
do_cmd netstat -s
do_cmd cat /proc/sys/net/ipv4/ip_forward
do_cmd iptables -L -v
for i in $( ifconfig -a | sed 's/[ \t].*//;/^$/d' | grep eth ) ; do 
        do_cmd ethtool $i
        do_cmd ethtool -i $i
        do_cmd ethtool -s $i
done 

do_cmd free
do_cmd df -h
do_cmd cat /etc/hosts
do_cmd cat /etc/network/interfaces
do_cmd cat /etc/apt/sources.list
do_cmd dpkg -l
do_cmd cat /var/log/apt/history.log
do_cmd -c "dmesg output: last 200 lines" tail -200 /var/log/dmesg

do_cmd uname -a
# haven't found a single set of ps options that shows all of %CPU, %MEM,
# and PPID; ps is quick, so just do it twice
do_cmd ps afxuww
do_cmd ps efwwl
do_cmd virsh list
do_cmd virsh net-list
do_cmd virsh nodedev-list
do_cmd ls -l /etc/libvirt/qemu
do_cmd ls -l /etc/network/znyx
do_cmd ls -l /var/lib/libvirt/images
do_cmd /opt/znyx/support/zdiff-dpkg.py
# quit 

        # log marker message to both results file and tty
        msg="Completed at `date`\n"
        pr_msg "$msg"




printf "\n" >& 2

exit 1
