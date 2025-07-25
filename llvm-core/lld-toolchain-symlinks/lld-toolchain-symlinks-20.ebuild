# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib

DESCRIPTION="Symlinks to use LLD on binutils-free system"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:LLVM"
S=${WORKDIR}

LICENSE="public-domain"
SLOT="${PV}"
KEYWORDS="amd64 arm arm64 ~loong ~mips ppc ppc64 ~riscv sparc x86 ~arm64-macos ~x64-macos"
IUSE="multilib-symlinks +native-symlinks"

RDEPEND="
	llvm-core/lld:${SLOT}
"

src_install() {
	use native-symlinks || return

	local chosts=( "${CHOST}" )
	if use multilib-symlinks; then
		local abi
		for abi in $(get_all_abis); do
			chosts+=( "$(get_abi_CHOST "${abi}")" )
		done
	fi

	local dest=/usr/lib/llvm/${SLOT}/bin
	dodir "${dest}"
	dosym ld.lld "${dest}/ld"
	for chost in "${chosts[@]}"; do
		dosym ld.lld "${dest}/${chost}-ld"
	done
}
