# BEFORE YOU READ ON...

This repository is no longer used. Any code which is still relevant has been moved to the main galasa
repository here: https://github.com/galasa-dev/galasa

# BEFORE YOU READ ON...

This repository is no longer used. Any code which is still relevant has been moved to the main galasa
repository here: https://github.com/galasa-dev/galasa


# Mono-repo

This is a temporary repo aimed at creating a mono-repo
by joining all of the existing galasa depositories together
into a single repository.

## Objectives
- A set of scripts which will create a mono-repo from all the
current repositories in github.
- Be able to retain the commit history of each repository by 
merging all the repositories together using git merge, 
- Once merged, moving each file such that each original repository looks like a child of the main repository top level.
- Be able to wipe that repository out and re-create it regularly
so that it stays up to date with the smaller single repositories.
- Have an 'overlay' folder which is copied onto the resultant mega-repo so we can customise the content
- Create an overall build process for all the code

