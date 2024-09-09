if [[ $* == *--scriptdebug* ]]; then
    set -x
fi
set -e

APP_NAME="Nugget"
WORKING_LOCATION="$(pwd)"
APP_BUILD_FILES="$WORKING_LOCATION/layout/Applications/$APP_NAME.app"
DEBUG_LOCATION="$WORKING_LOCATION/.theos/obj/debug"
RELEASE_LOCATION="$WORKING_LOCATION/.theos/obj"
if [[ $* == *--debug* ]]; then
    BUILD_LOCATION="$DEBUG_LOCATION/$APP_NAME.app"
else
    BUILD_LOCATION="$RELEASE_LOCATION/$APP_NAME.app"
fi

if [[ $* == *--clean* ]]; then
    echo "[*] Cleaning..."
    rm -rf build
    make clean
fi

if [ ! -d "build" ]; then
    mkdir build
fi
#remove existing archive if there
if [ -d "build/$APP_NAME.ipa" ]; then
    rm -rf "build/$APP_NAME.ipa"
fi

if ! type "gmake" >/dev/null; then
    echo "[!] gmake not found, using macOS bundled make instead"
    make clean
    if [[ $* == *--debug* ]]; then
        make
    else
        make FINALPACKAGE=1
    fi
else
    gmake clean
    if [[ $* == *--debug* ]]; then
        gmake -j"$(sysctl -n machdep.cpu.thread_count)"
    else
        gmake -j"$(sysctl -n machdep.cpu.thread_count)" FINALPACKAGE=1
    fi
fi

if [ -d $BUILD_LOCATION ]; then
    # Add the necessary files
    echo "Adding application files"
    cp -r "$APP_BUILD_FILES/icon.png" "$BUILD_LOCATION/icon.png"
    cp -r "$APP_BUILD_FILES/Info.plist" "$BUILD_LOCATION/Info.plist"
    cp -r "$APP_BUILD_FILES/Assets.car" "$BUILD_LOCATION/Assets.car"

    # Create payload
    echo "Creating payload"
    cd build
    mkdir Payload
    cp -r $BUILD_LOCATION Payload/$APP_NAME.app

    # Archive
    echo "Archiving"
    if [[ $* != *--debug* ]]; then
        strip Payload/$APP_NAME.app/$APP_NAME
    fi
    zip -vr $APP_NAME.ipa Payload
    rm -rf $APP_NAME.app
    rm -rf Payload
fi
