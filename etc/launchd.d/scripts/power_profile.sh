#!/bin/sh
#
# Modify the power profile based on AC line state.  This script is
# usually called from devd(8).
#
# Arguments: 0x00 (AC offline, economy) or 0x01 (AC online, performance)
#
# $FreeBSD: src/etc/rc.d/power_profile,v 1.7.2.1 2005/12/15 16:47:06 obrien Exp $
#

name="power_profile"
LOGGER="logger -t power_profile -p daemon.notice"

# Set a given sysctl node to a value.
#
# Variables:
# $node: sysctl node to set with the new value
# $value: HIGH for the highest performance value, LOW for the best
#	  economy value, or the value itself.
# $highest_value: maximum value for this sysctl, when $value is "HIGH"
# $lowest_value: minimum value for this sysctl, when $value is "LOW"
#
sysctl_set ()
{
	# Check if the node exists
	if [ -z "$(sysctl -n ${node} 2> /dev/null)" ]; then
		return
	fi

	# Get the new value, checking for special types HIGH or LOW
	case ${value} in
	[Hh][Ii][Gg][Hh])
		value=${highest_value}
		;;
	[Ll][Oo][Ww])
		value=${lowest_value}
		;;
	[Nn][Oo][Nn][Ee])
		return
		;;
	*)
		;;
	esac

	# Set the desired value
	[ -n "${value}" ] && sysctl ${node}=${value}
}

# start here
# used to emulate "requires/provide" functionality
pidfile="/var/run/power_profile.pid"
touch $pidfile

if [ $# -ne 1 ]; then
	err 1 "Usage: $0 [0x00|0x01]"
fi

# Find the next state (performance or economy).
state=$1
case ${state} in
0x01 | '')
	${LOGGER} "changed to 'performance'"
	profile="performance"
	;;
0x00)
	${LOGGER} "changed to 'economy'"
	profile="economy"
	;;
*)
	echo "Usage: $0 [0x00|0x01]"
	exit 1
esac

# Set the various sysctls based on the profile's values.
node="hw.acpi.cpu.cx_lowest"
highest_value="C1"
lowest_value="`(sysctl -n hw.acpi.cpu.cx_supported | \
	awk '{ print "C" split($0, a) }' -) 2> /dev/null`"
eval value=\$${profile}_cx_lowest
sysctl_set

node="dev.cpu.0.freq"
highest_value="`(sysctl -n dev.cpu.0.freq_levels | \
	awk '{ split($0, a, "[/ ]"); print a[1] }' -) 2> /dev/null`"
lowest_value="`(sysctl -n dev.cpu.0.freq_levels | \
	awk '{ split($0, a, "[/ ]"); print a[length(a) - 1] }' -) 2> /dev/null`"
eval value=\$${profile}_cpu_freq
sysctl_set

exit 0
