# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3_11 python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A modern and easy to use streamable zip file generator"
HOMEPAGE="
	https://github.com/pR0Ps/zipstream-ng/
	https://pypi.org/project/zipstream-ng/
"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~x86"

distutils_enable_tests pytest
