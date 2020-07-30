#
# This helper is for templates for Node.js packages (including Electron.js)
#

do_configure() {
    if [ -f "yarn.lock" ]; then
        : ${nodejs_packager:=yarn}
    else
        : ${nodejs_packager:=npm}
    fi

    $nodejs_packager install
}

do_build() {
    if [ -f "yarn.lock" ]; then
        : ${nodejs_packager:=yarn}
    else
        : ${nodejs_packager:=npm}
    fi

    : ${nodejs_build_script:=build}

    $nodejs_packager run $nodejs_build_script
}

do_install() {
    if [ -f "yarn.lock" ]; then
        : ${nodejs_packager:=yarn}
    else
        : ${nodejs_packager:=npm}
    fi

    : ${nodejs_install_script:=pack}  # name suggested by https://github.com/electron-userland/electron-builder#quick-setup-guide

    $nodejs_packager run $nodejs_install_script
}
