#!/bin/bash
# File              : autogen.sh
# Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
# Date              : 07.07.2023
# Last Modified Date: 03.11.2024
# Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
#!/bin/sh

echo aclocal...
aclocal

echo libtool...
libtoolize

echo automake...
automake --add-missing

echo autoconf...
autoconf

echo config.cache, autom4te.cache...
rm -f config.cache
rm -rf autom4te.cache

echo done
