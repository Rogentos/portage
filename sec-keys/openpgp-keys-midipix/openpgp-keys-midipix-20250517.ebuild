# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OpenPGP keys used to sign midipix releases"
HOMEPAGE="https://midipix.org/"
SRC_URI="https://dl.foss21.org/keys/6482133FE45A8A91EEB0733716997AE880F70A46.asc -> ${P}.asc"
S="${WORKDIR}"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"

src_install() {
	local files=( ${A} )
	insinto /usr/share/openpgp-keys
	newins - midipix.asc < <(cat "${files[@]/#/${DISTDIR}/}" || die)
}
