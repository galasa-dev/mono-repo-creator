#!/usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#
# Objectives:
# - Create a new github repo which contains all the source code from the old ones
# - Retaining all the commit histories of all the github repos pulled in.
# - Delete the previous version of the github repo.
# - Move the source code into 'modules' within the target github repo so files don't clash.
# - Overlay the target repo with some files specifically from here.
#

# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
# echo "Running from directory ${BASEDIR}"
export ORIGINAL_DIR=$(pwd)
cd "${BASEDIR}"

PROJECT_DIR=$(pushd $BASEDIR/.. 2>&1 >> /dev/null; pwd ; popd 2>&1 >> /dev/null)
WORKSPACE_DIR=$(pushd $PROJECT_DIR/.. 2>&1 >> /dev/null; pwd ; popd 2>&1 >> /dev/null)

#--------------------------------------------------------------------------
#
# Set Colors
#
#--------------------------------------------------------------------------
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#--------------------------------------------------------------------------
#
# Headers and Logging
#
#--------------------------------------------------------------------------
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ;}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ;}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ;}
debug() { printf "${white}%s${reset}\n" "$@" ;}
info() { printf "${white}➜ %s${reset}\n" "$@" ;}
success() { printf "${green}✔ %s${reset}\n" "$@" ;}
error() { printf "${red}✖ %s${reset}\n" "$@" ;}
warn() { printf "${tan}➜ %s${reset}\n" "$@" ;}
bold() { printf "${bold}%s${reset}\n" "$@" ;}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ;}


#--------------------------------------------------------------------------
# Variables
#
# Tailor these to suit your environment
#-------------------------------------------------------------------------- 
export GIT_ORG="galasa-dev"

function delete_local_galasa_repo() {
    h2 "Deleting the $GALASA_DIR repo"
    rm -fr $GALASA_DIR
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to delete existing galasa repo folder" ; exit 1 ; fi
    success "Made sure any existing content was deleted"
}

function create_galasa_repo_local() {
    h2 "Creating the $GALASA_DIR repo locally"
    mkdir -p $GALASA_DIR
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to create the new galasa repo folder" ; exit 1 ; fi
    success "'galasa' folder created"
}

function initialise_git() {
    
    git config --global init.defaultBranch main
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to configure 'main' as the most important and default branch" ; exit 1 ; fi
    success "Configured 'main' to be the main branch"
    cd $GALASA_DIR

    git init 
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to initialise git in the 'galasa' folder" ; exit 1 ; fi
    success "Git initialised in the 'galasa' project folder"

    git config --local  commit.gpgsign false
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to turn off signed commits in the 'galasa' folder" ; exit 1 ; fi
    success "Git commit signing turned off in the 'galasa' project folder OK."

    git commit -m "Initial commit of the mono repo" --allow-empty
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed our first commit in the 'galasa' git repo" ; exit 1 ; fi
    success "Committed the changes for repo $REPO"
}

function copy_overlays_into_mono_repo() {
    h2 "Copying 'overlays' into the 'galasa' project"
    cmd="cp -R $PROJECT_DIR/overlays/* $GALASA_DIR"
    info "Command is $cmd"
    $cmd
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to copy 'overlays' into the 'galasa' folder" ; exit 1 ; fi
    success "Copied overlays over the top of the original repo contents."

    h2 "Copying hidden folders from 'overlays' into the 'galasa' project"
    cmd="cp -R $PROJECT_DIR/overlays/. $GALASA_DIR"
    info "Command is $cmd"
    $cmd
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to copy hidden folders from 'overlays' into the 'galasa' folder" ; exit 1 ; fi
    success "Copied hidden folders from overlays over the top of the original repo contents."

    git add .
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to add 'overlays' into the 'galasa' repo staging area" ; exit 1 ; fi
    success "Added 'overlays' into the 'galasa' repo staging area OK"

    git commit -m "Adding overlays into the mono-repo."
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to commit 'overlays' into the 'galasa' repo" ; exit 1 ; fi
    success "Committed 'overlays' into the 'galasa' repo OK"
}

function merge_in_repo() {
    REPO=$1
    h2 "Merging in repository $REPO"
    cd $GALASA_DIR

    cmd="git remote add -f src_repo git@github.com:galasa-dev/$REPO.git"
    $cmd
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to set up a remote git reference to repo $REPO" ; exit 1 ; fi
    success "Set up a remote git reference to git repo $REPO"

    cmd="git merge --allow-unrelated-histories src_repo/main --no-edit"
    $cmd
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to merge the $REPO repo into the 'galasa' repo. command is '$cmd'" ; exit 1 ; fi
    success "Merged $REPO repo contents into the 'galasa' repo."

    # Move all the files except the 'modules' folder into the 'modules' folder.
    # Avoiding a recursion problem of moving the modules folder into itself.
    mkdir -p $GALASA_DIR/modules/$REPO
    for file_path in $GALASA_DIR/* .[^.]*; do
        file_name=$(basename -- "$file_path")
        info "Moving file $file_path ... file name is $file_name"
        if [[ "$file_name" != "modules" ]] && [[ "$file_name" != ".git" ]]; then 
            mv $GALASA_DIR/"$file_name" "$GALASA_DIR/modules/$REPO"
            rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to move the file $file_name into the 'galasa/modules' folder" ; exit 1 ; fi
        fi
    done
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to move the $REPO repo contents into the 'galasa/modules' folder" ; exit 1 ; fi
    success "Moved the $REPO repo contents into the 'galasa/modules' folder"

    git add .
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to add the file moves to git the staging area." ; exit 1 ; fi
    success "Added the file moves to git the staging area."

    git commit -m "Merging in the $REPO repository contents."
    rc=$? ; if [[ "$rc" != "0" ]]; then error "Failed to common the move of $REPO content to the 'galasa/modules/$REPO' folder." ; exit 1 ; fi
    success "Committed the file moves to git for the $REPO content."

    git remote remove src_repo
}

function clean_temp_folder() {
    h2 "Cleaning out the temp folder"
    TEMP_FOLDER=$PROJECT_DIR/temp
    rm -fr $TEMP_FOLDER
    mkdir -p $TEMP_FOLDER
    success "Temporary folder $TEMP_FOLDER created and cleaned"
}

function push_repo_to_github() {
    h2 "Pushing the 'galasa' repo to github.com"
    cd $GALASA_DIR
    gh repo new \
    --description "The Galasa source code" \
    --public \
    --push \
    --remote $GIT_ORG/galasa.git \
    --source $GALASA_DIR
}

function delete_repo_on_github() {
    h2 "Deleting the 'galasa' repo on github.com"
    gh repo delete git@github.com:$GIT_ORG/galasa.git --yes
}

h1 "Re-generating the galasa mono-repository"
GALASA_DIR=${WORKSPACE_DIR}/galasa

delete_local_galasa_repo
clean_temp_folder
create_galasa_repo_local
initialise_git

merge_in_repo wrapping
merge_in_repo buildutils
merge_in_repo gradle
merge_in_repo maven
merge_in_repo framework
merge_in_repo extensions
merge_in_repo managers
merge_in_repo obr

copy_overlays_into_mono_repo

delete_repo_on_github
push_repo_to_github

