# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ECM_HANDBOOK="optional"
KFMIN=6.13.0
QTMIN=6.7.2
inherit ecm gear.kde.org xdg

DESCRIPTION="Remote desktop connection (RDP and VNC) client"
HOMEPAGE="https://apps.kde.org/krdc/"

LICENSE="GPL-2" # TODO: CHECK
SLOT="6"
KEYWORDS="amd64 ~arm64 ~ppc64 ~riscv ~x86"
IUSE="activities +rdp +vnc"

#nx? ( >=net-misc/nxcl-0.9-r1 ) disabled upstream, last checked 2016-01-24
DEPEND="
	>=dev-qt/qtbase-${QTMIN}:6[gui,wayland,widgets,xml]
	>=kde-frameworks/kbookmarks-${KFMIN}:6
	>=kde-frameworks/kcmutils-${KFMIN}:6
	>=kde-frameworks/kcompletion-${KFMIN}:6
	>=kde-frameworks/kconfig-${KFMIN}:6
	>=kde-frameworks/kconfigwidgets-${KFMIN}:6
	>=kde-frameworks/kcoreaddons-${KFMIN}:6
	>=kde-frameworks/kcrash-${KFMIN}:6
	>=kde-frameworks/kdnssd-${KFMIN}:6
	>=kde-frameworks/ki18n-${KFMIN}:6
	>=kde-frameworks/kiconthemes-${KFMIN}:6
	>=kde-frameworks/knotifications-${KFMIN}:6
	>=kde-frameworks/knotifyconfig-${KFMIN}:6
	>=kde-frameworks/kservice-${KFMIN}:6
	>=kde-frameworks/kstatusnotifieritem-${KFMIN}:6
	>=kde-frameworks/kwallet-${KFMIN}:6
	>=kde-frameworks/kwidgetsaddons-${KFMIN}:6
	>=kde-frameworks/kwindowsystem-${KFMIN}:6
	>=kde-frameworks/kxmlgui-${KFMIN}:6
	activities? ( kde-plasma/plasma-activities:6 )
	rdp? (
		>=kde-frameworks/kio-${KFMIN}:6
		>=net-misc/freerdp-2.10:3
	)
	vnc? (
		net-libs/libssh:=
		>=net-libs/libvncserver-0.9
	)
"
RDEPEND="${DEPEND}"
RDEPEND+=" || ( >=dev-qt/qtbase-6.10:6[wayland] <dev-qt/qtwayland-6.10:6 )"
BDEPEND="x11-misc/shared-mime-info"

src_configure() {
	local mycmakeargs=(
		$(cmake_use_find_package activities PlasmaActivities)
		-DWITH_RDP=$(usex rdp)
		-DWITH_VNC=$(usex vnc)
	)

	ecm_src_configure
}
