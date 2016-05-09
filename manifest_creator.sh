#!/bin/bash

# Script to locally create a manifest using puppet resource
# for local files.

FILES=files.dm
SERVICES=services_packages.dm
HOST=`/bin/uname -n`

# Create the directory framework.
directory_framework()
{
while read NAME LOCATION; do
  FS="/opt/$HOST/$NAME"
  mkdir -p $FS/{manifests,templates}
  cat $LOCATION > $FS/templates/$NAME".erb"
  echo > $FS/manifests/init.pp
  puppet resource file $LOCATION >> $FS/manifests/init.pp
  sed -i -e '/mtime/d;/ctime/d;/md5/d;/type/d;/sel/d' $FS/manifests/init.pp
  sed -i "$ i\  content  => template(\"$NAME/$NAME.erb\")" $FS/manifests/init.pp
  sed -i 's/^/  /' $FS/manifests/init.pp
  sed -i "1 i class $NAME {" $FS/manifests/init.pp
  echo "}" >> $FS/manifests/init.pp
done <$FILES
}

services_packages()
{
while read NAME PACKAGE; do
  FS="/opt/$HOST/$NAME"
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
echo "#Execute this file to apply back the manifest locally" > /opt/$HOST/apply.pp
for i in `ls /opt/$HOST`; do echo "puppet apply --modulepath=/opt/$HOST -e \"include $i\"" >> /opt/$HOST/apply.pp; done
sed -i -e '/apply.pp/d' /opt/$HOST/apply.pp

}

directory_framework
services_packages
create_apply_file
