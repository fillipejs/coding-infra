if [[ $# -ne 2 ]]
then
  echo '== Please run this script passing the correct arguments ==
  ==> EXAMPLE: thisscript.sh $REPOSITORY $DATE
      where $REPOSITORY stands for which repository you wish to clean
      and $DATE is the date which images pushed before should be deleted'
  exit 0
fi

# IFS
IFS=$'\n'

# Get image repositories
gcloud container images list | grep $1 > repositorysb_

# For each repository
for repository in `cat repositorysb_`
do
  # Get all images not scanned for security anymore
  for image in $(gcloud container images list-tags $repository --limit=999999 --sort-by=TIMESTAMP --filter="timestamp.datetime < '$2'" --format='get(digest)')
  do
   gcloud container images delete -q --force-delete-tags $repository@$image
  done
done

rm -f repositorysb_

# Done
exit 0
