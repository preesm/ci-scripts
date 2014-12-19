NBARGS=2
function print_usage() {
    echo
    echo "Usage: $0 <working_directory> <git_dir> ...]"
    echo "    <working_directory>           Path to folder used to perform build & tests"
    echo "    <git_dir>             		Path to folder containing PREESM, DFTools & Graphiti repositories"
}

source $(dirname $0)/preesm_defines.sh

if [ $# -lt $NBARGS ]; then
    print_usage
    exit $E_BADARGS
fi

[ ! -d "$2" ] && echo "Missing git directory" && print_usage && exit $E_BADARGS

REPOCONTAINER=$2

# Download and install 2 eclipse (.build and .runtime)
# @param folder where to download and install eclipse
preesm_eclipse_setup.sh $PREESMWORK
# Build Graphiti using eclipse.build and install it into eclipse.runtime
# @param folder where eclipse is installed
# @param folder containing the graphiti feature project
# @param folder containing the graphiti plug-ins
graphiti_build.sh $PREESMWORK $REPOCONTAINER/graphiti/ $REPOCONTAINER/graphiti/plugins/
# Build DFTools using eclipse.build and install it into eclipse.runtime
# @param folder where eclipse is installed
# @param folder containing the DFTools feature project
# @param folder containing the DFTools plug-ins
dftools_build.sh $PREESMWORK $REPOCONTAINER/dftools/eclipse/ $REPOCONTAINER/dftools/eclipse/plugins/
# Build PREESM using eclipse.build and install it into eclipse.runtime
# @param folder where eclipse is installed
# @param folder containing the PREESM feature project
# @param folder containing the PREESM plug-ins
preesm_build.sh $PREESMWORK $REPOCONTAINER/preesm/ $REPOCONTAINER/preesm/plugins/
