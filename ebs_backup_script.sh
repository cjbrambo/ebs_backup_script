#!/bin/bash

KEEP_N=5

volumes=( vol-abcbvd vol-abcbvd )

# Creates a backup of selected volumes and adds a description
#
function backup() {
  for volume in $volumes; do
    echo "Creating backup of $volume"
    cmd="aws ec2 create-snapshot --volume-id $volume --description backup-script"
    cmdhandler $cmd
  done
}

# Collects and deletes snapshots over 5 backups old
#
function delete() {
  for volume in $volumes; do
    echo "Collecting snapshots over 5 backups old"
    cmd="aws ec2 describe-snapshots --filters Name=volume-id,Values=$volume,Name=description,Values=backup-script | jq '.Snapshots | sort_by(.StartTime) | reverse | .[$KEEP_N:] | .[] | .SnapshotId'"
    snapshots=$(eval $cmd)
    errhandler $? $cmd

    echo "About to delete these snapshots $snapshots"
    for snapshot in $snapshots; do
      snapshot="echo $snapshot | sed 's/\"//g'"
      echo "Deleting snapshot $snapshot"
      cmd="aws ec2 delete-snapshot --snapshot-id $snapshot"
      cmdhandler $cmd
    done
  done
}

function cmdhandler() {
  cmd=$@
  $cmd
  errhandler $? $cmd
}

function errhandler() {
  exit_status=$1
  shift
  cmd=$@
  if [ $exit_status -ne 0 ]; then
    slackmsg.py botdev "cmd failed:\n $cmd"
    exit $exit_status
  fi
}

backup
delete

slackmsg.py ops "Backup complete for volumes: $volumes"
