#!/bin/sh
#
# USBNetwork installer
#
# $Id: install.sh 13159 2016-04-11 15:50:07Z NiLuJe $
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
USBNET_LIBDIR="${USBNET_BASEDIR}/lib"

USBNET_LOG="${USBNET_BASEDIR}/usbnetwork_install.log"

KINDLE_TESTDIR="/usr/local/bin"
KINDLE_USBNETBIN="${KINDLE_TESTDIR}/usbnetwork.sh"
USBNET_USBNETBIN="${USBNET_BINDIR}/usbnetwork.sh"

# Result codes
OK=0
ERR=${OK}

otautils_update_progressbar

# Install our hack's custom content
# But keep the user's custom content...
if [ -d /mnt/us/${HACKNAME} ] ; then
    logmsg "I" "install" "" "our custom directory already exists, checking if we have custom content to preserve"
    # Custom IP config
    if [ -f /mnt/us/${HACKNAME}/etc/config ] ; then
        cfg_expected_md5="3bd24bfeeee223423e4a1b66770c51f9 1e067721e1f7070e93d5b6a0e7836c79 96d41c5b6e33693ed02fda4fecc2cddf dcd76cec212eb8dafe00342615d5d6cc"
        cfg_current_md5=$( md5sum /mnt/us/${HACKNAME}/etc/config | awk '{ print $1; }' )
        cfg_md5_match="false"
        for cur_exp_md5 in ${cfg_expected_md5} ; do
            if [ "${cfg_current_md5}" == "${cur_exp_md5}" ] ; then
                cfg_md5_match="true"
            fi
        done
        if [ "${cfg_md5_match}" != "true" ] ; then
            HACK_EXCLUDE="${HACKNAME}/etc/config"
            logmsg "I" "install" "" "found custom ip config, excluding from archive"
        fi
   fi
fi

otautils_update_progressbar

# Okay, now we can extract it. Since busybox's tar is very limited, we have to use a tmp directory to perform our filtering
logmsg "I" "install" "" "installing custom directory"
# Make sure our xzdec binary is executable first...
chmod +x ./xzdec
./xzdec ${HACKNAME}.tar.xz | tar -xvf -
# Do check if that went well
_RET=$?
if [ ${_RET} -ne 0 ] ; then
    logmsg "C" "install" "code=${_RET}" "failed to extract custom directory in tmp location"
    return 1
fi

otautils_update_progressbar

cd src
# Make a copy of the default config...
cp -f usbnet/etc/config usbnet/etc/config.default
# And now we filter the content to preserve user's custom content
for custom_file in ${HACK_EXCLUDE} ; do
    if [ -f "./${custom_file}" ] ; then
        logmsg "I" "install" "" "preserving custom content (${custom_file})"
        rm -f "./${custom_file}"
    fi
done
# Finally, unleash our filtered dir on the live userstore
cp -af . /mnt/us/
_RET=$?
if [ ${_RET} -ne 0 ] ; then
    logmsg "C" "install" "code=${_RET}" "failure to update userstore with custom directory"
    return 1
fi
cd - >/dev/null
rm -rf src

otautils_update_progressbar

# Here we go
echo >> ${USBNET_LOG}
echo "usbnetwork v${HACKVER}, $( date )" >> ${USBNET_LOG}

otautils_update_progressbar

# Remove our deprecated content
# From simple_usbnet
logmsg "I" "install" "" "removing deprecated files & symlinks (simple_usbnet)"
logmsg "I" "install" "" "removing SSH server symlinks"
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

logmsg "I" "install" "" "removing SSH server config"
if [ -f /usr/local/etc/dropbear/dropbear_rsa_host_key ] ; then
    echo "/usr/local/etc/dropbear/dropbear_rsa_host_key exists, deleting..." >> ${USBNET_LOG}
    rm -f /usr/local/etc/dropbear/dropbear_rsa_host_key >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

logmsg "I" "install" "" "removing SSH server binary"
if [ -f ${KINDLE_TESTDIR}/dropbearmulti ] ; then
    echo "${KINDLE_TESTDIR}/dropbearmulti exists, deleting..." >> ${USBNET_LOG}
    rm -f ${KINDLE_TESTDIR}/dropbearmulti >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

logmsg "I" "install" "" "removing usbnetwork command script"
if [ -f ${KINDLE_TESTDIR}/usbnetwork.sh -a ! -L ${KINDLE_TESTDIR}/usbnetwork.sh ] ; then
    echo "${KINDLE_TESTDIR}/usbnetwork.sh exists and is not a symlink, deleting..." >> ${USBNET_LOG}
    rm -f ${KINDLE_TESTDIR}/usbnetwork.sh >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

# Remove ;usbnetwork command symlink
logmsg "I" "install" "" "removing usbnetwork command symlink"
if [ -L ${KINDLE_USBNETBIN} ] ; then
    echo "symbolic link ${KINDLE_USBNETBIN} -> $( readlink ${KINDLE_USBNETBIN} ) exists, deleting..." >> ${USBNET_LOG}
    rm -f ${KINDLE_USBNETBIN} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

otautils_update_progressbar

# From v0.12.N
logmsg "I" "install" "" "removing deprecated binaries (v0.12.N)"
LIST="sshd sftp-server"
for var in ${LIST} ; do
    if [ -f ${USBNET_BINDIR}/${var} ] ; then
        echo "deprecated binary ${USBNET_BINDIR}/${var} exists, deleting..." >> ${USBNET_LOG}
        rm -f ${USBNET_BINDIR}/${var}
    fi
done

otautils_update_progressbar

# From v0.12.N
logmsg "I" "install" "" "removing deprecated symlinks (v0.12.N)"
var="/usr/bin/scp"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) exists, deleting..." >> ${USBNET_LOG}
    DBM=$( readlink ${var} )
    if [ "${DBM}" = "${USBNET_BINDIR}/dropbearmulti" ] ; then
        rm -f ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    else
        echo "symbolic link is not ours, skipping..." >> ${USBNET_LOG}
    fi
fi

otautils_update_progressbar

# From v0.12.N
logmsg "I" "install" "" "removing deprecated sshd symlink (v0.12.N)"
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

# From v0.21.N
logmsg "I" "install" "" "removing deprecated libraries (v0.21.N)"
LIST="libncurses.so.5 libncursesw.so.5"
for var in ${LIST} ; do
    if [ -f ${USBNET_LIBDIR}/${var} ] ; then
        echo "deprecated library ${USBNET_LIBDIR}/${var} exists, deleting..." >> ${USBNET_LOG}
        rm -f ${USBNET_LIBDIR}/${var}
    fi
done

otautils_update_progressbar

# Make sure our custom binaries are executable
LIST="busybox dropbearmulti htop kindletool kindle_usbnet_addr lsof mosh-client mosh-server rsync scp sftp ssh ssh-add ssh-agent sshfs ssh-keygen ssh-keyscan usbnet-link usbnetwork fbgrab"
for var in ${LIST} ; do
    [ -x ${USBNET_BINDIR}/${var} ] || chmod +x ${USBNET_BINDIR}/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
done

otautils_update_progressbar

LIST="sshd"
for var in ${LIST} ; do
    [ -x ${USBNET_SBINDIR}/${var} ] || chmod +x ${USBNET_SBINDIR}/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
done

otautils_update_progressbar

LIST="sftp-server ssh-keysign ssh-pkcs11-helper"
for var in ${LIST} ; do
    [ -x ${USBNET_LIBEDIR}/${var} ] || chmod +x ${USBNET_LIBEDIR}/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
done

otautils_update_progressbar

# Make sure the /usr/local/bin directory exists
logmsg "I" "install" "" "creating the ${KINDLE_TESTDIR} directory if need be"
[ -d ${KINDLE_TESTDIR} ] || mkdir -p ${KINDLE_TESTDIR} >> ${USBNET_LOG} 2>&1 || exit ${ERR}

otautils_update_progressbar

# Setup SSH server
logmsg "I" "install" "" "installing SSH server"
LIST="/usr/sbin/dropbearmulti /usr/bin/dropbear /usr/bin/dbclient /usr/bin/dropbearkey /usr/bin/dropbearconvert /usr/bin/dbscp"
for var in ${LIST} ; do
    if [ -L ${var} ] ; then
        echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
    else
        if [ -x ${var} ] ; then
            echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
        else
            ln -fs ${USBNET_BINDIR}/dropbearmulti ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        fi
    fi
done

otautils_update_progressbar

# Setup lsof
logmsg "I" "install" "" "installing lsof"
var="/usr/sbin/lsof"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/lsof ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup htop
logmsg "I" "install" "" "installing htop"
var="/usr/bin/htop"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/htop ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup rsync
logmsg "I" "install" "" "installing rsync"
var="/usr/bin/rsync"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/rsync ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup mosh
logmsg "I" "install" "" "installing mosh (server)"
var="/usr/bin/mosh-server"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/mosh-server ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

logmsg "I" "install" "" "installing mosh (client)"
var="/usr/bin/mosh-client"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/mosh-client ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup kindletool
logmsg "I" "install" "" "installing kindletool"
var="/usr/bin/kindletool"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/kindletool ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup fbgrab
logmsg "I" "install" "" "installing fbgrab"
var="/usr/bin/fbgrab"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/fbgrab ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup sshd (OpenSSH)
logmsg "I" "install" "" "installing sshd"
var="/usr/sbin/sshd"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_SBINDIR}/sshd ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup ssh* & sftp* (OpenSSH)
logmsg "I" "install" "" "installing ssh (client & utils)"
LIST="scp sftp ssh ssh-add ssh-agent ssh-keygen ssh-keyscan sshfs"
for var in ${LIST} ; do
    if [ -L /usr/bin/${var} ] ; then
        echo "symbolic link /usr/bin/${var} -> $( readlink /usr/bin/${var} ) already exists, skipping..." >> ${USBNET_LOG}
    else
        if [ -x /usr/bin/${var} ] ; then
            echo "Binary /usr/bin/${var} already exists, skipping..." >> ${USBNET_LOG}
        else
            ln -fs ${USBNET_BINDIR}/${var} /usr/bin/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        fi
    fi
done

otautils_update_progressbar

# Setup strace, ltrace & elfutils tools
logmsg "I" "install" "" "installing strace and friends"
LIST="strace eu-nm eu-objdump eu-readelf eu-strings ltrace"
for var in ${LIST} ; do
    if [ -L /usr/bin/${var} ] ; then
        echo "symbolic link /usr/bin/${var} -> $( readlink /usr/bin/${var} ) already exists, skipping..." >> ${USBNET_LOG}
    else
        if [ -x /usr/bin/${var} ] ; then
            echo "Binary /usr/bin/${var} already exists, skipping..." >> ${USBNET_LOG}
        else
            ln -fs ${USBNET_BINDIR}/${var} /usr/bin/${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
        fi
    fi
done

otautils_update_progressbar

# Setup nano
logmsg "I" "install" "" "installing nano"
var="/usr/bin/nano"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/nano ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup zsh
logmsg "I" "install" "" "installing zsh"
var="/usr/bin/zsh"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/zsh ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup ag
logmsg "I" "install" "" "installing ag"
var="/usr/bin/ag"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/ag ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup tmux
logmsg "I" "install" "" "installing tmux"
var="/usr/bin/tmux"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/tmux ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup objdump
logmsg "I" "install" "" "installing objdump"
var="/usr/bin/objdump"
if [ -L ${var} ] ; then
    echo "symbolic link ${var} -> $( readlink ${var} ) already exists, skipping..." >> ${USBNET_LOG}
else
    if [ -x ${var} ] ; then
        echo "Binary ${var} already exists, skipping..." >> ${USBNET_LOG}
    else
        ln -fs ${USBNET_BINDIR}/objdump ${var} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    fi
fi

otautils_update_progressbar

# Setup ;usbnetwork command script
logmsg "I" "install" "" "setting up usbnetwork command script"
# Save existing script in case it already exists
if [ -f ${KINDLE_USBNETBIN} ] ; then
    echo "${KINDLE_USBNETBIN} exists, saving..." >> ${USBNET_LOG}
    cp ${KINDLE_USBNETBIN} ${USBNET_USBNETBIN}-save.${HACKVER} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
    rm -f ${KINDLE_USBNETBIN} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
fi

# Copy our own script
cp -f ${USBNET_USBNETBIN} ${KINDLE_USBNETBIN} >> ${USBNET_LOG} 2>&1 || exit ${ERR}
chmod 0755 ${KINDLE_USBNETBIN} >> ${USBNET_LOG} 2>&1 || exit ${ERR}

otautils_update_progressbar

# Setup the whole custom mac address stuff...
logmsg "I" "install" "" "computing custom mac address"
# Start by building the NIC part of a MAC address from our S/N
# NOTE: This isn't terribly pretty. Another idea would be to use a 24bit or 16bit hash/checksum, but they're not that common, unfortunately, and I really don't want to trim a larger checksum...
serial="$(cat < /proc/usid)"

# Loop over each char... (can't do C-style for loops...)
i=0
while [ ${i} -lt ${#serial} ] ; do
    # We only care about the device code, and the last four chars
    case "${i}" in
        2 | 3 )
            # Device code
            char="$( echo -n "${serial}" | sed -re "s/(.){$i}(.)(.*?)/\2/g" )"
            # Build our mac...
            mac="${mac}${char}"
        ;;
        12 | 13 | 14 | 15 )
            # Last four chars (sanitize them, they're not in hex)
            char="$( echo -n "${serial}" | sed -re "s/(.){$i}(.)(.*?)/\2/g" )"

            # Convert to hex (full)
            # NOTE: Yep, the single quotes are key here, we want the hex representation of the char, not of an int.
            hex_char="$(printf "%X" "'${char}'")"
            # Then to int...
            int_char="$(printf "%d" "0x${hex_char}")"

            # 71 is G
            if [ ${int_char} -ge 71 ] ; then
                # Dumb it down to one char in the hex range
                dumb_int_char="$(( int_char % 16 ))"

                # And convert it to hex
                char="$(printf "%X" "${dumb_int_char}")"
            fi

            # Keep building our mac...
            mac="${mac}${char}"
        ;;
        * )
            # Dump it
        ;;
    esac

    let "i += 1"
done

echo "S/N ${serial} => NIC ${mac}" >> ${USBNET_LOG}

# Check if our nic mac looks okay...
# Arg 1 is mac to check
is_valid_mac() {
    mac="${1}"

    if printf "%X" "0x${mac}" > /dev/null 2>&1 ; then
        # It's in hex!
        if [ ${#mac} -eq 6 ] ; then
            # It's 24bit!
            return 0
        fi
    fi

    # Huh hoh...
    echo "mac ${mac} is invalid" >> ${USBNET_LOG}
    return 1
}

if is_valid_mac "${mac}" ; then
    echo "mac is valid" >> ${USBNET_LOG}
else
    # Invalid, fallback to default value
    mac="000000"
fi

otautils_update_progressbar

# Then build our tweaked kdb keyfile for volumd...
logmsg "I" "install" "" "building tweaked kdb keyfile"
cat > ${USBNET_BASEDIR}/etc/TURN_ON_NETWORKING_COMMAND << EOF
RG002
40
<DATA>
EOF
echo -n "modprobe g_ether host_addr='EE4900${mac}' dev_addr='EE1900${mac}'" >> ${USBNET_BASEDIR}/etc/TURN_ON_NETWORKING_COMMAND

## Check if our kdb keyfile looks okay
# Arg 1 is the file to check
is_kdb_keyfile_okay()
{
    kdb_key="${1}"

    if [ $(stat -c %s "${kdb_key}") -eq 81 ] ; then
        # Good :)
        return 0
    fi

    # Meep!
    echo "kdb keyfile looks wrong" >> ${USBNET_LOG}
    return 1
}

if is_kdb_keyfile_okay "${USBNET_BASEDIR}/etc/TURN_ON_NETWORKING_COMMAND" ; then
    echo "kdb keyfile looks ok" >> ${USBNET_LOG}
else
    # Looks broken, delete it
    rm -f "${USBNET_BASEDIR}/etc/TURN_ON_NETWORKING_COMMAND"
fi

otautils_update_progressbar

# Setup mac tweaks companion startup script
logmsg "I" "install" "" "installing preinit upstart job"
cp -f ${HACKNAME}-preinit.conf /etc/upstart/${HACKNAME}-preinit.conf >> ${USBNET_LOG} 2>&1 || exit ${ERR}

otautils_update_progressbar

# Setup auto USB network startup script
logmsg "I" "install" "" "installing upstart job"
cp -f ${HACKNAME}.conf /etc/upstart/${HACKNAME}.conf >> ${USBNET_LOG} 2>&1 || exit ${ERR}

otautils_update_progressbar

logmsg "I" "install" "" "cleaning up"
rm -f ${HACKNAME}-preinit.conf ${HACKNAME}.conf ${HACKNAME}.tar.xz xzdec

otautils_update_progressbar

echo "Done!" >> ${USBNET_LOG}
logmsg "I" "install" "" "done"

otautils_update_progressbar

return ${OK}
