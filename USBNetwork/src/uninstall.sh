#!/bin/sh
#
# USBNetwork uninstaller
#
# $Id: uninstall.sh 13159 2016-04-11 15:50:07Z NiLuJe $
#
##

HACKNAME="usbnet"

# Pull libOTAUtils for logging & progress handling
[ -f ./libotautils5 ] && source ./libotautils5


HACKVER="0.21.N"

# Directories
USBNET_BASEDIR="/mnt/us/usbnet"
USBNET_BINDIR="${USBNET_BASEDIR}/bin"
USBNET_SBINDIR="${USBNET_BASEDIR}/sbin"
USBNET_LIBEDIR="${USBNET_BASEDIR}/libexec"

USBNET_LOG="${USBNET_BASEDIR}/usbnetwork_install.log"

KINDLE_TESTDIR="/usr/local/bin"
KINDLE_USBNETBIN="${KINDLE_TESTDIR}/usbnetwork.sh"

USBNET_USBNETBIN="${USBNET_BINDIR}/usbnetwork"

# Result codes
OK=0
ERR=${OK}

otautils_update_progressbar

# Remove our deprecated content
# From simple_usbnet
logmsg "I" "uninstall" "" "removing deprecated files & symlinks (simple_usbnet)"
logmsg "I" "uninstall" "" "removing SSH server symlinks"
LIST="${KINDLE_TESTDIR}/dbclient ${KINDLE_TESTDIR}/dropbearconvert ${KINDLE_TESTDIR}/dropbearkey /usr/local/sbin/dropbear ${KINDLE_TESTDIR}/scp"
for var in ${LIST} ; do
    if [ -L ${var} ] ; then
        echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
        DBM=$( readlink ${var} )
        if [ "${DBM}" = "${KINDLE_TESTDIR}/dropbearmulti" ] ; then
            rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        else
            echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
        fi
    fi
done

otautils_update_progressbar

logmsg "I" "uninstall" "" "removing SSH server config"
if [ -f /usr/local/etc/dropbear/dropbear_rsa_host_key ] ; then
    echo "/usr/local/etc/dropbear/dropbear_rsa_host_key exists, deleting..." >> ${USBNET_LOG}
    rm -f /usr/local/etc/dropbear/dropbear_rsa_host_key >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

logmsg "I" "uninstall" "" "removing SSH server binary"
if [ -f ${KINDLE_TESTDIR}/dropbearmulti ] ; then
    echo "${KINDLE_TESTDIR}/dropbearmulti exists, deleting..." >> ${USBNET_LOG}
    rm -f ${KINDLE_TESTDIR}/dropbearmulti >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

logmsg "I" "uninstall" "" "removing usbnetwork command script"
if [ -f ${KINDLE_TESTDIR}/usbnetwork.sh -a ! -L ${KINDLE_TESTDIR}/usbnetwork.sh ] ; then
    echo "${KINDLE_TESTDIR}/usbnetwork.sh exists and is not a symlink, deleting..." >> ${USBNET_LOG}
    rm -f ${KINDLE_TESTDIR}/usbnetwork.sh >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

# Remove ;usbnetwork command symlink
logmsg "I" "uninstall" "" "removing usbnetwork command symlink"
if [ -L ${KINDLE_USBNETBIN} ] ; then
    echo "symbolic link ${KINDLE_USBNETBIN} -> $( readlink ${KINDLE_USBNETBIN} ) exists, deleting..." >> ${USBNET_LOG}
    rm -f ${KINDLE_USBNETBIN} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

# Remove SSH server symlinks
logmsg "I" "uninstall" "" "removing SSH server symlinks"
LIST="/usr/sbin/dropbearmulti /usr/bin/dropbear /usr/bin/dbclient /usr/bin/dropbearkey /usr/bin/dropbearconvert /usr/bin/dbscp /usr/bin/scp"
for var in ${LIST} ; do
    if [ -L ${var} ] ; then
        echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
        DBM=$( readlink ${var} )
        if [ "${DBM}" = "${USBNET_BINDIR}/dropbearmulti" ] ; then
            rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        else
            echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
        fi
    fi
done

otautils_update_progressbar

# Remove lsof symlink
logmsg "I" "uninstall" "" "removing lsof symlink"
var="/usr/sbin/lsof"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/lsof" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove htop symlink
logmsg "I" "uninstall" "" "removing htop symlink"
var="/usr/bin/htop"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/htop" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove rsync symlink
logmsg "I" "uninstall" "" "removing rsync symlink"
var="/usr/bin/rsync"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/rsync" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove mosh symlink
logmsg "I" "uninstall" "" "removing mosh (server) symlink"
var="/usr/bin/mosh-server"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/mosh-server" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

logmsg "I" "uninstall" "" "removing mosh (client) symlink"
var="/usr/bin/mosh-client"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/mosh-client" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove kindletool symlink
logmsg "I" "uninstall" "" "removing kindletool symlink"
var="/usr/bin/kindletool"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/kindletool" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove fbgrab symlink
logmsg "I" "uninstall" "" "removing fbgrab symlink"
var="/usr/bin/fbgrab"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/fbgrab" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove sshd symlink
logmsg "I" "uninstall" "" "removing sshd symlink (deprecated)"
var="/usr/sbin/sshd"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/sshd" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove sshd symlink
logmsg "I" "uninstall" "" "removing sshd symlink"
var="/usr/sbin/sshd"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_SBINDIR}/sshd" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove SSH client & utils symlinks
logmsg "I" "uninstall" "" "removing SSH client & utils symlinks"
LIST="scp sftp ssh ssh-add ssh-agent ssh-keygen ssh-keyscan sshfs"
for var in ${LIST} ; do
    if [ -L /usr/bin/${var} ] ; then
        echo "symbolic link /usr/bin/${var} -> $( readlink /usr/bin/${var} ) exists, deleting..." >> ${USBNET_LOG}
        SYMBIN=$( readlink /usr/bin/${var} )
        if [ "${SYMBIN}" = "${USBNET_BINDIR}/${var}" ] ; then
            rm -f /usr/bin/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        else
            echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
        fi
    fi
done

otautils_update_progressbar

# Remove strace, ltrace & elfutils tools symlinks
logmsg "I" "uninstall" "" "removing strace and friends symlinks"
LIST="strace eu-nm eu-objdump eu-readelf eu-strings ltrace"
for var in ${LIST} ; do
    if [ -L /usr/bin/${var} ] ; then
        echo "symbolic link /usr/bin/${var} -> $( readlink /usr/bin/${var} ) exists, deleting..." >> ${USBNET_LOG}
        SYMBIN=$( readlink /usr/bin/${var} )
        if [ "${SYMBIN}" = "${USBNET_BINDIR}/${var}" ] ; then
            rm -f /usr/bin/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        else
            echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
        fi
    fi
done

otautils_update_progressbar

# Remove nano symlink
logmsg "I" "uninstall" "" "removing nano symlink"
var="/usr/bin/nano"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/nano" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove zsh symlink
logmsg "I" "uninstall" "" "removing zsh symlink"
var="/usr/bin/zsh"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/zsh" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove ag symlink
logmsg "I" "uninstall" "" "removing ag symlink"
var="/usr/bin/ag"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/ag" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove tmux symlink
logmsg "I" "uninstall" "" "removing tmux symlink"
var="/usr/bin/tmux"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/tmux" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Remove objdump symlink
logmsg "I" "uninstall" "" "removing objdump symlink"
var="/usr/bin/objdump"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    SYMBIN=$( readlink ${var} )
    if [ "${SYMBIN}" = "${USBNET_BINDIR}/objdump" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# Delete preinit upstart job
logmsg "I" "uninstall" "" "removing preinit upstart job"
if [ -f /etc/upstart/${HACKNAME}-preinit.conf ] ; then
    echo "/etc/upstart/${HACKNAME}-preinit.conf exists, deleting..." >> ${USBNET_LOG}
    rm -f /etc/upstart/${HACKNAME}-preinit.conf >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

# Delete init upstart job
logmsg "I" "uninstall" "" "removing upstart job"
if [ -f /etc/upstart/${HACKNAME}.conf ] ; then
    echo "/etc/upstart/${HACKNAME}.conf exists, deleting..." >> ${USBNET_LOG}
    rm -f /etc/upstart/${HACKNAME}.conf >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

echo "All done!" >> ${USBNET_LOG}

otautils_update_progressbar

# Remove custom directory in userstore?
logmsg "I" "uninstall" "" "removing kual extension (only if /mnt/us/${HACKNAME}/uninstall exists)"
if [ -d /mnt/us/extensions/${HACKNAME} -a -f /mnt/us/${HACKNAME}/uninstall ] ; then
    rm -rf /mnt/us/extensions/${HACKNAME}
    logmsg "I" "uninstall" "" "kual extension has been removed"
fi
logmsg "I" "uninstall" "" "removing custom directory (only if /mnt/us/${HACKNAME}/uninstall exists)"
if [ -d /mnt/us/${HACKNAME} -a -f /mnt/us/${HACKNAME}/uninstall ] ; then
    rm -rf /mnt/us/${HACKNAME}
    logmsg "I" "uninstall" "" "custom directory has been removed"
fi

otautils_update_progressbar

logmsg "I" "uninstall" "" "done"

otautils_update_progressbar

return ${OK}
