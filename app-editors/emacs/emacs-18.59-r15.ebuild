# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs flag-o-matic multilib

DESCRIPTION="The extensible self-documenting text editor"
HOMEPAGE="https://www.gnu.org/software/emacs/"
SRC_URI="https://ftp.gnu.org/old-gnu/emacs/${P}.tar.gz
	https://dev.gentoo.org/~ulm/emacs/${P}-patches-15.tar.xz"

LICENSE="GPL-1+ GPL-2+ BSD HPND"
SLOT="18"
KEYWORDS="amd64 x86"
IUSE="abi_x86_x32 gui"

RDEPEND="sys-libs/ncurses:0=
	amd64? (
		abi_x86_x32? ( >=sys-libs/ncurses-5.9-r3:0=[abi_x86_x32(-)?] )
		!abi_x86_x32? ( >=sys-libs/ncurses-5.9-r3:0=[abi_x86_32(-)] )
	)
	gui? ( x11-libs/libX11 )"

DEPEND="${RDEPEND}
	gui? (
		x11-base/xorg-proto
		x11-misc/xbitmaps
	)"

BDEPEND="virtual/pkgconfig"
IDEPEND="app-eselect/eselect-emacs"
RDEPEND+=" ${IDEPEND}"

PATCHES=("${WORKDIR}/patch")

src_prepare() {
	default

	# Do not use the sandbox, or the dumped Emacs will be twice as large
	sed -i -e 's:\./temacs.*dump:SANDBOX_ON=0 LD_PRELOAD= env &:' \
		src/ymakefile || die
}

src_configure() {
	# autoconf? What's autoconf? We are living in 1992. ;-)
	local arch
	case ${ARCH} in
		amd64)
			if use abi_x86_x32; then
				arch=x86-x32
				multilib_toolchain_setup x32
			else
				arch=intel386
				multilib_toolchain_setup x86
			fi
			;;
		x86) arch=intel386 ;;
		*) die "Architecture ${ARCH} not yet supported" ;;
	esac
	local cmd="s/\"s-.*\.h\"/\"s-linux.h\"/;s/\"m-.*\.h\"/\"m-${arch}.h\"/"
	use gui && cmd="${cmd};s/.*\(#define HAVE_X_WINDOWS\).*/\1/"
	sed -e "${cmd}" src/config.h-dist >src/config.h || die

	cat <<-END >src/paths.h
		#define PATH_LOADSEARCH "/usr/share/emacs/${PV}/lisp"
		#define PATH_EXEC "/usr/share/emacs/${PV}/etc"
		#define PATH_LOCK "/var/lib/emacs/lock/"
		#define PATH_SUPERLOCK "/var/lib/emacs/lock/!!!SuperLock!!!"
	END

	sed -i -e "s:/usr/lib/\([^ ]*\).o:/usr/$(get_libdir)/\1.o:g" \
		-e "s:-lncurses:$("$(tc-getPKG_CONFIG)" --libs ncurses):" \
		src/s-linux.h || die

	# -O3 and -finline-functions cause segmentation faults at run time;
	# -flto causes a segmentation fault at compile time.
	# -Wno-implicit, -Wno-return-type and -Wno-return-mismatch will
	# quieten newer versions of GCC; feel free to submit a patch adding
	# all those missing prototypes.
	strip-flags
	filter-flags -finline-functions -fpie -flto
	append-flags -std=gnu17 -fno-strict-aliasing -Wno-implicit \
		-Wno-return-type -Wno-return-mismatch
	append-ldflags $(test-flags -no-pie)	#639562
	replace-flags -O[3-9] -O2
}

src_compile() {
	addpredict /var/lib/emacs/lock		#nowarn
	emake --jobs=1 \
		CC="$(tc-getCC)" CFLAGS="${CFLAGS} -Demacs" \
		LD="$(tc-getCC) -nostdlib" LDFLAGS="${LDFLAGS}"
}

src_install() {
	local basedir="/usr/share/emacs/${PV}" i

	dodir ${basedir}
	dodir /usr/share/man/man1
	emake --jobs=1 \
		LIBDIR="${D}"${basedir} \
		BINDIR="${D}"/usr/bin \
		MANDIR="${D}"/usr/share/man/man1 \
		install

	rmdir "${D}"${basedir}/lock || die
	find "${D}"${basedir} -type f \( -name "*.c" -o -name ChangeLog \
		-o -name COPYING ! -path "*/etc/COPYING" \) -exec rm "{}" + || die
	fperms -R go-w ${basedir}

	# remove duplicate DOC file
	rm "${D}"${basedir}/etc/DOC || die

	# move executables to the correct place
	mv "${D}"/usr/bin/emacs{,-${SLOT}} || die
	mv "${D}"/usr/bin/emacsclient{,-emacs-${SLOT}} || die
	rm "${D}"${basedir}/etc/emacsclient || die

	dodir /usr/libexec/emacs/${PV}
	for i in wakeup digest-doc sorted-doc movemail cvtmail fakemail \
		yow env server
	do
		mv "${D}"${basedir}/etc/${i} "${D}"/usr/libexec/emacs/${PV}/${i} || die
		dosym -r /usr/libexec/emacs/${PV}/${i} ${basedir}/etc/${i}
	done
	for i in test-distrib make-docfile; do
		rm "${D}"${basedir}/etc/${i} || die
	done

	# move man page
	mv "${D}"/usr/share/man/man1/emacs{,-${SLOT}}.1 || die

	# move Info files
	dodir /usr/share/info
	mv "${D}"${basedir}/info "${D}"/usr/share/info/emacs-${SLOT} || die
	dosym -r /usr/share/info/emacs-${SLOT} ${basedir}/info
	docompress -x /usr/share/info

	# dissuade Portage from removing our dir file #257260
	touch "${D}"/usr/share/info/emacs-${SLOT}/.keepinfodir

	dodir /var/lib/emacs
	diropts -m0777
	keepdir /var/lib/emacs/lock

	dodoc README PROBLEMS
}

pkg_preinst() {
	# verify that the PM hasn't removed our Info directory index #257260
	local infodir="${ED}/usr/share/info/emacs-${SLOT}"
	[[ -f ${infodir}/dir || ! -d ${infodir} ]] || die
}

pkg_postinst() {
	eselect --root="${ROOT}" emacs update ifunset
}

pkg_postrm() {
	eselect --root="${ROOT}" emacs update ifunset
}
