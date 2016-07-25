#!/bin/bash

# Script to locally create a manifest using puppet resource
# for local files.

FILES=files_managed_by_templates.dm
FILE_LINE=files_managed_by_file_line.dm
SERVICES=services_packages.dm
USERS=users_managed_by_puppet.dm
HOST=`/bin/uname -n`

clean_up()
{
/bin/rm -rf /opt/$HOST/*
}

hostname_remove_any-()
{
# Remove any - from the servername and change them to _
echo $HOST > /tmp/hostname.dm
sed -i 's/-/_/g' /tmp/hostname.dm
HOST_=`cat /tmp/hostname.dm`
}

default()
{
# The following are captured by default
  FSTAB="/opt/$HOST_/modules/build/fstab"
  mkdir -p $FSTAB/manifests
  echo > $FSTAB/manifests/init.pp
  puppet resource mount >> $FSTAB/manifests/init.pp
  sed -i 's/^/  /' $FSTAB/manifests/init.pp
  sed -i "1 i class fstab {" $FSTAB/manifests/init.pp
  sed -i -e '/binfmt_misc/,+3d' $FSTAB/manifests/init.pp
  echo "}" >> $FSTAB/manifests/init.pp
}

# Create the directory structure
directory_structure()
{
mkdir -p /opt/$HOST_/{manifests,modules}
mkdir -p /opt/$HOST_/modules/{build,roles}
cat > /opt/$HOST_/manifests/site.pp << EOF
notify { ' This is the VM4 server site.pp ': }

node default {

  include role_$HOST_
}
EOF
}

# create the environment.conf file
create_environment_conf()
{
cat > /opt/$HOST_/environment.conf << EOF
modulepath = modules/roles:modules/build
config_version = '/bin/echo \$environment'
EOF
}

# Create the directory framework.
directory_framework()
{
while read NAME LOCATION; do
  FS="/opt/$HOST_/modules/build/$NAME"
  mkdir -p $FS/{manifests,templates}
  cat $LOCATION > $FS/templates/$NAME".erb"
  echo > $FS/manifests/init.pp
  puppet resource file $LOCATION >> $FS/manifests/init.pp
  sed -i -e '/mtime/d;/ctime/d;/md5/d;/type/d;/sel/d' $FS/manifests/init.pp
  sed -i "$ i\  content  => template(\"$NAME/$NAME.erb\")," $FS/manifests/init.pp
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "1 i class $NAME {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
done <$FILES
}

create_file_line_framework()
{
while read NAME1 LOCATION1; do
  FS="/opt/$HOST_/modules/build/$NAME1"
  mkdir -p $FS/manifests
  echo > $FS/manifests/init.pp
  grep -vE '^(\s*$|#)' $LOCATION1| while read line
    do
      r=$RANDOM
      FIRST=`echo $line | awk '{print $1}'`
      echo "  file_line{'$LOCATION1 $FIRST.$r':" >> $FS/manifests/init.pp
      echo "    path  => '$LOCATION1'," >> $FS/manifests/init.pp
      echo "    line  => '$line'," >> $FS/manifests/init.pp
      echo "    match => '^$FIRST'," >> $FS/manifests/init.pp
      echo "  }" >> $FS/manifests/init.pp
      echo "" >> $FS/manifests/init.pp
    done
  sed -i "1 i class $NAME1 {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
done <$FILE_LINE
}

services_packages()
{
while read NAME PACKAGE; do
  FS="/opt/$HOST_/modules/build/$NAME"
  mkdir -p $FS/manifests
  echo > $FS/manifests/init.pp
  puppet resource package $PACKAGE >> $FS/manifests/init.pp
  puppet resource service $NAME >> $FS/manifests/init.pp
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "1 i class $NAME {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
done <$SERVICES
}

create_apply_file()
{
echo "#Execute this file to apply back the manifest locally" > /opt/$HOST_/apply.pp
for i in `ls /opt/$HOST_/modules/build`; do echo "puppet apply --modulepath=/opt/$HOST_/modules/build -e \"include $i\"" >> /opt/$HOST_/apply.pp; done
#sed -i -e '/apply.pp/d;/environment.conf/d;/manifests/d' /opt/$HOST_/apply.pp
sed -i -e '/apply.pp/d' /opt/$HOST_/apply.pp
chmod +x /opt/$HOST_/apply.pp
}

create_role()
{
ROLE=/opt/$HOST_/modules/roles/role_$HOST_/manifests
mkdir -p $ROLE
echo "#Add this role to your puppet master. Either in hiera or the tool you use to manage your infrastructure" > $ROLE/init.pp
for i in `ls /opt/$HOST_/modules/build`; do echo "  include $i" >> $ROLE/init.pp; done
sed -i -e "/apply.pp/d;/role_$HOST_/d" $ROLE/init.pp
sed -i "2 i class role_$HOST_ { \n" $ROLE/init.pp
echo "}" >> $ROLE/init.pp
}

replace_hostname_with_facter()
{
for i in `find /opt/$HOST_/modules/build/ -name *.erb`
do
grep $HOST $i
  if [ $? == 0 ] ; then
    sed -i -e "s/$HOST/<%= @hostname %>/g" $i
  fi
done
}

manage_users()
{
FS="/opt/$HOST_/modules/build/users"
mkdir -p $FS/manifests
echo > $FS/manifests/init.pp
while read USER; do
  puppet resource user $USER >> $FS/manifests/init.pp
done <$USERS
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "1 i class users {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
}

clean_up
hostname_remove_any-
default
directory_structure
directory_framework
create_file_line_framework
services_packages
manage_users
create_apply_file
create_environment_conf
replace_hostname_with_facter
create_role
