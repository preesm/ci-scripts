NBARGS=3
function print_usage() {
    echo
    echo "Usage: $0 <applications_directory> <workspace> <eclipse_directory>"
    echo "    <applications_directory>      Path to folder containing the project(s) to execute"
    echo "    <workspace>                   Path to eclipse workspace to use"
    echo "    <eclipse_directory>           Path to folder containing eclipse installation to use"
}

if [ $# -lt $NBARGS ]; then
    print_usage
    exit $E_BADARGS
fi

[ ! -d "$1" ] && echo "Missing application directory" && print_usage && exit $E_BADARGS
[ ! -d "$2" ] && echo "Missing workspace directory" && print_usage && exit $E_BADARGS
[ ! -d "$3" ] && echo "Missing eclipse directory" && print_usage && exit $E_BADARGS

APPDIR=$1
WORKSPACE=$2
ECLIPSEDIR=$3

echo "Copy projects in eclipse workspace"
cp -r $APPDIR/* $WORKSPACE

echo "Register projects in eclipse workspace"
$ECLIPSEDIR/eclipse -nosplash -consoleLog -application org.ietr.preesm.cli.workspaceSetup -data $WORKSPACE $WORKSPACE