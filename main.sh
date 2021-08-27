#!/usr/bin/env bash

XFS_PATH=/mnt/xfs
RPMS="${XFS_PATH}/rpms"
REFLINKS="${XFS_PATH}/reflinks"
MERGED="${XFS_PATH}/merged"


function dump() {
  df "${XFS_PATH}" > "df${1}"
  stat -f "${XFS_PATH}" > "stat${1}"
}

readarray -t PKGS < <(dnf repoquery --requires --resolve nginx)
rm -rf "${XFS_PATH}"/*
mkdir "${RPMS}"
mkdir "${REFLINKS}"
dump 1

# install
for pkg in "${PKGS[@]}"; do
    rpm -i --nodeps --root "${RPMS}/${pkg}" $(dnf repoquery --location "${pkg}")
done
dump 2

# reflinks
for pkg in "${PKGS[@]}"; do
  cp -r --reflink "${RPMS}/${pkg}" "${REFLINKS}/${pkg}"
done
dump 3

# merge
for pkg in "${PKGS[@]}"; do
  rsync -a "${REFLINKS}/${pkg}/" "${MERGED}" --link-dest="${REFLINKS}/${pkg}"
done
dump 4
