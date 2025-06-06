# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: elisp-common.eclass
# @MAINTAINER:
# Gentoo GNU Emacs project <gnu-emacs@gentoo.org>
# @AUTHOR:
# Matthew Kennedy <mkennedy@gentoo.org>
# Jeremy Maitin-Shepard <jbms@attbi.com>
# Mamoru Komachi <usata@gentoo.org>
# Christian Faulhammer <fauli@gentoo.org>
# Ulrich Müller <ulm@gentoo.org>
# Maciej Barć <xgqt@gentoo.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Emacs-related installation utilities
# @DESCRIPTION:
#
# Usually you want to use this eclass for (optional) GNU Emacs support
# of your package.  This is NOT for XEmacs!
#
# Many of the steps here are sometimes done by the build system of your
# package (especially compilation), so this is mainly for standalone
# elisp files you gathered from somewhere else.
#
# When relying on the emacs USE flag, you need to add
#
# @CODE
# emacs? ( >=app-editors/emacs-25.3:* )
# @CODE
#
# to your DEPEND/RDEPEND line and use the functions provided here to
# bring the files to the correct locations.
#
# If your package requires a minimum Emacs version, e.g. Emacs 26.1,
# then the dependency should be on >=app-editors/emacs-26.1:* instead.
# Because the user can select the Emacs executable with eselect, you
# should also make sure that the active Emacs version is sufficient.
# The eclass will automatically ensure this if you assign variable
# NEED_EMACS with the Emacs version, as in the following example:
#
# @CODE
# NEED_EMACS=26.1
# @CODE
#
# Please note that this should be done only for packages that are known
# to fail with lower Emacs versions.
#
# @SUBSECTION src_compile() usage:
#
# An elisp file is compiled by the elisp-compile() function defined
# here and simply takes the source files as arguments.  The case of
# interdependent elisp files is also supported, since the current
# directory is added to the load-path which makes sure that all files
# are loadable.
#
# @CODE
# elisp-compile *.el
# @CODE
#
# Function elisp-make-autoload-file() can be used to generate a file
# with autoload definitions for the lisp functions.  It takes the output
# file name (default: "${PN}-autoloads.el") and a list of directories
# (default: working directory) as its arguments.  Use of this function
# requires that the elisp source files contain magic ";;;###autoload"
# comments.  See the Emacs Lisp Reference Manual (node "Autoload") for
# a detailed explanation.
#
# @SUBSECTION src_install() usage:
#
# The resulting compiled files (.elc) should be put in a subdirectory of
# /usr/share/emacs/site-lisp/ which is named after the first argument
# of elisp-install().  The following parameters are the files to be put
# in that directory.  Usually the subdirectory should be ${PN}, you can
# choose something else, but remember to tell elisp-site-file-install()
# (see below) the change, as it defaults to ${PN}.
#
# @CODE
# elisp-install ${PN} *.el *.elc
# @CODE
#
# To let the Emacs support be activated by Emacs on startup, you need
# to provide a site file (shipped in ${FILESDIR}) which contains the
# startup code (have a look in the documentation of your software).
# Normally this would look like this:
#
# @CODE
# (add-to-list 'load-path "@SITELISP@")
# (add-to-list 'auto-mode-alist '("\\.csv\\'" . csv-mode))
# (autoload 'csv-mode "csv-mode" "Major mode for csv files." t)
# @CODE
#
# If your Emacs support files are installed in a subdirectory of
# /usr/share/emacs/site-lisp/ (which is strongly recommended), you need
# to extend Emacs' load-path as shown in the first non-comment line.
# The elisp-site-file-install() function of this eclass will replace
# "@SITELISP@" and "@SITEETC@" by the actual paths.
#
# The next line tells Emacs to load the mode opening a file ending
# with ".csv" and load functions depending on the context and needed
# features.  Be careful though.  Commands as "load-library" or "require"
# bloat the editor as they are loaded on every startup.  When having
# many Emacs support files, users may be annoyed by the start-up time.
# Also avoid keybindings as they might interfere with the user's
# settings.  Give a hint in pkg_postinst(), which should be enough.
# The guiding principle is that emerging your package should not by
# itself cause a change of standard Emacs behaviour.
#
# The naming scheme for this site-init file matches the shell pattern
# "[1-8][0-9]*-gentoo*.el", where the two digits at the beginning define
# the loading order (numbers below 10 or above 89 are reserved for
# internal use).  So if your initialisation depends on another Emacs
# package, your site file's number must be higher!  If there are no such
# interdependencies then the number should be 50.  Otherwise, numbers
# divisible by 10 are preferred.
#
# Best practice is to define a SITEFILE variable in the global scope of
# your ebuild (e.g., right after S or RDEPEND):
#
# @CODE
# SITEFILE="50${PN}-gentoo.el"
# @CODE
#
# Which is then installed by
#
# @CODE
# elisp-site-file-install "${FILESDIR}/${SITEFILE}"
# @CODE
#
# in src_install().  Any characters after the "-gentoo" part and before
# the extension will be stripped from the destination file's name.
# For example, a file "50${PN}-gentoo-${PV}.el" will be installed as
# "50${PN}-gentoo.el".  If your subdirectory is not named ${PN}, give
# the differing name as second argument.
#
# For the simple case that only the package's subdirectory needs to be
# added to the load-path, function elisp-make-site-file() will create
# and install a site-init file that does just that:
#
# @CODE
# elisp-make-site-file "${SITEFILE}"
# @CODE
#
# Again, this must be called in src_install().  See the function's
# documentation for more details on its usage.
#
# @SUBSECTION pkg_setup() usage:
#
# If your ebuild uses the elisp-compile eclass function to compile
# its elisp files (see above), then you don't need a pkg_setup phase,
# because elisp-compile and elisp-make-autoload-file do their own sanity
# checks.  On the other hand, if the elisp files are compiled by the
# package's build system, then there is often no check for the Emacs
# version.  In this case, you can add an explicit check in pkg_setup:
#
# @CODE
# elisp-check-emacs-version
# @CODE
#
# When having optional Emacs support, you should prepend "use emacs &&"
# to above call of elisp-check-emacs-version().
#
# @SUBSECTION pkg_postinst() / pkg_postrm() usage:
#
# After that you need to recreate the start-up file of Emacs after
# emerging and unmerging by using
#
# @CODE
# pkg_postinst() {
# 	elisp-site-regen
# }
#
# pkg_postrm() {
# 	elisp-site-regen
# }
# @CODE
#
# Again, with optional Emacs support, you should prepend "use emacs &&"
# to above calls of elisp-site-regen().

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

# @ECLASS_VARIABLE: SITELISP
# @DESCRIPTION:
# Directory where packages install Emacs Lisp files.
SITELISP=/usr/share/emacs/site-lisp

# @ECLASS_VARIABLE: SITEETC
# @DESCRIPTION:
# Directory where packages install miscellaneous (not Lisp) files.
SITEETC=/usr/share/emacs/etc

# @ECLASS_VARIABLE: EMACSMODULES
# @DESCRIPTION:
# Directory where packages install dynamically loaded modules.
# May contain a @libdir@ token which will be replaced by $(get_libdir).
EMACSMODULES=/usr/@libdir@/emacs/modules

# @ECLASS_VARIABLE: EMACS
# @DESCRIPTION:
# Path of Emacs executable.
EMACS=${EPREFIX}/usr/bin/emacs

# @ECLASS_VARIABLE: EMACSFLAGS
# @DESCRIPTION:
# Flags for executing Emacs in batch mode.
# These work for Emacs versions 18-24, so don't change them.
EMACSFLAGS="-batch -q --no-site-file"

# @ECLASS_VARIABLE: BYTECOMPFLAGS
# @DESCRIPTION:
# Emacs flags used for byte-compilation in elisp-compile().
BYTECOMPFLAGS="-L ."

# @ECLASS_VARIABLE: NEED_EMACS
# @DESCRIPTION:
# The minimum Emacs version required for the package.
: "${NEED_EMACS:=25.3}"

# @ECLASS_VARIABLE: _ELISP_EMACS_VERSION
# @INTERNAL
# @DESCRIPTION:
# Cached value of Emacs version detected in elisp-check-emacs-version().
_ELISP_EMACS_VERSION=""

# @FUNCTION: elisp-emacs-version
# @RETURN: exit status of Emacs
# @DESCRIPTION:
# Output version of currently active Emacs.

elisp-emacs-version() {
	local version ret tmout="timeout -k 5 55"
	# Run without timeout if the command is not available
	${tmout} true &>/dev/null || tmout=""
	# The following will work for at least versions 18-24.
	echo "(princ emacs-version)" >"${T}"/emacs-version.el
	version=$(
		# EMACS could be a microemacs variant that ignores the -batch
		# option and would therefore hang, waiting for user interaction.
		# Redirecting stdin and unsetting TERM and DISPLAY will cause
		# most of them to exit with an error.
		unset TERM DISPLAY
		${tmout} ${EMACS} ${EMACSFLAGS} -l "${T}"/emacs-version.el </dev/null
	)
	ret=$?
	rm -f "${T}"/emacs-version.el
	if [[ ${ret} -ne 0 ]]; then
		eerror "elisp-emacs-version: Failed to run ${EMACS}"
		[[ $(realpath ${EMACS} 2>/dev/null) == */emacs* ]] \
			|| eerror "This package needs GNU Emacs"
		return ${ret}
	fi
	if [[ -z ${version} ]]; then
		eerror "elisp-emacs-version: Could not determine Emacs version"
		return 1
	fi
	echo "${version}"
}

# @FUNCTION: elisp-check-emacs-version
# @DESCRIPTION:
# Test if the eselected Emacs version is at least the version of
# GNU Emacs specified in the NEED_EMACS variable, or die otherwise.

elisp-check-emacs-version() {
	if [[ -z ${_ELISP_EMACS_VERSION} ]]; then
		local have_emacs
		have_emacs=$(elisp-emacs-version) \
			|| die "Could not determine Emacs version"
		einfo "Emacs version: ${have_emacs}"
		if [[ ${have_emacs} =~ XEmacs|Lucid ]]; then
			die "XEmacs detected. This package needs GNU Emacs."
		fi
		# GNU Emacs versions have only numeric components.
		if ! [[ ${have_emacs} =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
			die "Malformed version string: ${have_emacs}"
		fi
		_ELISP_EMACS_VERSION=${have_emacs}
	fi

	if ! ver_test "${_ELISP_EMACS_VERSION}" -ge "${NEED_EMACS}"; then
		eerror "This package needs at least Emacs ${NEED_EMACS}."
		eerror "Use \"eselect emacs\" to select the active version."
		die "Emacs version too low"
	fi
}

# @FUNCTION: elisp-compile
# @USAGE: <list of elisp files>
# @DESCRIPTION:
# Byte-compile Emacs Lisp files.
#
# This function uses GNU Emacs to byte-compile all ".el" specified by
# its arguments.  The resulting byte-code (".elc") files are placed in
# the same directory as their corresponding source file.
#
# The current directory is added to the load-path.  This will ensure
# that interdependent Emacs Lisp files are visible between themselves,
# in case they require or load one another.

elisp-compile() {
	elisp-check-emacs-version

	ebegin "Compiling GNU Emacs Elisp files"
	${EMACS} ${EMACSFLAGS} ${BYTECOMPFLAGS} -f batch-byte-compile "$@"
	eend $? "elisp-compile: batch-byte-compile failed" || die
}

# @FUNCTION: elisp-make-autoload-file
# @USAGE: [output file] [list of directories]
# @DESCRIPTION:
# Generate a file with autoload definitions for the lisp functions.

elisp-make-autoload-file() {
	local f="${1:-${PN}-autoloads.el}" null="" page=$'\f'
	shift
	elisp-check-emacs-version

	ebegin "Generating autoload file for GNU Emacs"

	cat >"${f}" <<-EOF
	;;; ${f##*/} --- autoloads for ${PN}  -*-lexical-binding:t-*-

	;;; Commentary:
	;; Automatically generated by elisp-common.eclass
	;; DO NOT EDIT THIS FILE

	;;; Code:
	${page}
	;; Local ${null}Variables:
	;; version-control: never
	;; no-byte-compile: t
	;; no-update-autoloads: t
	;; End:

	;;; ${f##*/} ends here
	EOF

	${EMACS} ${EMACSFLAGS} \
		--eval "(require 'autoload)" \
		--eval "(setq make-backup-files nil)" \
		--eval "(setq generated-autoload-file (expand-file-name \"${f}\"))" \
		-f batch-update-autoloads "${@-.}"

	eend $? "elisp-make-autoload-file: batch-update-autoloads failed" || die
}

# @FUNCTION: elisp-org-export-to
# @USAGE: <export file type> <Org file path>
# @DESCRIPTION:
# Use Emacs Org "export-to" functions to convert a given Org file to a
# picked format.
#
# Example:
# @CODE
# elisp-org-export-to texinfo README.org
# mv README.texi ${PN}.texi || die
# @CODE

elisp-org-export-to() {
	local export_format="${1}"
	local org_file_path="${2}"

	local export_group
	case ${export_format} in
		info) export_group=texinfo ;;  # Straight to ".info".
		markdown) export_group=md ;;
		pdf) export_group=latex ;;
		*) export_group=${export_format} ;;
	esac

	# export_format = texinfo    =>  org-texinfo-export-to-texinfo
	# export_format = pdf        =>  org-latex-export-to-pdf

	local export_function=org-${export_group}-export-to-${export_format}

	${EMACS} ${EMACSFLAGS} "${org_file_path}" -f "${export_function}" \
		|| die "Org export to ${export_format} failed"
}

# @FUNCTION: elisp-test-buttercup
# @USAGE: [test-subdirectory] [test-runner-opts] ...
# @DESCRIPTION:
# Run ELisp package tests using the "buttercup" test runner.
#
# The option "test-subdirectory" may be given any number of times,
# it should be given as though it was passed to Emacs or the test tool,
# not as a string.
#
# The options "test-subdirectory" and "test-runner-opts" are optional,
# but if "test-runner-opts" needs to be provided also "test-subdirectory"
# has to be specified.

elisp-test-buttercup() {
	debug-print-function ${FUNCNAME} "$@"

	local test_dir="${1:-$(pwd)}"
	shift

	local -a myopts=(
		${BYTECOMPFLAGS}
		-L "${test_dir}"
		--traceback full
		"$@"
	)
	ebegin "Running buttercup tests"
	buttercup "${myopts[@]}" "${test_dir}"
	eend $? "${FUNCNAME}: tests failed" || die
}

# @FUNCTION: elisp-test-ert-runner
# @USAGE: [test-subdirectory] [test-runner-opts] ...
# @DESCRIPTION:
# Run ELisp package tests using the "ert-runner" test runner.
#
# The option "test-subdirectory" may be given any number of times,
# it should be given as though it was passed to Emacs or the test tool,
# not as a string.
#
# The options "test-subdirectory" and "test-runner-opts" are optional,
# but if "test-runner-opts" needs to be provided also "test-subdirectory"
# has to be specified.

elisp-test-ert-runner() {
	debug-print-function ${FUNCNAME} "$@"

	local test_dir="${1:-$(pwd)}"
	shift

	local -a myopts=(
		${BYTECOMPFLAGS}
		--reporter ert+duration
		--script
		-L "${test_dir}"
		"$@"
	)
	ebegin "Running ert-runner tests"
	ert-runner "${myopts[@]}" "${test_dir}"
	eend $? "${FUNCNAME}: tests failed" || die
}

# @FUNCTION: elisp-test-ert
# @USAGE: [test-subdirectory] [test-runner-opts] ...
# @DESCRIPTION:
# Run ELisp package tests using "ert", the Emacs's built-in test runner.
#
# The option "test-subdirectory" may be given any number of times,
# it should be given as though it was passed to Emacs or the test tool,
# not as a string.
#
# The options "test-subdirectory" and "test-runner-opts" are optional,
# but if "test-runner-opts" needs to be provided also "test-subdirectory"
# has to be specified.

elisp-test-ert() {
	debug-print-function ${FUNCNAME} "$@"

	local test_dir="${1:-$(pwd)}"
	shift

	local -a extra_load=()
	local extra_load_file
	for extra_load_file in "${test_dir}"/?*-test.el; do
		if [[ -f "${extra_load_file}" ]]; then
			extra_load+=( -l "${extra_load_file}" )
		fi
	done

	local -a myopts=(
		${EMACSFLAGS}
		${BYTECOMPFLAGS}
		-L "${test_dir}"
		"${extra_load[@]}"
		"$@"
		-f ert-run-tests-batch-and-exit
	)
	ebegin "Running ert tests"
	${EMACS} "${myopts[@]}"
	eend $? "${FUNCNAME}: tests failed" || die
}

# @FUNCTION: elisp-enable-tests
# @USAGE: [--optional] <test-runner> [test-runner-options] ...
# @DESCRIPTION:
# Set up IUSE, RESTRICT, BDEPEND and test runner function for running
# tests with the specified test runner.
#
# The test-runner argument must be one of:
#
# - buttercup: for "buttercup" provided via "app-emacs/buttercup"
#
# - ert-runner: for "ert-runner" provided via "app-emacs/ert-runner"
#
# - ert: for built-in GNU Emacs test utility
#
# If the "--optional" flag is passed (before specifying the test
# runner), then it is assumed that the ELisp package is a part of some
# some project that optionally enables GNU Emacs support.  This will
# correctly set up the test and Emacs dependencies.
#
# Notice that the first option passed to the "test-runner" is the
# directory and the rest are miscellaneous options applicable to that
# given runner.
#
# This function has to be called post inherit, specifically after
# "IUSE", "RESTRICT" and "BDEPEND" variables are assigned.
# It is advised to place this call right before (re)defining a given
# ebuild's phases.
#
# Example:
# @CODE
# inherit elisp-common
#
# ...
#
# elisp-enable-tests --optional ert-runner "${S}"/elisp -t "!org"
#
# src_test() {
# 	emake -C tests test
# 	elisp-test
# }
# @CODE

elisp-enable-tests() {
	debug-print-function ${FUNCNAME} "$@"

	local optional
	if [[ ${1} = "--optional" ]] ; then
		optional=YES
		shift
	fi

	local test_pkg
	local test_runner=${1}
	shift

	_ELISP_TEST_OPTS=( "$@" )

	case ${test_runner} in
		buttercup )
			test_pkg="app-emacs/buttercup"
			_ELISP_TEST_FUNCTION=elisp-test-buttercup
			;;
		ert-runner )
			test_pkg="app-emacs/ert-runner"
			_ELISP_TEST_FUNCTION=elisp-test-ert-runner
			;;
		ert )
			_ELISP_TEST_FUNCTION=elisp-test-ert
			;;
		* )
			die "${FUNCNAME}: unknown test runner, given ${test_runner}"
			;;
	esac

	if [[ ${test_pkg} ]]; then
		IUSE+=" test "
		RESTRICT+=" !test? ( test ) "
		if [[ ${optional} ]]; then
			IUSE+=" emacs "
			BDEPEND+=" test? ( emacs? ( ${test_pkg} ) ) "
		else
			BDEPEND+=" test? ( ${test_pkg} ) "
		fi
	fi

	return 0
}

# @FUNCTION: elisp-test
# @DESCRIPTION:
# Test the package using a ELisp test runner.
#
# If called without executing "elisp-enable-tests" beforehand, then
# does nothing, otherwise a test runner is called with given
# "test-runner-options".

elisp-test() {
	if [[ ${_ELISP_TEST_FUNCTION} ]]; then
		${_ELISP_TEST_FUNCTION} "${_ELISP_TEST_OPTS[@]}"
	fi
}

# @FUNCTION: elisp-install
# @USAGE: <subdirectory> <list of files>
# @DESCRIPTION:
# Install files in SITELISP directory.

elisp-install() {
	local subdir="$1"
	shift
	ebegin "Installing Elisp files for GNU Emacs support"
	( # subshell to avoid pollution of calling environment
		insinto "${SITELISP}/${subdir}"
		doins "$@"
	)
	eend $? "elisp-install: doins failed" || die
}

# @FUNCTION: elisp-modules-install
# @USAGE: <subdirectory> <list of files>
# @DESCRIPTION:
# Install dynamic modules in EMACSMODULES directory.

elisp-modules-install() {
	local subdir="$1"
	shift
	ebegin "Installing dynamic modules for GNU Emacs support"
	( # subshell to avoid pollution of calling environment
		exeinto "${EMACSMODULES//@libdir@/$(get_libdir)}/${subdir}"
		doexe "$@"
	)
	eend $? "elisp-modules-install: doins failed" || die
}

# @FUNCTION: elisp-site-file-install
# @USAGE: <site-init file> [subdirectory]
# @DESCRIPTION:
# Install Emacs site-init file in SITELISP directory.  Automatically
# inserts a standard comment header with the name of the package
# (unless it is already present).  Tokens @SITELISP@, @SITEETC@,
# and @EMACSMODULES@ are replaced by the path to the package's
# subdirectory in SITELISP, SITEETC, and EMACSMODULES, respectively.

elisp-site-file-install() {
	local sf="${1##*/}" my_pn="${2:-${PN}}" modules ret
	local add_header="0,/\S/ {
		# Delete any leading blank lines
		/\S/! d
		# Insert a header, unless we are already looking at one
		/^;.*${PN}/I! \
			i ;;; ${PN} site-lisp configuration  -*-lexical-binding:t-*-\n
	}"

	[[ ${sf} == [0-9][0-9]*-gentoo*.el ]] \
		|| ewarn "elisp-site-file-install: bad name of site-init file"
	[[ ${sf%-gentoo*.el} != "${sf}" ]] && sf="${sf%-gentoo*.el}-gentoo.el"
	sf="${T}/${sf}"
	ebegin "Installing site initialisation file for GNU Emacs"
	[[ $1 == "${sf}" ]] || cp "$1" "${sf}"
	modules=${EMACSMODULES//@libdir@/$(get_libdir)}
	sed -i -e "${add_header}" \
		-e "s:@SITELISP@:${EPREFIX}${SITELISP}/${my_pn}:g" \
		-e "s:@SITEETC@:${EPREFIX}${SITEETC}/${my_pn}:g" \
		-e "s:@EMACSMODULES@:${EPREFIX}${modules}/${my_pn}:g;\$q" "${sf}"
	( # subshell to avoid pollution of calling environment
		insinto "${SITELISP}/site-gentoo.d"
		doins "${sf}"
	)
	ret=$?
	rm -f "${sf}"
	eend ${ret} "elisp-site-file-install: doins failed" || die
}

# @FUNCTION: elisp-make-site-file
# @USAGE: <filename> [subdirectory] [line]...
# @DESCRIPTION:
# Create and install a site-init file for the package.  By default,
# this will add the package's SITELISP subdirectory to Emacs' load-path:
#
# @CODE
# (add-to-list 'load-path "@SITELISP@")
# @CODE
#
# Additional arguments are appended as lines to the destination file.
# Any @SITELISP@, @SITEETC@, and @EMACSMODULES@ tokens in these
# arguments are replaced, as described for elisp-site-file-install.

elisp-make-site-file() {
	[[ $1 == [0-9][0-9]*-gentoo.el ]] \
		|| die "elisp-make-site-file: bad name of site-init file"

	local f="${T}/$1" my_pn="${2:-${PN}}"
	shift; shift
	printf "%s\n" "(add-to-list 'load-path \"@SITELISP@\")" "$@" >"${f}" || die
	elisp-site-file-install "${f}" "${my_pn}"
}

# @FUNCTION: elisp-site-regen
# @DESCRIPTION:
# Regenerate the site-gentoo.el file, based on packages' site
# initialisation files in the /usr/share/emacs/site-lisp/site-gentoo.d/
# directory.

elisp-site-regen() {
	local sitelisp=${EROOT}${SITELISP}
	local sf i ret=0 null="" page=$'\f'
	local -a sflist

	if [[ ${EBUILD_PHASE} == *rm && ! -e ${sitelisp}/site-gentoo.el ]]; then
		ewarn "Refusing to create site-gentoo.el in ${EBUILD_PHASE} phase."
		return 0
	fi

	[[ -d ${sitelisp} ]] \
		|| die "elisp-site-regen: Directory ${sitelisp} does not exist"

	ebegin "Regenerating site-gentoo.el for GNU Emacs (${EBUILD_PHASE})"

	for sf in "${sitelisp}"/site-gentoo.d/[0-9][0-9]*.el; do
		[[ -r ${sf} ]] && sflist+=("${sf}")
	done

	cat <<-EOF >"${T}"/site-gentoo.el || ret=$?
	;;; site-gentoo.el --- Gentoo site initialisation  -*-lexical-binding:t-*-

	;;; Commentary:
	;; Automatically generated by elisp-common.eclass
	;; DO NOT EDIT THIS FILE

	;;; Code:

	EOF
	# Concatenate all site initialisation files.
	# 1{/^;/s/\s*-\*-.*-\*-//} deletes file-local-var cookies from line 1.
	# /\S/,$!d deletes any leading blank lines.
	# $G inserts a blank line after each file.
	sed -s '1{/^;/s/\s*-\*-.*-\*-//};/\S/,$!d;$G' "${sflist[@]}" \
		</dev/null >>"${T}"/site-gentoo.el || ret=$?
	cat <<-EOF >>"${T}"/site-gentoo.el || ret=$?
	${page}
	(provide 'site-gentoo)

	;; Local ${null}Variables:
	;; no-byte-compile: t
	;; buffer-read-only: t
	;; End:

	;;; site-gentoo.el ends here
	EOF

	if [[ ${ret} -ne 0 ]]; then
		eend ${ret} "elisp-site-regen: Writing site-gentoo.el failed."
		die
	elif cmp -s "${sitelisp}"/site-gentoo.el "${T}"/site-gentoo.el; then
		# This prevents outputting unnecessary text when there
		# was actually no change.
		# A case is a remerge where we have doubled output.
		rm -f "${T}"/site-gentoo.el
		eend 0
		einfo "... no changes."
	else
		mv "${T}"/site-gentoo.el "${sitelisp}"/site-gentoo.el
		eend $? "elisp-site-regen: Replacing site-gentoo.el failed" || die
		case ${#sflist[@]} in
			0) [[ ${PN} == emacs-common ]] \
				|| ewarn "... Huh? No site initialisation files found." ;;
			1) einfo "... ${#sflist[@]} site initialisation file included." ;;
			*) einfo "... ${#sflist[@]} site initialisation files included." ;;
		esac
	fi

	return 0
}
