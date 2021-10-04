#!/usr/bin/env bash

XFS_PATH=/mnt/xfs
RPMS="${XFS_PATH}/rpms"
REFLINKS="${XFS_PATH}/reflinks"
MERGED="${XFS_PATH}/merged"


function dump() {
  sync -f "${XFS_PATH}"
  df "${XFS_PATH}" > "df${1}"
  stat -f "${XFS_PATH}" > "stat${1}"
}

# setup directories
rm -rf "${XFS_PATH}"/*
mkdir "${RPMS}"
mkdir "${REFLINKS}"
dump 1

# store nginx and all its dependencies in $PKGS
readarray -t PKGS < <(dnf repoquery --requires --resolve nginx)

# install each package into a separate directory under $RPMS
for pkg in "${PKGS[@]}"; do
    rpm -i --nodeps --root "${RPMS}/${pkg}" $(dnf repoquery --location "${pkg}")
done
dump 2

# reflink each package's directory in $RPMS into $REFLINKS
for pkg in "${PKGS[@]}"; do
  cp -r --reflink "${RPMS}/${pkg}" "${REFLINKS}/${pkg}"
done
dump 3

# create a hardlinked root filesystem tree by merging everything from each $pkg
# directory in $REFLINKS to a single root filesystem directory in $MERGED
for pkg in "${PKGS[@]}"; do
  rsync -a "${REFLINKS}/${pkg}/" "${MERGED}" --link-dest="${REFLINKS}/${pkg}"
done
dump 4
