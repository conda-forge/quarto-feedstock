set -ex

export NATIVE_PREFIX=$PREFIX
if [[ "$CONDA_BUILD_CROSS_COMPILATION" = "1" ]]; then
    # We are cross-compiling, so we need to use the build prefix
    export NATIVE_PREFIX=$BUILD_PREFIX
    mkdir -p $PREFIX/bin
    mkdir -p $PREFIX/share/quarto
fi

export QUARTO_VENDOR_BINARIES=false
export QUARTO_NO_SYMLINK=1
export QUARTO_DENO=$NATIVE_PREFIX/bin/deno
export DENO_BIN_PATH=$NATIVE_PREFIX/bin/deno
export QUARTO_DENO_DOM=$DENO_DOM_PLUGIN
export QUARTO_PANDOC=$NATIVE_PREFIX/bin/pandoc
export QUARTO_ESBUILD=$NATIVE_PREFIX/bin/esbuild

export QUARTO_PACKAGE_PATH=$SRC_DIR/package
export QUARTO_DIST_PATH=$PREFIX
export QUARTO_BIN_PATH=$PREFIX/bin
export QUARTO_SHARE_PATH=$PREFIX/share/quarto

source package/src/set_package_paths.sh
source configuration

bash configure.sh
bash package/src/quarto-bld prepare-dist

# here-doc tab indented
mkdir -p $PREFIX/etc/conda/activate.d
{ read -r -d '' || printf >$PREFIX/etc/conda/activate.d/quarto.sh '%s' "$REPLY"; } <<-EOF
  #!/bin/sh
  export QUARTO_DENO=$PREFIX/bin/deno
  export QUARTO_DENO_DOM=$DENO_DOM_PLUGIN
  export QUARTO_PANDOC=$PREFIX/bin/pandoc
  export QUARTO_ESBUILD=$PREFIX/bin/esbuild
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
  unset QUARTO_DART_SASS
  unset QUARTO_SHARE_PATH
  unset QUARTO_CONDA_PREFIX
EOF
