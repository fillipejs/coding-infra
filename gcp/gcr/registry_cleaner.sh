if [[ $# -ne 2 ]]
then
  echo '== Please run this script passing the correct arguments ==
  ==> EXAMPLE: thisscript.sh $REPOSITORY $NIMAGES
      where $REPOSITORY stands for which repository you wish to clean
      and $NIMAGES is the number of images to maintain on each repository (the newer ones will be keeped)'
  exit 0
fi

# IFS
IFS=$'\n'

# Get image repositories
gcloud container images list | grep $1 > repositorys_

# For each repository
for repository in `cat repositorys_`
do
  # Get all images not scanned for security anymore
  for image in $(gcloud container images list-tags $repository --limit=999999 --format='get(digest)' | tail -n +$(expr $2 + 1))
  do
   gcloud container images delete -q --force-delete-tags $repository@$image
  done
done

rm -f repositorys_

# Done
exit 0
