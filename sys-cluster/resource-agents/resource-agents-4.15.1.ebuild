# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="${P/resource-}"
inherit autotools tmpfiles

DESCRIPTION="Resources pack for Heartbeat / Pacemaker"
HOMEPAGE="http://www.linux-ha.org/wiki/Resource_Agents"
SRC_URI="https://github.com/ClusterLabs/resource-agents/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~hppa x86"
IUSE="doc libnet rgmanager systemd"

RDEPEND="
	sys-apps/iproute2
	sys-apps/which
	>=sys-cluster/cluster-glue-1.0.12-r1
	sys-cluster/libqb:=
	libnet? ( net-libs/libnet:1.1 )
	systemd? ( sys-apps/systemd )
"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-apps/which
	doc? (
		dev-libs/libxml2
		dev-libs/libxslt
		app-text/docbook-xsl-stylesheets
	)
"

PATCHES=(
	"${FILESDIR}/4.6.1-configure.patch"
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	# TODO: fix systemd automagic
	# TODO: python support
	local myeconfargs=(
		--disable-fatal-warnings
		--localstatedir=/var
		# --with-ocf-root needs to be /usr/lib, see bug #720420
		--with-ocf-root=/usr/lib/ocf
		--with-rsctmpdir=/run/resource-agents
		$(use_enable doc)
		$(use_enable libnet)
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	rm -rf "${ED}/usr/lib/ocf/resource.d/redhat" || die
	rm -rf "${ED}"/etc/init.d/ || die
	rm -rf "${ED}"{,/var}/run || die

	use rgmanager || rm -rf "${ED}"/usr/share/cluster/ "${ED}"/var/

	if ! use systemd ; then
		newtmpfiles - resource-agents.conf <<-EOF
		d /var/run/resource-agents 1755 root root
		EOF
	fi
}

pkg_postinst() {
	tmpfiles_process resource-agents.conf

	elog "To use Resource Agents installed in ${EROOT}/usr/lib/ocf/resource.d"
	elog "you have to emerge required runtime dependencies manually."
	elog ""
	elog "Description and dependencies of all Agents can be found on"
	elog "http://www.linux-ha.org/wiki/Resource_Agents"
	elog "or in the documentation of this package."
}
