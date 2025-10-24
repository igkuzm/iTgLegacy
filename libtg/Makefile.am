SUBDIRS = tl_generator mtx tl tg
ACLOCAL_AMFLAGS = -I m4

#if MAKE_TEST
bin_PROGRAMS = tgtest
tgtest_SOURCES = test.c
tgtest_LDADD = tg/libtg.la -lstdc++ -lsqlite3 -lz
#endif
