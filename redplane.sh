#! /bin/sh
SCRIPT_DIR=$(dirname "$0")
cleanup() {
  rm -rf ~/git/"$1"
}
clone() {
  cd ~/git || exit
  git clone "https://aur.archlinux.org/${1}"
  cd "$1" || exit
}
build() {
  makepkg -si
}
synclist() {
  if ! grep "${1}" ~/.redplane/to-update >/dev/null 2>&1; then
    tee -a "${1}" ~/.redplane/to-update
  fi
}
update() {
  doas pacman -Syu
  REDPLANE_UPDATEFILE_LINES=$(awk 'END{print NR}' ~/.redplane/to-update)
  for i in $( seq 1 "$REDPLANE_UPDATEFILE_LINES" );  do
    "$SCRIPT_DIR"/redplane.sh -i $(sed -n "${i}p" ~/.redplane/to-update)
  done
}
usage() {
  echo "-u: update the system"
  echo "-i: install the specified package"
  echo "-h: list the commands"
  echo "-t: specify number of threads"
}
mkfiles() {
  mkdir ~/git >/dev/null 2>&1
  mkdir ~/.redplane >/dev/null 2>&1
  touch ~/.redplane/to-update >/dev/null 2>&1
}
install() {
  if [  "$1" != "" ]; then
    if [ YESTOALL == "y" ]; then
      if [ ! getpkg ]; then
        clone $1
        build
        synclist $1
        cleanup $1
      fi
    else
      read -r -p "r u sure u wanna install $1? [y/n]: " yn
      if [ "$yn" == "y" ]; then
        doas pacman -S $1
        if [ $? > 0 ]; then
          read -r -p "pacman fucked up. check aur? [y/n]: "  yn
          if [ "$yn" == "y" ]; then
            clone $1
            build
            synclist $1
            cleanup $1
          fi
        else
          echo "pacman did not fuck up."
        fi
      fi
    fi
  fi

}
error() {
  echo "KABOOM! plane crash: $1"
  exit 1
}
mkfiles
while getopts uhyt:i: options; do
  case $options in
    i) AUR_PACKAGE=$OPTARG;;
    u) UPDATE_PACKAGES=yes;;
    h) PRINT_HELP=yes;;
    t) export MAKEFLAGS="-j${OPTARG}";;
    y) YESTOALL=y;;
    *)echo "KABOOM! plane crash: invalid option"
      exit 1;;
  esac
done
if [ "$1" == "" ]; then
  error "no options specified."
fi
if [ "$UPDATE_PACKAGES" == "yes" ]; then
  update
fi
if [ "$AUR_PACKAGE" != "" ]; then
  install "$AUR_PACKAGE"
fi
if [ "$PRINT_HELP" == "yes" ]; then
  usage
fi
