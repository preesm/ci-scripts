#!/bin/bash

# exits when a command returned non 0 value
set -e
export E_BADARGS=64

#[ ! -d "$1" ] && echo "Missing working directory folder" && exit $E_BADARGS
[ -z "$BUILDTYPE" ] && export BUILDTYPE="tests" && echo "Variable BUILDTYPE has not been set. Initialized to \"tests\""

export PREESMWORK="$(readlink -f $1)"

ARCH=`uname -m`

if [ "$ARCH" == "x86_64" ]; then
	ECLIPSE_ARCH="-x86_64"
else
	ECLIPSE_ARCH=""
fi

# Used to download the base platform version of eclipse
export ECLIPSEURL="http://mirror.switch.ch/mirror/eclipse/downloads/drops4/R-4.4.2-201502041700/eclipse-platform-4.4.2-linux-gtk$ECLIPSE_ARCH.tar.gz"

# Used to download dependencies (both runtime and build eclipse)
ECLIPSEVERSION=luna
export ECLIPSEREPOSITORY=http://download.eclipse.org/releases/$ECLIPSEVERSION

export ECLIPSERUN=$PREESMWORK/eclipse.runtime
export ECLIPSEBUILD=$PREESMWORK/eclipse.build

export BUILDDIR=$PREESMWORK/build.dir.$BUILDTYPE
export PLUGINSDIR=$BUILDDIR/plugins
export FEATURESDIR=$BUILDDIR/features

# Get the path of the current script. This script is necessary to resolve symlinks to this script
# see http://stackoverflow.com/a/246128/1887976
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Set the path of the p2-admin binary, generated from orcc_eclipse_setup script
if [ "$ARCH" == "x86_64" ]; then
	P2ADMIN_ARCH="x86_64"
else
	P2ADMIN_ARCH="x86"
fi

export P2ADMIN=$DIR/../../p2-admin/org.eclipselabs.equinox.p2.admin.product/target/products/org.eclipse.equinox.p2.admin.rcp.product/linux/gtk/$P2ADMIN_ARCH/p2-admin/p2-admin

export JGRAPHTPATH=$DIR/../lib/jgrapht-0.9.0
