#!/bin/bash

if [[ $# -ne 2 ]]
then
  echo '== Please run this script passing the correct arguments ==
  ==> EXAMPLE: thisscript.sh $REPOSITORY $DAYS
      where $REPOSITORY stands for which repository you wish to clean
      and $DAYS is the number of days ago the image should have been pushed, otherwise will be deleted'
  exit 0
fi

function getRepos {
  gcloud container images list | grep $REGISTRY > repositorys_
  if [ $? -ne 0 ]
  then
    echo "Something went wrong getting the images"
    exit 1
  fi
}

function dealWithUntagedImages (){
  # For every image
  for image_info in `cat untaged_images_ | tr -d '"'`
  do
    # Get image resourceUrl
    image=$(echo $image_info | awk '{ print $1 }')

    # Transform the date of the last sec scan
    data_t=`date --date=$(echo $image_info | awk '{ print $2 }')  +"%s"`
    data_at=`date +"%s"`
    sub=`expr $data_at - $data_t`
    # Calculate how many days since it has be pushed
    month_passed=`expr $sub / 60 / 60 / 24`
    # Check the condition for deleting untaged images
    if [ $month_passed -gt $DAYS ]
    then
     echo "The image $image is untaged and not pushed since $DAYS days, since it will be deleted" >> thisshouldbedeleted_
    fi
  done
}

function dealWithTagedImages () {
  # For every image
  for image_info in `cat taged_images_ | tr -d '"'`
  do
    # Get image resourceUrl
    image=$(echo $image_info | awk '{ print $1 }')

    # Transform the date of the last sec scan
    data_t=`date --date=$(echo $image_info | awk '{ print $2 }')  +"%s"`
    data_at=`date +"%s"`
    sub=`expr $data_at - $data_t`
    # Calculate how many days since it has be pushed
    month_passed=`expr $sub / 60 / 60 / 24`
    # Recalculate the condition and check it as for taged images
    condition_override=$(expr $DAYS \* 2)
    if [ $month_passed -gt $condition_override ]
    then
     echo "The image $image is taged but not pushed since $DAYS days, since it will be deleted" >> thisshouldbedeleted_
    fi
  done
}

main(){
  # Get entries
  REGISTRY=$1
  DAYS=$2

  # IFS
  IFS=$'\n'

  # Get image repositories
  getRepos

  # For each repository
  for repository in `cat repositorys_`
  do
    # Separate tagged and untaged images from the repository
    gcloud beta container images list-tags --show-occurrences $REGISTRY$repository --format=json --filter='NOT tags:*' | jq '.[] | select(.DISCOVERY[].kind== "DISCOVERY") | "\(.DISCOVERY[].resourceUrl) \(.DISCOVERY[].updateTime)"' > untaged_images_
    gcloud beta container images list-tags --show-occurrences $REGISTRY$repository --format=json --filter='tags:*' | jq '.[] | select(.DISCOVERY[].kind== "DISCOVERY") | "\(.DISCOVERY[].resourceUrl) \(.DISCOVERY[].updateTime)"' > taged_images_

    # Deal with each of them accordingly
    dealWithUntagedImages
    dealWithTagedImages
  done

  # Done
  exit 0
}

main $1 $2
