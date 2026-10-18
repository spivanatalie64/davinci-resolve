# Maintainer: Natalie <natalie@acreetionos.org>
# Self-contained DaVinci Resolve (free) package with dynamic download
# Downloads the installer automatically from Blackmagic Design's API

_pkgname=resolve
pkgname=davinci-resolve
pkgver=21.1.1
pkgrel=1
pkgdesc='Professional A/V post-production software suite from Blackmagic Design (free version, dynamically downloaded)'
arch=('x86_64')
url="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
license=('LicenseRef-scancode-commercial-license')
depends=('glu' 'fuse2' 'opencl-driver' 'qt5-x11extras' 'qt5-svg'
         'qt5-quickcontrols2' 'qt5-multimedia' 'libxcrypt-compat' 'xmlsec'
         'java-runtime' 'ffmpeg4.4' 'gst-plugins-bad-libs' 'python-numpy'
         'tbb' 'apr-util' 'luajit' 'libc++' 'libc++abi')
makedepends=('libarchive' 'xdg-user-dirs' 'patchelf' 'curl' 'jq' 'unzip')
conflicts=('davinci-resolve-studio' 'davinci-resolve-beta' 'davinci-resolve-studio-beta')
install="${pkgname}.install"
options=('!strip')

# Blackmagic Design download API configuration (free version)
REFERID="263d62f31cbb49e0868005059abcb0c9"
DOWNLOADSURL="https://www.blackmagicdesign.com/api/support/us/downloads.json"
SITEURL="https://www.blackmagicdesign.com/api/register/us/download"
PRODUCT="DaVinci Resolve"
VERSION="${pkgver}"
USERAGENT="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.75 Safari/537.36"

prepare() {
  # Step 1: Get download ID from Blackmagic API
  echo "==> Fetching download ID from Blackmagic Design API..."
  DOWNLOADID=$(curl -s --compressed "$DOWNLOADSURL" | \
    jq -r '.downloads[] | .urls.Linux?[]? | select(.downloadTitle | test("^'"$PRODUCT $VERSION"'( Update)?$")) | .downloadId')
  if [ -z "$DOWNLOADID" ]; then
    echo "ERROR: Could not find download ID for $PRODUCT $VERSION"
    exit 1
  fi
  echo "==> Download ID: $DOWNLOADID"

  # Step 2: Register and get signed download URL
  echo "==> Registering download..."
  REQJSON='{"firstname":"Arch","lastname":"Linux","email":"someone@archlinux.org","phone":"202-555-0194","country":"us","state":"New York","city":"AUR","product":"DaVinci Resolve","street":"-"}'
  REQJSON="$(printf '%s' "$REQJSON" | sed 's/[[:space:]]\+/ /g')"
  RESOLVEURL=$(curl -s --compressed \
    -H 'Host: www.blackmagicdesign.com' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Origin: https://www.blackmagicdesign.com' \
    -H "$USERAGENT" \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H "Referer: https://www.blackmagicdesign.com/support/download/$REFERID/Linux" \
    -H 'Accept-Encoding: gzip, deflate, br' \
    -H 'Accept-Language: en-US,en;q=0.9' \
    -H 'Authority: www.blackmagicdesign.com' \
    -H 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
    --data-ascii "$REQJSON" \
    "$SITEURL/$DOWNLOADID")
  if [ -z "$RESOLVEURL" ]; then
    echo "ERROR: Could not get download URL"
    exit 1
  fi
  echo "==> Download URL obtained"

  # Step 3: Download the zip
  ARCHIVE="DaVinci_Resolve_${pkgver}_Linux.zip"
  if [ ! -f "$ARCHIVE" ]; then
    echo "==> Downloading $ARCHIVE (this may take a while)..."
    curl --retry 3 --retry-delay 3 \
      -H "Upgrade-Insecure-Requests: 1" \
      -H "$USERAGENT" \
      -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
      -H "Accept-Language: en-US,en;q=0.9" \
      --compressed \
      "$RESOLVEURL" \
      -o "$ARCHIVE"
  fi

  # Step 4: Download control panels setup script
  if [ ! -f "davinci-control-panels-setup.sh" ]; then
    curl -s -o "davinci-control-panels-setup.sh" \
      "https://aur.archlinux.org/cgit/aur.git/plain/davinci-control-panels-setup.sh?h=davinci-resolve"
  fi

  # Step 5: Extract zip
  echo "==> Extracting archive..."
  unzip -o "$ARCHIVE"
  chmod u+x "./DaVinci_Resolve_${pkgver}_Linux.run"

  # Step 6: Run appimage extract
  "./DaVinci_Resolve_${pkgver}_Linux.run" --appimage-extract

  # Fix permission to all files and dirs
  chmod -R u+rwX,go+rX,go-w "squashfs-root"

  pushd "squashfs-root/share/panels"
  tar -zxf dvpanel-framework-linux-x86_64.tgz
  chmod -R u+rwX,go+rX,go-w "lib"
  mv *.so "${srcdir}/squashfs-root/libs"
  mv lib/* "${srcdir}/squashfs-root/libs"
  popd

  rm -rf squashfs-root/{installer*,AppRun*,CentOSUpdate}

  while IFS= read -r -d '' _file; do
    chmod 0755 "${_file}"
  done < <(find "squashfs-root" -type d -print0)

  while IFS= read -r -d '' _file; do
    [[ -f "${_file}" && $(od -t x1 -N 4 "${_file}") == *"7f 45 4c 46"* ]] || continue
    chmod 0755 "${_file}"
  done < <(find "squashfs-root" -type f -print0)

  # Prepare list of paths for patchelf
  _patchelf_paths=(
    "libs"
    "libs/plugins/"{sqldrivers,xcbglintegrations,imageformats,platforms}
    "libs/Fusion"
    "plugins"
    "bin"
    "BlackmagicRAWSpeedTest/BlackmagicRawAPI"
    "BlackmagicRAWSpeedTest/plugins/"{platforms,imageformats,mediaservice,audio,xcbglintegrations,bearer}
    "BlackmagicRAWPlayer/BlackmagicRawAPI"
    "BlackmagicRAWPlayer/plugins/"{mediaservice,imageformats,audio,platforms,xcbglintegrations,bearer}
    "Onboarding/plugins/"{xcbglintegrations,qtwebengine,platforms,imageformats}
    "DaVinci Control Panels Setup/plugins/"{platforms,imageformats,bearer}
    "DaVinci Control Panels Setup/AdminUtility/PlugIns/"{DaVinciKeyboards,DaVinciPanels}
  )
  for _index in "${!_patchelf_paths[@]}"
  do
    _patchelf_paths[${_index}]="/opt/${_pkgname}/${_patchelf_paths[${_index}]}"
  done
  while IFS= read -r -d '' _file; do
    [[ -f "${_file}" && $(od -t x1 -N 4 "${_file}") == *"7f 45 4c 46"* ]] || continue
    patchelf --set-rpath "$(IFS=":"; echo "${_patchelf_paths[*]}:\$ORIGIN")" "${_file}"
  done < <(find "squashfs-root" -type f -size -32M -print0)

  while IFS= read -r -d '' _file; do
    sed -i "s|RESOLVE_INSTALL_LOCATION|/opt/${_pkgname}|g" "${_file}"
  done < <(find . -type f '(' -name "*.desktop" -o -name "*.directory" -o -name "*.menu" ')' -print0)

  rm -f squashfs-root/libs/libglib-2.0.so.0{,.8200.4} \
     squashfs-root/libs/libgio-2.0.so.0{,.8200.4} \
     squashfs-root/libs/libgmodule-2.0.so.0{,.8200.4} \
     squashfs-root/libs/libgobject-2.0.so.0{,.8200.4} \
     squashfs-root/libs/libc++.so.1{,.0} \
     squashfs-root/libs/libc++abi.so.1{,.0}
  ln -s "../BlackmagicRAWPlayer/BlackmagicRawAPI" "squashfs-root/bin/"
  ln -s -t squashfs-root/libs/ \
    /usr/lib/lib{glib,gio,gmodule,gobject}-2.0.so.0 \
    /usr/lib/libgdk_pixbuf-2.0.so.0 \
    /usr/lib/lib{c++,c++abi}.so.1

  echo "StartupWMClass=resolve" >> "squashfs-root/share/DaVinciResolve.desktop"

  echo 'SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="096e", MODE="0666"' > "squashfs-root/share/etc/udev/rules.d/99-DavinciPanel.rules"

  # Fix desktop files
  sed -i 's#Exec=.*#Exec=davinci-control-panels-setup#' \
    "squashfs-root/share/DaVinciControlPanelsSetup.desktop"
  sed -i 's#Icon=.*#Icon=davinci-resolve#' \
    "squashfs-root/share/DaVinciResolve.desktop"
  sed -i 's#Icon=.*#Icon=davinci-resolve-panels-setup#' \
    "squashfs-root/share/DaVinciControlPanelsSetup.desktop"
  sed -i 's#Icon=.*#Icon=blackmagicraw-player#' \
    "squashfs-root/share/blackmagicraw-player.desktop"
  sed -i 's#Icon=.*#Icon=blackmagicraw-speedtest#' \
    "squashfs-root/share/blackmagicraw-speedtest.desktop"
}

package() {
  # Install binary launchers
  install -D -m 0755 "${srcdir}/davinci-control-panels-setup.sh" \
    "${pkgdir}/usr/bin/davinci-control-panels-setup"
  ln -s "/opt/resolve/bin/resolve" "${pkgdir}/usr/bin/${pkgname}"
  # Install other files
  install -d -m 0755 "${pkgdir}/opt/${_pkgname}"
  cp -rf squashfs-root/* "${pkgdir}/opt/${_pkgname}"

  # Distribute files into other directories
  pushd "${pkgdir}/opt/${_pkgname}"
  install -D -m 0644 -t "${pkgdir}/opt/${_pkgname}/configs" \
    share/{default-config.dat,log-conf.xml}
  install -D -m 0644 -t "${pkgdir}/opt/${_pkgname}/DolbyVision" \
    "share/default_cm_config.bin"
  install -d -m 0755 "${pkgdir}/opt/${_pkgname}/.license"
  install -d -m 0755 "${pkgdir}/opt/${_pkgname}/Apple Immersive/Calibration"
  install -d -m 0755 "${pkgdir}/opt/${_pkgname}/Extras"
  install -d -m 0755 "${pkgdir}/opt/${_pkgname}/Fairlight"
  install -d -m 0755 "${pkgdir}/opt/${_pkgname}/Immersive/Canon/STMap"
  # Install licenses
  install -d -m 0644 "${pkgdir}/usr/share/licenses/${pkgname}"
  ln -s "/opt/resolve/docs/License.html" "${pkgdir}/usr/share/licenses/${pkgname}"
  # Install Desktop files and menu
  install -D -m 0644 -t "${pkgdir}/usr/share/applications" \
    "share/DaVinciResolve.desktop" \
    "share/DaVinciControlPanelsSetup.desktop" \
    "share/blackmagicraw-player.desktop" \
    "share/blackmagicraw-speedtest.desktop"
  install -D -m 0644 -t "${pkgdir}/usr/share/desktop-directories" \
    "share/DaVinciResolve.directory"
  install -D -m 0644 -t "${pkgdir}/etc/xdg/menus" \
    "share/DaVinciResolve.menu"
  # Install icons
  install -D -m 0644 -t "${pkgdir}/usr/share/icons/hicolor/64x64/apps" \
    "graphics/DV_Resolve.png" \
    "graphics/DV_ResolveProj.png"
  install -D -m 0644 "graphics/DV_Resolve.png" \
    "${pkgdir}/usr/share/icons/hicolor/128x128/apps/davinci-resolve.png"
  install -D -m 0644 "graphics/DV_Panels.png" \
    "${pkgdir}/usr/share/icons/hicolor/128x128/apps/davinci-resolve-panels-setup.png"
  install -D -m 0644 "graphics/blackmagicraw-player_256x256_apps.png" \
    "${pkgdir}/usr/share/icons/hicolor/256x256/apps/blackmagicraw-player.png"
  install -D -m 0644 "graphics/blackmagicraw-speedtest_256x256_apps.png" \
    "${pkgdir}/usr/share/icons/hicolor/256x256/apps/blackmagicraw-speedtest.png"
  # Install other files
  install -D -m 0644 -t "${pkgdir}/usr/share/mime/packages" \
    "share/resolve.xml"
  install -D -m 0644 -t "${pkgdir}/usr/lib/udev/rules.d" \
    "share/etc/udev/rules.d"/{99-BlackmagicDevices.rules,99-ResolveKeyboardHID.rules,99-DavinciPanel.rules}
  popd
}
