#
# This helper is for templates for Node.js packages (including Electron.js)
#

do_configure() {
    : ${NODE_ENV:=production}
    if [ -f "yarn.lock" ]; then
        : ${nodejs_packager:=yarn}
    else
        : ${nodejs_packager:=npm}
    fi

    $nodejs_packager install
}

do_build() {
    : ${NODE_ENV:=production}
    if [ -f "yarn.lock" ]; then
        : ${nodejs_packager:=yarn}
    else
        : ${nodejs_packager:=npm}
    fi

    : ${nodejs_build_script:=build}

    $nodejs_packager run $nodejs_build_script
}

# it's really likely that it won't suit anybody's needs but whatever
do_install() {
    : ${NODE_ENV:=production}
    if [ -f "yarn.lock" ]; then
        : ${nodejs_packager:=yarn}
    else
        : ${nodejs_packager:=npm}
    fi

    : ${nodejs_install_script:=pack}  # name suggested by https://github.com/electron-userland/electron-builder#quick-setup-guide

    $nodejs_packager run $nodejs_install_script
}
