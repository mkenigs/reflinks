#!/usr/bin/env bash

XFS_PATH=/mnt/xfs
RPMS="${XFS_PATH}/rpms"
REFLINKS="${XFS_PATH}/reflinks"


function dump() {
  df "${XFS_PATH}" > "df${1}"
  stat -f "${XFS_PATH}" > "stat${1}"
}

rm -rf ${XFS_PATH}/*
mkdir "${RPMS}"
mkdir "${REFLINKS}"
dump 1

# install
readarray -t PKGS < <(dnf repoquery --requires --resolve nginx)
for pkg in "${PKGS[@]}"; do
    rpm -i --nodeps --root "${RPMS}/${pkg}" $(dnf repoquery --location "${pkg}")
done
dump 2

# reflinks
for pkg in "${PKGS[@]}"; do
  cp -r --reflink "${RPMS}/${pkg}" "${REFLINKS}/${pkg}"
done
dump 3
