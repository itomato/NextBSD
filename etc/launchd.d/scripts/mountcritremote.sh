#!/bin/sh
#
# Removed dependency from /etc/rc.

# Mount NFS filesystems if present in /etc/fstab
#
# XXX When the vfsload() issues with nfsclient support and related sysctls
# have been resolved, this block can be removed, and the condition that
# skips nfs in the following block (for "other network filesystems") can
# be removed.
#
mountcritremote_precmd()
{
	case "`mount -d -a -t nfs 2> /dev/null`" in
	*mount_nfs*)
		# Handle absent nfs client support
		if ! sysctl vfs.nfs >/dev/null 2>&1; then
			kldload nfsclient || { warn 'nfs mount ' \
			    'requested, but no nfs client in kernel'; \
			    return 1; }
		fi
		;;
	esac
	return 0
}

mountcritremote_start()
{
	# Mount nfs filesystems.
	#
	echo -n 'Mounting NFS file systems:'
	mount -a -t nfs
	echo '.'

	# Mount other network filesystems if present in /etc/fstab.
	case ${extra_netfs_types} in
	[Nn][Oo])
		;;
	*)
		netfs_types="${netfs_types} ${extra_netfs_types}"
		;;
	esac

	for i in ${netfs_types}; do
		fstype=${i%:*}
		fsdecr=${i#*:}

		[ "${fstype}" = "nfs" ] && continue

		case "`mount -d -a -t ${fstype}`" in
		*mount_${fstype}*)
			echo -n "Mounting ${fsdecr} file systems:"
			mount -a -t ${fstype}
			echo '.'
			;;
		esac
	done

	# Cleanup /var again just in case it's a network mount.
	/etc/rc.d/cleanvar reload
	rm -f /var/run/clean_var /var/spool/lock/clean_var
}

# start here
# used to emulate "requires/provide" functionality
pidfile="/var/run/mountcritremote.pid"
touch $pidfile
mountcritremote_precmd
mountcritremote_start
exit 0
