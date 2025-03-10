# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=CHOCOLATE
DIST_VERSION=v3.0.2
inherit perl-module

DESCRIPTION="Call methods on native types"

SLOT="0"
KEYWORDS="amd64 x86"

RDEPEND="
	>=dev-perl/Scope-Guard-0.210.0
	>=virtual/perl-version-0.770.0
"
BDEPEND="
	${RDEPEND}
	virtual/perl-ExtUtils-MakeMaker
	test? (
		>=dev-perl/IPC-System-Simple-1.300.0
		>=dev-perl/Test-Fatal-0.17.0
	)
"
