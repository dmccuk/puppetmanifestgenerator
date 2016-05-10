#!/bin/bash

# Script to locally create a manifest using puppet resource
# for local files.

FILES=files_managed_by_templates.dm
FILE_LINE=files_managed_by_file_line.dm
SERVICES=services_packages.dm
HOST=`/bin/uname -n`
HOST_=`cat /tmp/hostname.dm`

hostname_remove_any-()
{
# Remove any - from the servername and change them to _
echo $HOST > /tmp/hostname.dm
sed -i 's/-/_/g' /tmp/hostname.dm
}


# Create the directory framework.
directory_framework()
{
while read NAME LOCATION; do
  FS="/opt/$HOST_/$NAME"
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
  FS="/opt/$HOST_/$NAME1"
  mkdir -p $FS/manifests
  echo > $FS/manifests/init.pp
  grep -vE '^(\s*$|#)' $LOCATION1| while read line
    do
      r=$(( $RANDOM % 10 + 40 ))
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
  FS="/opt/$HOST_/$NAME"
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
for i in `ls /opt/$HOST_`; do echo "puppet apply --modulepath=/opt/$HOST_ -e \"include $i\"" >> /opt/$HOST_/apply.pp; done
sed -i -e '/apply.pp/d' /opt/$HOST_/apply.pp
}

create_role()
{
ROLE=/opt/$HOST_/role_$HOST_/manifest
mkdir -p $ROLE
echo "#Add this role to your puppet master. Either in hiera or the tool you use to manage your infrastructure" > $ROLE/init.pp
for i in `ls /opt/$HOST_`; do echo "  include $i" >> $ROLE/init.pp; done
sed -i -e "/apply.pp/d;/role_$HOST_/d" $ROLE/init.pp
sed -i "2 i class role_$HOST_ { \n" $ROLE/init.pp
echo "}" >> $ROLE/init.pp
}

replace_hostname_with_facter()
{
for i in `find /opt/$HOST_/ -name *.erb`
do
grep $HOST $i
  if [ $? == 0 ] ; then
    sed -i -e "s/$HOST/<%= @hostname %>/g" $i
  fi
done
}


hostname_remove_any-
directory_framework
create_file_line_framework
services_packages
create_apply_file
replace_hostname_with_facter
create_role

