#!/bin/bash

# exits when a command returned non 0 value
set -e
export E_BADARGS=64

[ ! -d "$1" ] && echo "Missing git directory" && print_usage && exit $E_BADARGS

export REPOCONTAINER="$(readlink -f $1)"

# Setup eclipse classpath
ECLIPSECP=$(echo $ECLIPSEBUILD/plugins/*.jar | sed -e "s/ /:/g")
# Add the missing junit4 plugin, to allow compiling xtend in tests plugin
ECLIPSECP=$ECLIPSECP:$(echo $ECLIPSEBUILD/plugins/org.junit_4*/junit.jar)
# Add JGrapht and BSH
ECLIPSECP=$ECLIPSECP:$REPOCONTAINER/graphiti/plugins/org.jgrapht:$REPOCONTAINER/preesm/plugins/org.ietr.preesm.memory/lib/bsh-2.1.7.jar

export ECLIPSECP

GRAPHITIREPO=$REPOCONTAINER/graphiti
GRAPHITIPLUGINSDIR=$GRAPHITIREPO/plugins/
export GRAPHITIPLUGINSDIR
GRAPHITIFEATURESDIR=$GRAPHITIREPO/
export GRAPHITIFEATURESDIR

DFTOOLSREPO=$REPOCONTAINER/dftools/
DFTOOLSPLUGINSDIR=$DFTOOLSREPO/eclipse/plugins/
export DFTOOLSPLUGINSDIR
DFTOOLSFEATURESDIR=$DFTOOLSREPO/eclipse/
export DFTOOLSFEATURESDIR

PREESMREPO=$REPOCONTAINER/preesm
PREESMPLUGINSDIR=$PREESMREPO/plugins
export PREESMPLUGINSDIR
PREESMFEATURESDIR=$PREESMREPO/
export PREESMFEATURESDIR

# Setup Xtend classpaths
# Source folders from Graphiti
for PROJECT in $GRAPHITIPLUGINSDIR/*; do
  for d in $PROJECT/*/; do
    name=$(basename "$d")
    if [[ $name == "src" || $name == "lib" || $name == "src-gen" ]] ; then
      GRAPHITISRCFOLDERS=$GRAPHITISRCFOLDERS:$d
    fi
  done
done
# Remove the first ':'
GRAPHITISRCFOLDERS=$(echo $GRAPHITISRCFOLDERS | sed -e "s/^://g")
export GRAPHITISRCFOLDERS

# Source folders from DFTools
for PROJECT in $DFTOOLSPLUGINSDIR/*; do
  for d in $PROJECT/*/; do
    name=$(basename "$d")
    if [[ $name == "src" || $name == "lib" || $name == "src-gen" ]] ; then
      DFTOOLSSRCFOLDERS=$DFTOOLSSRCFOLDERS:$d
    fi
  done
done
# Remove the first ':'
DFTOOLSSRCFOLDERS=$(echo $DFTOOLSSRCFOLDERS | sed -e "s/^://g")
export DFTOOLSSRCFOLDERS

# Source folders from PREESM
for PROJECT in $PREESMPLUGINSDIR/*; do
  for d in $PROJECT/*/; do
    name=$(basename "$d")
    if [[ $name == "src" || $name == "lib" || $name == "src-gen" ]] ; then
      PREESMSRCFOLDERS=$PREESMSRCFOLDERS:$d
    fi
  done
done
# Remove the first ':'
PREESMSRCFOLDERS=$(echo $PREESMSRCFOLDERS | sed -e "s/^://g")
export PREESMSRCFOLDERS