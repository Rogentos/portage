# Copyright 2008-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# NOTE from https://github.com/protocolbuffers/protobuf/blob/main/cmake/dependencies.cmake
ABSEIL_MIN_VER="20250127.0"

JAVA_PKG_IUSE="doc source test"
MAVEN_ID="com.google.protobuf:protobuf-java:${PV}"
JAVA_TESTING_FRAMEWORKS="junit-4"

inherit java-pkg-2 java-pkg-simple cmake

DESCRIPTION="Core Protocol Buffers library"
HOMEPAGE="https://protobuf.dev"
# Currently we bundle the binary version of truth.jar used only for tests, we don't install it.
# And we build artifact x.y.z from the y.z tarball in order to allow sharing the tarball with
# dev-libs/protobuf.
MY_PV="$(ver_cut 2-3)"
MY_PV="${MY_PV/_rc/-rc}"
TV="1.4.4"
SRC_URI="
	https://github.com/protocolbuffers/protobuf/releases/download/v${MY_PV}/protobuf-${MY_PV}.tar.gz
	test? (
		https://repo1.maven.org/maven2/com/google/truth/truth/${TV}/truth-${TV}.jar
	)
"
S="${WORKDIR}/protobuf-${MY_PV}"

LICENSE="BSD"
SLOT="0/$(ver_cut 1)"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~amd64-linux ~x86-linux ~x64-macos"
IUSE="system-protoc"

BDEPEND="
	system-protoc? ( dev-libs/protobuf:0/${MY_PV}.0[protoc] )
	!system-protoc? ( >=dev-cpp/abseil-cpp-${ABSEIL_MIN_VER}:= )
"
DEPEND="
	>=virtual/jdk-1.8:*
	test? (
		dev-java/guava:0
		dev-java/mockito:4
	)
"
RDEPEND="
	>=virtual/jre-1.8:*
"

JAVA_AUTOMATIC_MODULE_NAME="com.google.protobuf"
JAVA_JAR_FILENAME="protobuf.jar"
JAVA_RESOURCE_DIRS="java/core/src/main/resources"
JAVA_SRC_DIR="java/core/src/main/java"

JAVA_TEST_GENTOO_CLASSPATH="guava,junit-4,mockito-4"
JAVA_TEST_SRC_DIR="java/core/src/test/java"

run-protoc() {
	if use system-protoc; then
		protoc "$1"
	else
		"${BUILD_DIR}/protoc" "$1"
	fi
}

src_prepare() {
	# If the corresponding version of system-protoc is not available we build protoc locally
	if use system-protoc; then
		 # apply patches
		default
	else
		cmake_src_prepare
	fi
	java-pkg-2_src_prepare

	# https://github.com/protocolbuffers/protobuf/blob/main/java/core/generate-sources-build.xml
	einfo "Replace variables in generate-sources-build.xml"
	sed \
		-e 's:${generated.sources.dir}:java/core/src/main/java:' \
		-e 's:${protobuf.java_source.dir}:java/core/src/main/resources:' \
		-e 's:${protobuf.source.dir}:src:' \
		-e 's:^.*value="::' -e 's:\"/>::' \
		-e '/project\|echo\|mkdir\|exec/d' \
		-i java/core/generate-sources-build.xml || die "sed to sources failed"

	# https://github.com/protocolbuffers/protobuf/blob/main/java/core/generate-test-sources-build.xml
	einfo "Replace variables in generate-test-sources-build.xml"
	sed \
		-e 's:${generated.testsources.dir}:java/core/src/test/java:' \
		-e 's:${protobuf.source.dir}:src:' \
		-e 's:${test.proto.dir}:java/core/src/test/proto:' \
		-e 's:^.*value="::' -e 's:\"/>::' \
		-e '/project\|mkdir\|exec\|Also generate/d' \
		-i java/core/generate-test-sources-build.xml || die "sed to test sources failed"

	# Split the file in two parts, one for each run-protoc call
	awk '/--java_out/{x="test-sources-build-"++i;}{print > x;}' \
		java/core/generate-test-sources-build.xml || die

	# Requires TestParameterInjector library, currently not available in Gentoo.
	rm java/core/src/test/java/com/google/protobuf/CodedInputStreamTest.java || die

	# java/core/src/test/java/editions_unittest/TestDelimited.java:2867:
	# error: package editions_unittest.MessageImport does not exist
	rm java/core/src/test/java/com/google/protobuf/TextFormatTest.java || die
}

src_configure() {
	local mycmakeargs=(
		-Dprotobuf_BUILD_TESTS=OFF
		-Dprotobuf_LOCAL_DEPENDENCIES_ONLY=ON
	)
	if ! use system-protoc; then
		cmake_src_configure
	fi
}

src_compile() {
	if ! use system-protoc; then
		cmake_src_compile
	fi

	einfo "Run protoc to generate sources"
	run-protoc \
		@java/core/generate-sources-build.xml \
		|| die "protoc sources failed"

	java-pkg-simple_src_compile
}

src_test() {
	local -x JAVA_GENTOO_CLASSPATH_EXTRA="${DISTDIR}/truth-${TV}.jar"

	# google/protobuf/java_features.proto: File not found.
	cp {java/core/src/main/resources,src}/google/protobuf/java_features.proto || die

	einfo "Running protoc on first part of generate-test-sources-build.xml"
	run-protoc @test-sources-build-1 \
		|| die "run-protoc test-sources-build-1 failed"

	einfo "Running protoc on second part of generate-test-sources-build.xml"
	run-protoc @test-sources-build-2 \
		|| die "run-protoc test-sources-build-2 failed"

	einfo "Running tests"
	# Invalid test class 'map_test.MapInitializationOrderTest':
	# 1. Test class should have exactly one public constructor
	# Invalid test class 'protobuf_unittest.CachedFieldSizeTest':
	# 1. Test class should have exactly one public constructor
	pushd "${JAVA_TEST_SRC_DIR}" >/dev/null || die
		local JAVA_TEST_RUN_ONLY=$(find * \
			-path "**/*Test.java" \
			! -path "**/Abstract*Test.java" \
			! -name "MapInitializationOrderTest.java" \
			! -name CachedFieldSizeTest.java
			)
	popd >/dev/null || die
	JAVA_TEST_RUN_ONLY="${JAVA_TEST_RUN_ONLY//.java}"
	JAVA_TEST_RUN_ONLY="${JAVA_TEST_RUN_ONLY//\//.}"
	java-pkg-simple_src_test
}

src_install() {
	java-pkg-simple_src_install
}
