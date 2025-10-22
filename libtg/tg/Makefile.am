lib_LTLIBRARIES = libtg.la
libtg_la_CFLAGS = -fPIC
libtg_la_SOURCES = tg.c \
				   connect.c \
				   database.c \
				   auth.c \
				   strerr.c \
				   dialogs.c \
				   messages.c \
				   images.c \
				   peer.c \
				   files.c \
				   chat.c \
				   user.c \
				   channel.c \
				   updates.c \
				   encrypt.c \
				   header.c \
				   transport.c \
				   ack.c \
				   net.c \
				   ntp.c \
				   send_query.c \
				   answer.c \
				   queue.c \
				   ds.c \
				   2fa.c \
				   errors.c \
				   prepare_query.c \
					 ../crypto/pbkdf2.c \
           ../crypto/hsh.c \
           ../crypto/aes.c \
           ../crypto/cmn.c \
           ../crypto/rsa.c

libtg_la_LIBADD = ../tl/*.o ../mtx/src/*.o -lsqlite3 -lcrypto -lz
libtg_la_LDFLAGS = -Wl,-w
if MACOS
libtg_la_SOURCES += darwin-posix-rt/clock_gettime.c
#libtg_la_LIBADD  += ../mtx/darwin-posix-rt/*.o
endif
