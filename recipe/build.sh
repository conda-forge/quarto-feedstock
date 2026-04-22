set -ex

# With {{ compiler('c') }} / {{ compiler('rust') }} in build:, conda-build
# always uses dual-prefix mode, so build-time tools (deno, pandoc, etc.)
# live in $BUILD_PREFIX. This holds for both native and cross builds.
export NATIVE_PREFIX=$BUILD_PREFIX
if [[ "$CONDA_BUILD_CROSS_COMPILATION" = "1" ]]; then
    mkdir -p $PREFIX/bin
    mkdir -p $PREFIX/share/quarto
fi

# The typst-gather Rust build pulls in openssl-sys (via typst-kit) on Linux.
# Point it at the conda-provided openssl in the host prefix so the openssl
# crate's build.rs doesn't fall back to pkg-config / system discovery.
if [[ "${target_platform}" == linux-* ]]; then
    export OPENSSL_DIR=$PREFIX
fi

export QUARTO_VENDOR_BINARIES=false
export QUARTO_NO_SYMLINK=1
export QUARTO_DENO=$NATIVE_PREFIX/bin/deno
export DENO_BIN_PATH=$NATIVE_PREFIX/bin/deno
export QUARTO_DENO_DOM=$DENO_DOM_PLUGIN
export QUARTO_PANDOC=$NATIVE_PREFIX/bin/pandoc
export QUARTO_ESBUILD=$NATIVE_PREFIX/bin/esbuild
export QUARTO_TYPST=$NATIVE_PREFIX/bin/typst

export QUARTO_DIST_PATH=$PREFIX

# Alter the configuration file with a dynamic value containing the full
# package version (e.g. 1.3.340). The only thing allowed in this file is
# export statements with static assignments, so we strip the upstream
# assignment and append a new one using the build-time PKG_VERSION.
# More context: https://github.com/conda-forge/quarto-feedstock/pull/7
sed -i '/^export QUARTO_VERSION=/d' configuration
echo "export QUARTO_VERSION=${PKG_VERSION}" >> configuration
source configuration

source package/src/set_package_paths.sh

# conda-forge's Rust toolchain sets CARGO_BUILD_TARGET to the host triple,
# so `cargo build` writes to target/<triple>/release/ instead of the default
# target/release/. Upstream configure.sh line 108-109 hardcodes the default
# path. Patch it in-place so the cp after `cargo build` finds the binary.
sed -i "s|package/typst-gather/target/release|package/typst-gather/target/${CARGO_BUILD_TARGET}/release|" configure.sh

# configure.sh's cp destination (tools/<arch>/) is only created by upstream
# inside the vendored-binaries branch we disable with QUARTO_VENDOR_BINARIES=false.
# Pre-create both common arches so the cp succeeds regardless of host arch.
mkdir -p "$QUARTO_BIN_PATH/tools/x86_64" "$QUARTO_BIN_PATH/tools/aarch64"

bash configure.sh

# prepare-dist.ts (package/src/common/prepare-dist.ts, line 111) also hardcodes
# package/typst-gather/target/release/typst-gather — a second reference to the
# non-triple path. cargo wrote to target/<triple>/release/, so replicate the
# binary to the non-triple location for prepare-dist to find it.
if [[ -f "package/typst-gather/target/${CARGO_BUILD_TARGET}/release/typst-gather" ]]; then
    mkdir -p package/typst-gather/target/release
    cp "package/typst-gather/target/${CARGO_BUILD_TARGET}/release/typst-gather" \
       package/typst-gather/target/release/typst-gather
fi

bash package/src/quarto-bld prepare-dist
bash package/src/quarto-bld make-installer-dir

mkdir -p $PREFIX/etc/conda/activate.d
{ read -r -d '' || printf >$PREFIX/etc/conda/activate.d/quarto.sh '%s' "$REPLY"; } <<-EOF
  #!/bin/sh
  export QUARTO_DENO=$PREFIX/bin/deno
  export QUARTO_DENO_DOM=$DENO_DOM_PLUGIN
  export QUARTO_PANDOC=$PREFIX/bin/pandoc
  export QUARTO_ESBUILD=$PREFIX/bin/esbuild
  export QUARTO_TYPST=$PREFIX/bin/typst
  export QUARTO_DART_SASS=$PREFIX/bin/sass
  export QUARTO_SHARE_PATH=$PREFIX/share/quarto
  export QUARTO_CONDA_PREFIX=$PREFIX
EOF

mkdir -p $PREFIX/etc/conda/deactivate.d
{ read -r -d '' || printf >$PREFIX/etc/conda/deactivate.d/quarto.sh '%s' "$REPLY"; } <<-EOF
  #!/bin/sh
  unset QUARTO_DENO
  unset QUARTO_DENO_DOM
  unset QUARTO_PANDOC
  unset QUARTO_ESBUILD
  unset QUARTO_TYPST
  unset QUARTO_DART_SASS
  unset QUARTO_SHARE_PATH
  unset QUARTO_CONDA_PREFIX
EOF
