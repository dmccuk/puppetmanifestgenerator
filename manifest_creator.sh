#!/bin/bash
#set -x

# Script to locally create a manifest using puppet resource
# for local files.


#LOCALDIR=`pwd`
#FILE_HOME=$LOCALDIR/puppetmanifestgenerator
FILE_HOME=/tmp/puppetmanifestgenerator
FILES=$FILE_HOME/files_managed_by_templates.dm
FILE_LINE=$FILE_HOME/files_managed_by_file_line.dm
SERVICES=$FILE_HOME/services_packages.dm
USERS=$FILE_HOME/users_managed_by_puppet.dm
HOST=`/bin/hostname -s`
PUPPET_MOD_NAME=`/bin/hostname -s | awk -F- '{print $1}'`

clean_up()
{
echo " (*) Remove previous target directory"
hostname_remove_any-
/bin/rm -rf /opt/$HOST_
}

hostname_remove_any-()
{
echo " (*) Remove any '-' and change them to '_'"
# Remove any - from the servername and change them to _
echo $HOST > /tmp/hostname.dm
sed -i 's/-/_/g' /tmp/hostname.dm
HOST_=`cat /tmp/hostname.dm`
}

capture_facts()
{
echo " (*) Capture all the facts from the server"
FACTER=`which facter`
$FACTER > /opt/$HOST_/facts.dm
}

default()
{
# The following are captured by default
echo " (*) Capture fstab info by default"
cd /opt/$HOST_/modules/build
MODULE=$PUPPET_MOD_NAME-fstab
echo -e "\n\n\n\n\n\n\n" |puppet module generate $MODULE > /dev/null
mv $MODULE fstab 2> /dev/null
FSTAB="/opt/$HOST_/modules/build/fstab"
echo "#" > $FSTAB/manifests/init.pp
puppet resource mount >> $FSTAB/manifests/init.pp
sed -i 's/^/  /' $FSTAB/manifests/init.pp
sed -i "2 i class fstab {" $FSTAB/manifests/init.pp
sed -i -e '/binfmt_misc/,+3d' $FSTAB/manifests/init.pp
echo "}" >> $FSTAB/manifests/init.pp
}

# Create the directory structure
directory_structure()
{
echo " (*) Create the directory Structure"
mkdir -p /opt/$HOST_/{manifests,modules}
mkdir -p /opt/$HOST_/modules/{build,roles}
cat > /opt/$HOST_/manifests/site.pp << EOF
#
notify { ' This is the $HOST server site.pp ': }

node default {

  include role_$HOST_
  }
EOF
}

# create the environment.conf file
echo " (*) Create the environment config file"
create_environment_conf()
{
cat > /opt/$HOST_/environment.conf << EOF
modulepath = modules/roles:modules/build
config_version = '/bin/echo \$environment'
EOF
}

# Create the templates.
create_templates()
{
echo " (*) Creating templates"
cd /opt/$HOST_/modules/build
while read NAME LOCATION; do
  MODULE=$PUPPET_MOD_NAME-$NAME
  echo -e "\n\n\n\n\n\n\n" |puppet module generate $MODULE > /dev/null
  mv $MODULE $NAME 2> /dev/null
  FS="/opt/$HOST_/modules/build/$NAME"
  mkdir -p $FS/templates
  cat $LOCATION > $FS/templates/$NAME".erb"
  echo "#" > $FS/manifests/init.pp
  puppet resource file $LOCATION >> $FS/manifests/init.pp
  sed -i -e '/mtime/d;/ctime/d;/md5/d;/type/d;/sel/d' $FS/manifests/init.pp
  sed -i "$ i\  content => template(\'$NAME/$NAME.erb\')," $FS/manifests/init.pp
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "2 i class $NAME {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
done <$FILES
}

create_file_line_framework()
{
echo " (*) Creating file_line files"
cd /opt/$HOST_/modules/build
  while read NAME1 LOCATION1; do
  MODULE=$PUPPET_MOD_NAME-$NAME1
  echo -e "\n\n\n\n\n\n\n" |puppet module generate $MODULE > /dev/null
  mv $MODULE $NAME1 2> /dev/null
  FS="/opt/$HOST_/modules/build/$NAME1"
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
echo " (*) Creating service and package files"
cd /opt/$HOST_/modules/build
while read NAME PACKAGE; do
  MODULE=$PUPPET_MOD_NAME-$NAME
  echo -e "\n\n\n\n\n\n\n" |puppet module generate $MODULE > /dev/null
  mv $MODULE $NAME 2> /dev/null
  FS="/opt/$HOST_/modules/build/$NAME"
  echo "#" > $FS/manifests/init.pp
  puppet resource package $PACKAGE >> $FS/manifests/init.pp
  puppet resource service $NAME >> $FS/manifests/init.pp
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "2 i class $NAME {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
done <$SERVICES
}

create_apply_file()
{
echo " (*) Create a local apply file"
echo "#Execute this file to apply back the manifest locally" > /opt/$HOST_/apply.pp
for i in `ls /opt/$HOST_/modules/build`; do echo "puppet apply --modulepath=/opt/$HOST_/modules/build -e \"include $i\"" >> /opt/$HOST_/apply.pp; done
#sed -i -e '/apply.pp/d;/environment.conf/d;/manifests/d' /opt/$HOST_/apply.pp
sed -i -e '/apply.pp/d' /opt/$HOST_/apply.pp
chmod +x /opt/$HOST_/apply.pp
}

create_role()
{
echo " (*) Create the role"
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
echo " (*) Change any hostnames into ::hostname"
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
echo " (*) Create the user management files"
cd /opt/$HOST_/modules/build
MODULE=$PUPPET_MOD_NAME-users
echo -e "\n\n\n\n\n\n\n" |puppet module generate $MODULE > /dev/null
mv $MODULE users 2> /dev/null
while read USER; do
  FS="/opt/$HOST_/modules/build/users"
  echo "#" > $FS/manifests/init.pp
  puppet resource user $USER >> $FS/manifests/init.pp
done <$USERS
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "2 i class users {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
}

complete()
{
echo " (*) Puppet files created"
}

clean_up
hostname_remove_any-
directory_structure
default
create_templates
create_file_line_framework
services_packages
manage_users
create_apply_file
create_environment_conf
replace_hostname_with_facter
create_role
capture_facts
complete
