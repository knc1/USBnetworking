#!/bin/sh -e
#
# $Id: build-updates.sh 13420 2016-08-28 21:49:51Z NiLuJe $
#

HACKNAME="usbnet"
HACKDIR="USBNetwork"
PKGNAME="${HACKNAME}"
PKGVER="0.21.N"

# We need kindletool (https://github.com/NiLuJe/KindleTool) in $PATH
if (( $(kindletool version | wc -l) == 1 )) ; then
	HAS_KINDLETOOL="true"
fi

if [[ "${HAS_KINDLETOOL}" != "true" ]] ; then
	echo "You need KindleTool (https://github.com/NiLuJe/KindleTool) to build this package."
	exit 1
fi

# We also need GNU tar
if [[ "$(uname -s)" == "Darwin" ]] ; then
	TAR_BIN="gtar"
else
	TAR_BIN="tar"
fi
if ! ${TAR_BIN} --version | grep "GNU tar" > /dev/null 2>&1 ; then
	echo "You need GNU tar to build this package."
	exit 1
fi

# Go away if we don't have the PW2 tree checked out for the A9 binaries...
if [[ ! -d "../../../PW2_Hacks" ]] ; then
	echo "Skipping USBNetwork build, we're missing the A9 binaries (from the PW2_Hacks tree)"
	exit 1
fi

# Go away if we don't have the USBNetwork tree for the legacy version checked out...
if [[ ! -d "../../../Hacks/USBNetwork" ]] ; then
	echo "Skipping USBNetwork build, we're missing the KUAL extension (from the Hacks tree)"
	exit 1
fi

# Pickup our common stuff... We leave it in our staging wd so it ends up in the source package.
if [[ ! -d "../../Common" ]] ; then
	echo "The tree isn't checked out in full, missing the Common directory..."
	exit 1
fi
# LibOTAUtils 5
cp -f ../../Common/lib/libotautils5 ./libotautils5
# XZ Utils
cp -f ../../Common/bin/xzdec ./xzdec
# LibKH 5
for common_lib in libkh5 ; do
	cp -f ../../Common/lib/${common_lib} ../src/${HACKNAME}/bin/${common_lib}
done

# Make sure we bundle our KUAL extension...
cp -avf ../../../Hacks/USBNetwork/src/extensions ../src/


## Install

# Archive custom directory
export XZ_DEFAULTS="-T 0"
${TAR_BIN} --owner root --group root --exclude-vcs -cvJf ${HACKNAME}.tar.xz ../src/${HACKNAME} ../src/extensions

# Copy the script to our working directory, to avoid storing crappy paths in the update package
cp ../src/install.sh ./
cp ../src/usbnet.conf ./
cp ../src/usbnet-preinit.conf ./

# Build the install package (Touch & PaperWhite)
kindletool create ota2 -d touch -d paperwhite libotautils5 install.sh ${HACKNAME}.tar.xz xzdec usbnet-preinit.conf usbnet.conf Update_${PKGNAME}_${PKGVER}_install_touch_pw.bin

# Remove the Touch & PaperWhite archive
rm -f ./${HACKNAME}.tar.xz

# Build the PaperWhite 2 archive...
${TAR_BIN} --owner root --group root --exclude-vcs -cvf ${HACKNAME}.tar ../src/${HACKNAME} ../src/extensions
# Delete A8 binaries
KINDLE_MODEL_BINARIES="bin/busybox bin/dropbearmulti bin/htop bin/kindletool bin/kindle_usbnet_addr bin/lsof bin/mosh-client bin/mosh-server bin/rsync bin/scp bin/sftp bin/ssh bin/ssh-add bin/ssh-agent bin/sshfs bin/ssh-keygen bin/ssh-keyscan lib/libcrypto.so.1.0.0 lib/libssl.so.1.0.0 libexec/sftp-server libexec/ssh-keysign libexec/ssh-pkcs11-helper sbin/sshd bin/fbgrab bin/strace bin/eu-nm bin/eu-objdump bin/eu-readelf bin/eu-strings bin/ltrace lib/libasm.so.1 lib/libdw.so.1 lib/libelf.so.1 lib/libz.so.1 lib/libpng16.so.16 lib/libncurses.so.6 lib/libncursesw.so.6 lib/libunwind-arm.so.8 lib/libunwind-ptrace.so.0 lib/libunwind.so.8 bin/nano bin/zsh lib/libebl_aarch64.so lib/libebl_arm.so lib/libmagic.so.1 lib/libpcre.so.1 lib/libpcreposix.so.0"
KINDLE_MODEL_BINARIES="${KINDLE_MODEL_BINARIES} lib/zsh/attr.so lib/zsh/cap.so lib/zsh/clone.so lib/zsh/compctl.so lib/zsh/complete.so lib/zsh/complist.so lib/zsh/computil.so lib/zsh/curses.so lib/zsh/datetime.so lib/zsh/deltochar.so lib/zsh/example.so lib/zsh/files.so lib/zsh/langinfo.so lib/zsh/mapfile.so lib/zsh/mathfunc.so lib/zsh/newuser.so lib/zsh/parameter.so lib/zsh/pcre.so lib/zsh/regex.so lib/zsh/rlimits.so lib/zsh/sched.so lib/zsh/stat.so lib/zsh/system.so lib/zsh/termcap.so lib/zsh/terminfo.so lib/zsh/zftp.so lib/zsh/zleparameter.so lib/zsh/zle.so lib/zsh/zprof.so lib/zsh/zpty.so lib/zsh/zselect.so lib/zsh/zutil.so lib/zsh/net/socket.so lib/zsh/net/tcp.so lib/zsh/param/private.so"
KINDLE_MODEL_BINARIES="${KINDLE_MODEL_BINARIES} bin/dircolors bin/ag lib/libevent-2.1.so.5 lib/libevent_core-2.1.so.5 lib/libevent_extra-2.1.so.5 lib/libevent_openssl-2.1.so.5 lib/libevent_pthreads-2.1.so.5 bin/tmux bin/gdb bin/gdbserver bin/objdump"
for my_bin in ${KINDLE_MODEL_BINARIES} ; do
	${TAR_BIN} --delete -vf ${HACKNAME}.tar src/${HACKNAME}/${my_bin}
done
# Append A9 binaries
for my_bin in ${KINDLE_MODEL_BINARIES} ; do
	${TAR_BIN} --transform "s,^PW2_Hacks/${HACKDIR}/,,S" --show-transformed-names -rvf ${HACKNAME}.tar ../../../PW2_Hacks/${HACKDIR}/src/${HACKNAME}/${my_bin}
done
# xz it...
xz ${HACKNAME}.tar

# Speaking of, we need our own xzdec binary, too!
cp -f ../../../PW2_Hacks/Common/bin/xzdec ./xzdec

# Build the install package (Wario)
kindletool create ota2 -d paperwhite2 -d basic -d voyage -d paperwhite3 -d oasis -d basic2 libotautils5 install.sh ${HACKNAME}.tar.xz xzdec usbnet-preinit.conf usbnet.conf Update_${PKGNAME}_${PKGVER}_install_pw2_kt2_kv_pw3_koa_kt3.bin

## Uninstall
# Copy the script to our working directory, to avoid storing crappy paths in the update package
cp ../src/uninstall.sh ./

# Build the install package
kindletool create ota2 -d kindle5 libotautils5 uninstall.sh Update_${PKGNAME}_${PKGVER}_uninstall.bin

## Cleanup
# Remove package specific temp stuff
rm -f ./install.sh ./uninstall.sh ./${HACKNAME}.tar.xz ./xzdec ./usbnet-preinit.conf ./usbnet.conf

# Move our updates
mv -f *.bin ../
