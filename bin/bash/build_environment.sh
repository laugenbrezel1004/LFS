# to get to the root
# TODO überarbeiten
#dirname "${BASH_SOURCE[0]}"
echo "${BASH_SOURCE[0]}"
#cd "$(dirname "${BASH_SOURCE[0]}")"  || exit 1
pwd

#cd .. && cd .. && pwd
#
#pwd
export LFS="$(pwd)"/ext4
export MAKEFLAGS=-j24
#export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
#