#!/bin/bash

set -e

KEEP_N=5

volumes=( vol-abcbvd )

# Creates a backup of selected volumes and adds a description
#
function backup() {
  for volume in $volumes; do
    echo "Creating backup of $volume"
    aws ec2 create-snapshot --volume-id $volume --description "backup-script"
  done
}

# Collects and deletes snapshots over 5 backups old
#
function delete() {
  for volume in $volumes; do
    echo "Collecting snapshots over 5 backups old"
    snapshots=$(aws ec2 describe-snapshots \
      --filters Name=description,Values="backup-script",Name=volume-id,Values=$volume \
      | jq ".Snapshots |  sort_by(.StartTime) | reverse | .[$KEEP_N:] | .[] | .SnapshotId")

    echo "About to delete these snapshots $snapshots"
      for snapshot in $snapshots; do
        snapshot=$(echo $snapshot | sed "s/\"//g")
        echo "Deleting snapshot $snapshot"
        aws ec2 delete-snapshot --snapshot-id $snapshot
      done
  done
}

backup

delete

