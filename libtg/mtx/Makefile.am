AUTOMAKE_OPTIONS = subdir-objects

lib_LTLIBRARIES = libmtx.la

nobase_include_HEADERS = \
	include/aes.h \
	include/api.h \
	include/app.h \
	include/buf.h \
	include/cmn.h \
	include/crc.h \
	include/cry.h \
	include/enl.h \
	include/fact.h \
	include/hdl.h \
	include/hsh.h \
	include/log.h \
	include/macro.h \
	include/net.h \
	include/rfc.h \
	include/rsa.h \
	include/scl.h \
	include/sel.h \
	include/setup.h \
	include/sha1.h \
	include/sil.h \
	include/srl.h \
	include/std.h \
	include/stk.h \
	include/tgt.h \
	include/tml.h \
	include/trl.h \
	include/sha256.h \
	include/types.h

libmtx_la_SOURCES = \
	src/aes.c \
	src/api.c \
	src/app.c \
	src/buf.c \
	src/cmn.c \
	src/crc.c \
	src/cry.c \
	src/enl.c \
	src/hdl.c \
	src/hsh.c \
	src/log.c \
	src/net.c \
	src/rfc.c \
	src/rsa.c \
	src/scl.c \
	src/sel.c \
	src/sha1.c \
	src/sil.c \
	src/srl.c \
	src/std.c \
	src/stk.c \
	src/tgt.c \
	src/tml.c \
	src/trl.c \
	src/types.c \
	src/sha256.c \
	src/fact.cpp

if MACOS
libmtx_la_SOURCES += darwin-posix-rt/clock_gettime.c
endif

libmtx_la_CFLAGS = -fPIC
libmtx_la_CPPFLAGS = -fPIC
libmtx_la_LIBADD = -lcrypto
libmtx_la_LDFLAGS = -Wl,-w


#bin_PROGRAMS = mtx
#mtx_SOURCES = src/main.c
#mtx_LDADD = libmtx.la
