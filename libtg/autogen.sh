#!/bin/bash
# File              : autogen.sh
# Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
# Date              : 07.07.2023
# Last Modified Date: 07.07.2023
# Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
#!/bin/sh

echo libtoolize...
libtoolize

echo aclocal...
aclocal

echo automake...
automake --add-missing

echo autoconf...
autoconf

echo config.cache, autom4te.cache...
rm -f config.cache
rm -rf autom4te.cache

echo done
