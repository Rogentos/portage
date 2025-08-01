# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_OPTIONAL=1
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYTHON_COMPAT=( pypy3_11 python3_{11..14} python3_{13,14}t )

inherit cmake toolchain-funcs flag-o-matic distutils-r1

DESCRIPTION="A data templating language for app and tool developers"
HOMEPAGE="https://jsonnet.org/"
SRC_URI="https://github.com/google/jsonnet/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64 ppc64 ~riscv ~x86"
IUSE="custom-optimization doc examples python test"
RESTRICT="!test? ( test )"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	dev-cpp/nlohmann_json:=
	python? ( ${PYTHON_DEPS} )
"
DEPEND="
	${RDEPEND}
	test? ( dev-cpp/gtest )
"
BDEPEND="
	python? (
		${PYTHON_DEPS}
		${DISTUTILS_DEPS}
		>=dev-python/setuptools-72.2[${PYTHON_USEDEP}]
	)
"

PATCHES=(
	"${FILESDIR}/jsonnet-0.16.0-libdir.patch"
	"${FILESDIR}/jsonnet-0.16.0-cp-var.patch"
)

distutils_enable_tests unittest

src_prepare() {
	cmake_src_prepare
	use python && distutils-r1_src_prepare
}

src_configure() {
	use custom-optimization || replace-flags '-O*' -O3
	tc-export CC CXX

	local mycmakeargs=(
		-DUSE_SYSTEM_JSON=ON
		-DBUILD_STATIC_LIBS=OFF
	)

	if use test; then
		mycmakeargs+=(
			-DBUILD_TESTS=ON
			-DUSE_SYSTEM_GTEST=ON
		)
	else
		mycmakeargs+=(
			-DBUILD_TESTS=OFF
		)
	fi

	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	use python && CMAKE_BUILD_DIR="${BUILD_DIR}" distutils-r1_src_compile
}

src_test() {
	cmake_src_test
	use python && CMAKE_BUILD_DIR="${BUILD_DIR}" distutils-r1_src_test
}

python_test() {
	LD_LIBRARY_PATH="${CMAKE_BUILD_DIR}" "${EPYTHON}" -m unittest python._jsonnet_test -v \
		|| die "Tests failed with ${EPYTHON}"
}

src_install() {
	cmake_src_install
	use python && distutils-r1_src_install

	if use doc; then
		find doc -name '.gitignore' -delete || die
		docinto html
		dodoc -r doc/.
	fi
	if use examples; then
		docinto examples
		dodoc -r examples/.
	fi
}
