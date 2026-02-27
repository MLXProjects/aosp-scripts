#!/bin/sh
TARGET_PATH="$(realpath .)"

# install host dependencies
# Alpine: (needs community repo)
# apk add screen debootstrap

###
# prepare froyo env
#
# init rootfs
mkdir froyo
debootstrap --arch=i386 precise "$TARGET_PATH/froyo" http://old-releases.ubuntu.com/ubuntu/ || debootstrap --arch=i386 precise "$TARGET_PATH/froyo" http://old-releases.ubuntu.com/ubuntu/
umount "$TARGET_PATH/froyo/proc"
# create sync script
cat > "$TARGET_PATH/froyo/root/sync" <<EOF
#!/bin/sh
cd /root
mkdir froyo
cd froyo
repo init -u https://android.googlesource.com/platform/manifest.git -b froyo --depth=1
repo sync --force-sync --no-clone-bundle --no-tags -j2
EOF
chmod a+x "$TARGET_PATH/froyo/root/sync"
# download JDK
rm -f "$TARGET_PATH/froyo/root/*.deb"
wget --tries=0 -P "$TARGET_PATH/froyo/root" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-bin_1.5.0-22-0ubuntu0.8.04_i386.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-demo_1.5.0-22-0ubuntu0.8.04_i386.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-jdk_1.5.0-22-0ubuntu0.8.04_i386.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-jre_1.5.0-22-0ubuntu0.8.04_all.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/main/j/java-common/java-common_0.43ubuntu4_all.deb"
#### echo -n "Press any key to continue . . . " && read && echo
# install git-repo
wget https://storage.googleapis.com/git-repo-downloads/repo-1 -O "$TARGET_PATH/froyo/usr/bin/repo"
chmod a+x "$TARGET_PATH/froyo/usr/bin/repo"
# disable upstart since it's a chroot
cat > "$TARGET_PATH/froyo/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
exit 101
EOF
chmod a+x "$TARGET_PATH/froyo/usr/sbin/policy-rc.d"
# add repos
cat > "$TARGET_PATH/froyo/etc/apt/sources.list" <<EOF
deb http://old-releases.ubuntu.com/ubuntu precise main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu precise-updates main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu precise-backports main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu precise-security main restricted universe multiverse
EOF
# bind mounts before entering chroot
for f in dev dev/pts proc sys; do
	mount --bind /$f "$TARGET_PATH/froyo/$f"
done
# use setup script inside chroot
cat > "$TARGET_PATH/froyo/root/setup.sh" <<EOF
#!/bin/sh
# set dns
nameserver 8.8.8.8 > /etc/resolv.conf
# get keys & sync repos
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 16126D3A3E5C1192 7F0BB3BE5BF00518 C2518248EEA14886 464AD83D4631BBEA 089EBE08314DF160 B9316A7BC7917B12 EB9B1D8886F44E2A
apt-get update
# install AOSP dependencies
apt-get install -y git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev libc6-dev libncurses5-dev x11proto-core-dev \
  libx11-dev libreadline6-dev libgl1-mesa-dev tofrodos python-markdown \
  libxml2-utils nano wget unixodbc
# install JDK
cd /root
dpkg -r sun-java5-bin sun-java5-jdk sun-java5-jre sun-java5-demo java-common
dpkg -i *.deb
# here was apt-get install -fy
rm -f *.deb
# set aliases
alias apt=apt-get > /root/.bash_aliases
alias cls=clear >> /root/.bash_aliases
# set dummy git account
git config --global user.name dev
git config --global user.email email@example.com
# download aosp
cd /root
./sync
EOF
chmod a+x "$TARGET_PATH/froyo/root/setup.sh"
#### echo -n "Press any key to continue . . . " && read && echo
chroot "$TARGET_PATH/froyo" /bin/bash "/root/setup.sh"
#### echo -n "Press any key to continue . . . " && read && echo
# unbind mounts after finishing
for f in dev/pts dev proc sys; do
	umount "$TARGET_PATH/froyo/$f"
done
#### echo -n "Press any key to continue . . . " && read && echo


###
# prepare gb env
#
# init rootfs
mkdir gb
debootstrap --arch=amd64 precise "$TARGET_PATH/gb" http://old-releases.ubuntu.com/ubuntu/ || debootstrap --arch=amd64 precise "$TARGET_PATH/gb" http://old-releases.ubuntu.com/ubuntu/
umount "$TARGET_PATH/gb/proc"
# create sync script
cat > "$TARGET_PATH/gb/root/sync" <<EOF
#!/bin/sh
cd /root
mkdir gb
cd gb
repo init -u https://android.googlesource.com/platform/manifest.git -b gingerbread --depth=1
repo sync --force-sync --no-clone-bundle --no-tags -j2
EOF
chmod a+x "$TARGET_PATH/gb/root/sync"
# download JDK
rm -f "$TARGET_PATH/gb/root/*.deb"
wget --tries=0 -P "$TARGET_PATH/gb/root" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/ia32-sun-java5-bin_1.5.0-22-0ubuntu0.8.04_amd64.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-bin_1.5.0-22-0ubuntu0.8.04_amd64.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-demo_1.5.0-22-0ubuntu0.8.04_amd64.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-jdk_1.5.0-22-0ubuntu0.8.04_amd64.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/multiverse/s/sun-java5/sun-java5-jre_1.5.0-22-0ubuntu0.8.04_all.deb" \
"http://ftp.twaren.net/ubuntu/ubuntu/pool/main/j/java-common/java-common_0.43ubuntu4_all.deb"
#### echo -n "Press any key to continue . . . " && read && echo
# install git-repo
wget https://storage.googleapis.com/git-repo-downloads/repo-1 -O "$TARGET_PATH/gb/usr/bin/repo"
chmod a+x "$TARGET_PATH/gb/usr/bin/repo"
# disable upstart since it's a chroot
cat > "$TARGET_PATH/gb/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
exit 101
EOF
chmod a+x "$TARGET_PATH/gb/usr/sbin/policy-rc.d"
# add repos
cat > "$TARGET_PATH/gb/etc/apt/sources.list" <<EOF
deb http://old-releases.ubuntu.com/ubuntu precise main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu precise-updates main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu precise-backports main restricted universe multiverse
deb http://old-releases.ubuntu.com/ubuntu precise-security main restricted universe multiverse
EOF
# bind mounts before entering chroot
for f in dev dev/pts proc sys; do
	mount --bind /$f "$TARGET_PATH/gb/$f"
done
# use setup script inside chroot
cat > "$TARGET_PATH/gb/root/setup.sh" <<EOF
#!/bin/sh
# set dns
nameserver 8.8.8.8 > /etc/resolv.conf
# get keys & sync repos
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 16126D3A3E5C1192 7F0BB3BE5BF00518 C2518248EEA14886 464AD83D4631BBEA 089EBE08314DF160 B9316A7BC7917B12 EB9B1D8886F44E2A
apt-get update
#### echo -n "Press any key to continue . . . " && read && echo
# install multiarch dependencies
apt-get install -y gcc-multilib g++-multilib
# install AOSP dependencies
apt-get install -y git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev libc6-dev libncurses5-dev:i386 ia32-libs \
  x11proto-core-dev libx11-dev:i386 libreadline6-dev:i386 libgl1-mesa-glx:i386 \
  libgl1-mesa-dev g++-multilib mingw32 tofrodos python-markdown \
  libxml2-utils xsltproc zlib1g-dev:i386 g++-multilib nano wget unixodbc
#### echo -n "Press any key to continue . . . " && read && echo
# install JDK
cd /root
dpkg -r sun-java5-bin sun-java5-jdk sun-java5-jre sun-java5-demo java-common
dpkg -i *.deb
# here was apt-get install -fy
rm -f *.deb
# set aliases
alias apt=apt-get > /root/.bash_aliases
alias cls=clear >> /root/.bash_aliases
# set dummy git account
git config --global user.name dev
git config --global user.email email@example.com
# download aosp
cd /root
./sync
EOF
chmod a+x "$TARGET_PATH/gb/root/setup.sh"
#### echo -n "Press any key to continue . . . " && read && echo
chroot "$TARGET_PATH/gb" /bin/bash "/root/setup.sh"
#### echo -n "Press any key to continue . . . " && read && echo
# unbind mounts after finishing
for f in dev/pts dev proc sys; do
	umount "$TARGET_PATH/gb/$f"
done
#### echo -n "Press any key to continue . . . " && read && echo

###
# prepare lp env
#
# init rootfs
mkdir lp
#### echo -n "Press any key to continue . . . " && read && echo
debootstrap --arch=amd64 trusty "$TARGET_PATH/lp" http://archive.ubuntu.com/ubuntu/ || debootstrap --arch=amd64 trusty "$TARGET_PATH/lp" http://archive.ubuntu.com/ubuntu/
umount "$TARGET_PATH/lp/proc"
#### echo -n "Press any key to continue . . . " && read && echo
# create sync script
cat > "$TARGET_PATH/lp/root/sync" <<EOF
#!/bin/sh
cd /root
mkdir lp
cd lp
repo init -u https://android.googlesource.com/platform/manifest.git -b android-5.1.1_r38 --depth=1
repo sync --force-sync --no-clone-bundle --no-tags -j2
EOF
chmod a+x "$TARGET_PATH/lp/root/sync"
# install git-repo
wget https://storage.googleapis.com/git-repo-downloads/repo-1 -O "$TARGET_PATH/lp/usr/bin/repo"
chmod a+x "$TARGET_PATH/lp/usr/bin/repo"
# disable upstart since it's a chroot
cat > "$TARGET_PATH/lp/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
exit 101
EOF
chmod a+x "$TARGET_PATH/lp/usr/sbin/policy-rc.d"
# add repos
cat > "$TARGET_PATH/lp/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu/ trusty main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu trusty-security main restricted universe multiverse
EOF
# bind mounts before entering chroot
for f in dev dev/pts proc sys; do
	mount --bind /$f "$TARGET_PATH/lp/$f"
done
# use setup script inside chroot
cat > "$TARGET_PATH/lp/root/setup.sh" <<EOF
#!/bin/sh
# set dns
nameserver 8.8.8.8 > /etc/resolv.conf
# get keys & sync repos
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 16126D3A3E5C1192
apt-get update
# install multiarch dependencies
apt install -y gcc-multilib g++-multilib
# install AOSP dependencies
apt install -y git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
  lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
  libgl1-mesa-dev libxml2-utils xsltproc unzip openjdk-7-jdk nano wget || exit
# set aliases
alias cls=clear >> /root/.bash_aliases
# set dummy git account
git config --global user.name dev
git config --global user.email email@example.com
# download aosp
cd /root
./sync
EOF
chmod a+x "$TARGET_PATH/lp/root/setup.sh"
#### echo -n "Press any key to continue . . . " && read && echo
chroot "$TARGET_PATH/lp" /bin/bash "/root/setup.sh"
#### echo -n "Press any key to continue . . . " && read && echo
# unbind mounts after finishing
for f in dev/pts dev proc sys; do
	umount "$TARGET_PATH/lp/$f"
done
#### echo -n "Press any key to continue . . . " && read && echo

###
# create chroot script
#
cat > "$TARGET_PATH/root" <<EOF
#!/bin/sh
if [ -z "$1" ]; then
	printf "Usage: $0 TARGET\n\tTARGET\tchroot directory\n"
	exit
fi

TARGET=$(dirname "$(realpath -f "$0")")/$1
for f in dev dev/pts proc sys; do
	mount --bind /$f $TARGET/$f
done
chroot $TARGET /bin/login -f root
for f in dev/pts dev proc sys; do
	umount $TARGET/$f
done
EOF
chmod a+x "$TARGET_PATH/root"
