# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: wxwidgets.eclass
# @MAINTAINER:
# wxwidgets@gentoo.org
# @SUPPORTED_EAPIS: 8
# @BLURB: Manages build configuration for wxGTK-using packages.
# @DESCRIPTION:
# This eclass sets up the proper environment for ebuilds using the wxGTK
# libraries.  Ebuilds using wxPython do not need to inherit this eclass.
#
# More specifically, this eclass controls the configuration chosen by the
# ${ESYSROOT}/usr/bin/wx-config wrapper.
#
# Using the eclass is simple:
#
#   - set WX_GTK_VER equal to a SLOT of wxGTK
#   - call setup-wxwidgets()
#
# The configuration chosen is based on the version required and the flags
# wxGTK was built with.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_WXWIDGETS_ECLASS} ]]; then
_WXWIDGETS_ECLASS=1

# @ECLASS_VARIABLE: WX_GTK_VER
# @PRE_INHERIT
# @REQUIRED
# @DESCRIPTION:
# The SLOT of the x11-libs/wxGTK you're targeting.  Needs to be defined before
# inheriting the eclass.  Currently only "3.2-gtk3" is supported.
case ${WX_GTK_VER} in
	3.2-gtk3) ;;
	"") die "WX_GTK_VER not declared" ;;
	*)  die "Invalid WX_GTK_VER: must be set to a valid wxGTK SLOT ('3.2-gtk3')" ;;
esac
readonly WX_GTK_VER

inherit flag-o-matic

# @FUNCTION: setup-wxwidgets
# @DESCRIPTION:
# Call this in your ebuild to set up the environment for wxGTK in src_configure.
# Besides controlling the wx-config wrapper, this exports WX_CONFIG containing
# the path to the config in case it needs to be passed to the build system.
#
# This function also controls the level of debugging output from the libraries.
# Debugging features are enabled by default and need to be disabled at the
# package level.  Because this causes many warning dialogs to pop up during
# runtime, we add -DNDEBUG to CPPFLAGS to disable debugging features (unless
# your ebuild has a debug USE flag and it's enabled).  If you don't like this
# behavior, you can set WX_DISABLE_NDEBUG to override it.
#
# See: https://docs.wxwidgets.org/trunk/overview_debugging.html
setup-wxwidgets() {
	local w wxtoolkit=gtk3 wxconf

	if [[ -z ${WX_DISABLE_NDEBUG} ]]; then
		{ in_iuse debug && use debug; } || append-cppflags -DNDEBUG
	fi

	# toolkit overrides
	if has_version -d "x11-libs/wxGTK:${WX_GTK_VER}[aqua]"; then
		wxtoolkit="mac"
	elif ! has_version -d "x11-libs/wxGTK:${WX_GTK_VER}[X]"; then
		wxtoolkit="base"
	fi

	# Older versions used e.g. 'gtk3-unicode-3.2-gtk3', while we've
	# migrated to the upstream layout of 'gtk3-unicode-3.2' for newer
	# versions when fixing bug #955936.
	if has_version -d "<x11-libs/wxGTK-3.2.8.1:3.2-gtk3"; then
		wxconf="${wxtoolkit}-unicode-${WX_GTK_VER}"
	else
		wxconf="${wxtoolkit}-unicode-${WX_GTK_VER%%-*}"
	fi

	for w in "${CHOST:-${CBUILD}}-${wxconf}" "${wxconf}"; do
		[[ -f ${ESYSROOT}/usr/$(get_libdir)/wx/config/${w} ]] && wxconf=${w} && break
	done || die "Failed to find configuration ${wxconf}"

	export WX_CONFIG="${ESYSROOT}/usr/$(get_libdir)/wx/config/${wxconf}"
	export WX_ECLASS_CONFIG="${WX_CONFIG}"

	einfo
	einfo "Requested wxWidgets:        ${WX_GTK_VER}"
	einfo "Using wxWidgets:            ${wxconf}"
	einfo
}

fi
