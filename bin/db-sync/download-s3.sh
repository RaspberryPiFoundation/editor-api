#!/bin/bash -eu

S3_BUCKET="$1"
S3_PROFILE="editor-images-env-sync"

# copy bucket to local
echo "Copying contents from $S3_BUCKET S3 bucket"
aws s3 cp $S3_BUCKET ./storage/tmp --profile $S3_PROFILE --recursive
# check for error codes
if [ "$?" -ne "0" ]; then
  echo "Unable to transfer S3 contents"
else
  for f in ./storage/tmp/* ; do
    echo "Processing $f"
    file=$( echo ${f##*/} )
    dir1=${file:0:2}
    dir2=${file:2:2}
    mkdir -p "./storage/${dir1}/${dir2}" | true
    mv "${f}" "./storage/${dir1}/${dir2}/${file}"
  done
fi
