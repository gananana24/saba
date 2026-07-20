#!/bin/bash -e

HOME_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_PATH="$HOME_PATH/build"
OS_PATH="$TARGET_PATH/wasabi"
APP_NAME="saba"
APP_BIN="$HOME_PATH/target/x86_64-unknown-none/release/$APP_NAME"
WASABI_REPOSITORY="https://github.com/hikalium/wasabi.git"
WASABI_REV="abf27c6f587e777fce5c53234d45d997ed075996"

# Make build directory
if [ -d "$TARGET_PATH" ]
then
  echo $TARGET_PATH" exists"
else
  echo $TARGET_PATH" doesn't exist"
  mkdir -p "$TARGET_PATH"
fi

if [ -d "$OS_PATH/.git" ]
then
  echo $OS_PATH" exists"
else
  echo $OS_PATH" doesn't exist"
  echo "cloning repository..."
  git clone "$WASABI_REPOSITORY" "$OS_PATH"
fi

if ! git -C "$OS_PATH" cat-file -e "$WASABI_REV^{commit}" 2>/dev/null; then
  git -C "$OS_PATH" fetch origin "$WASABI_REV"
fi
git -C "$OS_PATH" checkout --detach "$WASABI_REV"

if [ "$(uname -s)" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS: https://brew.sh/" >&2
    exit 1
  fi
  COREUTILS_GNUBIN="$(brew --prefix coreutils)/libexec/gnubin"
  if [ ! -x "$COREUTILS_GNUBIN/readlink" ]; then
    echo "GNU coreutils is required on macOS. Install it with: brew install coreutils" >&2
    exit 1
  fi
  export PATH="$COREUTILS_GNUBIN:$PATH"
fi

make -C "$HOME_PATH" build

if [ ! -f "$APP_BIN" ]; then
  echo "App binary not found after build: $APP_BIN" >&2
  exit 1
fi

echo "Using wasabi at: $OS_PATH"
echo "Using app at: $APP_BIN"
make -C "$OS_PATH" run WITH_APP_BIN="$APP_BIN"
