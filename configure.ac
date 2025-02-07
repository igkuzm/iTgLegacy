AC_INIT([iTgLegacy],[1.9])
AM_INIT_AUTOMAKE

AC_PROG_CC
AC_PROG_CXX
AC_PROG_OBJC

AC_CONFIG_HEADER(libtg/config.h)

AC_ARG_WITH([tgtest],
						[AS_HELP_STRING([--with-tgtest],
														[enable tgtest (default=no)])],
						[enable_tgtest=$withval],
						[enable_tgtest=no])
AM_CONDITIONAL([MAKE_TEST], [test "$enable_tgtest" = "yes"])

AS_VAR_IF([INSTALL_NAME_TOOL], [], [ 
	AC_PATH_PROG(INSTALL_NAME_TOOL,install_name_tool,none)
	AS_IF([test x"$INSTALL_NAME_TOOL" == x"none"], 
		[AC_MSG_ERROR([Can't find install_name_tools. Please set INSTALL_NAME_TOOL=])
	])
])
AC_SUBST([INSTALL_NAME_TOOL])

AS_VAR_IF([ZIP], [], [ 
	AC_PATH_PROG(ZIP,zip,none)
	AS_IF([test x"$ZIP" == x"none"], 
		[AC_MSG_ERROR([Please install zip before configuring. Or set ZIP=])
	])
])
AC_SUBST([ZIP])

AS_VAR_IF([ZSIGN], [], [ 
	AC_PATH_PROG(ZSIGN,zsign,none)
	AS_IF([test x"$ZSIGN" == x"none"], 
		[AC_MSG_ERROR([Please install zsign (github:zhlynn/zsign). Or set ZSIGN=])
	])
])
AC_SUBST([ZIP])

AC_CANONICAL_HOST
case "${host_os}" in
    cygwin*|mingw*)
        build_windows=yes;;
    darwin*)
        build_mac=yes;;
    *)
		build_linux=yes;;
esac

case "${host_cpu}" in
    i?86*)
        build_i386=yes;;
    x86_64*)
        build_x86_64=yes;;
    arm64*|aarch64*)
        build_arm64=yes;;
    armv7*)
        build_arm=yes;;
    *)
		;;
esac

AM_CONDITIONAL([LINUX],   [test "$build_linux"   = "yes"])
AM_CONDITIONAL([MACOS],   [test "$build_mac"     = "yes"])
AM_CONDITIONAL([WINDOWS], [test "$build_windows" = "yes"])
AM_CONDITIONAL([WIN32],   [test "$build_windows" = "yes" -a "$build_i386" == "yes"])
AM_CONDITIONAL([WIN64],   [test "$build_windows" = "yes" -a "$build_x86_64" == "yes"])

LT_INIT
AC_CHECK_HEADER([sqlite3.h],[],[AC_MSG_ERROR([Please install sqlite3])],[])
AC_CHECK_HEADER([openssl/ssl.h],[],[AC_MSG_ERROR([Please install openssl])],[])

AC_CONFIG_FILES([
	Makefile
	libtg/Makefile
	libtg/tl_generator/Makefile
	libtg/mtx/Makefile
	libtg/tl/Makefile
	libtg/tg/Makefile
	src/Makefile
])
AC_OUTPUT

echo "**************************************************"
echo "${PACKAGE_NAME}"
echo "**************************************************"
echo "CC = ${CC}"
echo "CXX = ${CXX}"
echo "OBJC = ${OBJC}"
echo "INSTALL_NAME_TOOL = ${INSTALL_NAME_TOOL}"
echo "ZIP = ${ZIP}"
echo "**************************************************"
echo "run make to compile"
