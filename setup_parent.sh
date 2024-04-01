#!/bin/bash

set -e

base_dir=$(pwd)

# Parse command-line options
name=""
remote=""
destination=""

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -n, --name <name>       Name of the project"
  echo "  -r, --remote <remote>   Remote repository URL"
  echo "  -d, --destination <destination>"
  echo "                          Destination folder"
  echo ""
  echo "Example:"
  echo ""
  echo "$0 --name mycomponent --remote 'https://github.com/me/mycomponent.git' --destination ~/myproject-parent"
  echo ""
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name) shift; name="$1" ;;
    -r|--remote) shift; remote="$1" ;;
    -d|--destination) shift; destination="$1" ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
  shift
done

# Validate if required options are provided
if [ -z "$name" ] || [ -z "$remote" ] || [ -z "$destination" ]; then
  usage=
  exit 1
fi

echo "Setup parent repository for $project with remote $project_url in $destination"

if curl -ILs "$project_url" | tac | grep -m1 HTTP | grep 404; then
  echo "$project_url does not exist, goto GitHub and setup $project_url as empty repository!"
  exit 0
fi


echo "Setup git repository"
mkdir -p "$destination"
cd "$destination"
git init
git branch -m main

echo "Setup basic files repository"
echo "# Parent repository for $project" > "$destination/README.md"
echo "0.0.1dev" > "$destination/VERSION"
cp "$base_dir/makefile" makefile
cp "$base_dir/.gitignore" .gitignore

git add .
git commit -m "Setup repository"


echo "Add requirements"
wget https://github.com/leolani/cltl-requirements/archive/main.zip
unzip main.zip
rm main.zip
mv cltl-requirements-main cltl-requirements
echo "# Requirements for $project" > cltl-requirements/README.md
cp "base_dir/requirements.txt" cltl-requirements/requirements.txt
git add .
git commit -m "Add cltl-requirements"

exit 0

echo "Add submodules"
git submodule add -b main --name util https://github.com/leolani/cltl-build.git util
git submodule add -b main --name cltl-combot https://github.com/leolani/cltl-combot.git cltl-combot
git submodule add -b main --name cltl-backend https://github.com/leolani/cltl-backend.git cltl-backend
git submodule add -b main --name cltl-emissor-data https://github.com/leolani/cltl-emissor-data.git cltl-emissor-data
git submodule add -b main --name cltl-eliza https://github.com/leolani/cltl-eliza.git cltl-eliza
git submodule add -b main --name cltl-asr https://github.com/leolani/cltl-asr.git cltl-asr
git submodule add -b main --name cltl-chat-ui https://github.com/leolani/cltl-chat-ui.git cltl-chat-ui


echo "Add ${project}-app"
git submodule add -b main --name "$project-app" "https://github.com/leolani/cltl-template.git" "$project-app"
cd "$project-app"
./init_component.sh -n "$project-app" --remote "https://github.com/leolani/$project-app.git" --namespace "$project"
cd ..

git submodule sync -recursive

echo "Add folders for project specific code"
mkdir src/
mkdir src/$project
mkdir src/$project_service

mkdir test/
