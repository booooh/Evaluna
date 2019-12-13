#! /bin/bash

# * by default, master doesn't create a tag, but creates a new docker image and tags it with the same tag
# * when a "release/<foo>" tag is placed, and pushed to upstream, the following will happen:
#    1. create the docker image, tag it with "foo" and push it, 
#    2. create a release branch "release/<foo>", and commit the updated helm chart with the docker image tag updated to "foo".
# * now HEAD on "release/<foo>" is a valid commit, and we should merge it back to master, so create a pull request, mnaully tag as a release via UI in github 

git_commit=$1
git_branch=$2
git_tag=$3

current_tag=$(git describe --abbrev=0 --tags)
if [[ ! "$git_tag" =~ ^release/.* ]] ; then
    echo "ERROR: tag $git_tag does not match pattern release/<foo>"
    exit 1
fi
docker_tag=${git_tag##release/}

# create the release branch
git checkout -b $git_tag

# build and push the docker images
bash dss/scripts/deploy.sh $git_commit $docker_tag

# update the helm chart
# TODO: determine bump_part based on difference between current app version and new app version
python dss/scripts/update_chart_version.py --bump_part patch --app_version "${docker_tag}"

git commit -am "Preparing release branch for ${docker_tag}"

# configure the remote repository, and push the commit
remote=https://$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG
git push -u $remote refs/heads/$git_tag:refs/heads/$git_tag
