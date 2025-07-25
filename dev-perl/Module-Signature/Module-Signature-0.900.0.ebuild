# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=TIMLEGGE
DIST_VERSION=0.90
inherit perl-module

DESCRIPTION="Module signature file manipulation"

LICENSE="CC0-1.0 || ( Artistic GPL-2+ )"
SLOT="0"
KEYWORDS="amd64 x86"

RDEPEND="
	app-crypt/gnupg
	dev-perl/Crypt-OpenPGP
"
BDEPEND="
	${RDEPEND}
	>=virtual/perl-ExtUtils-MakeMaker-6.360.0
	test? (
		dev-perl/IPC-Run
	)
"
