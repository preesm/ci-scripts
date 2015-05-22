#!/bin/bash
NBARGS=4
function print_usage() {
    echo
    echo "Usage: $0 <applications_directory> <workspace> <eclipse_directory> <project> [<workflow> <scenario>]"
    echo "    <applications_directory>      Path to folder containing the project(s) to execute"
    echo "    <workspace>                   Path to eclipse workspace to use"
    echo "    <eclipse_directory>           Path to folder containing eclipse installation to use"
    echo "    <project>                     Name of the project containing the workflow and the scenario to execute"
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
PROJECT=$4
WORKFLOW=$5
SCENARIO=$6

# echo "Copy projects in eclipse workspace"
# cp -r $APPDIR/* $WORKSPACE

echo "Register projects in eclipse workspace"
$ECLIPSEDIR/eclipse -nosplash -consoleLog -application org.ietr.preesm.cli.workspaceSetup -data $WORKSPACE $APPDIR

if [ -z $WORKFLOW ]; then
    WORKFLOWMSG="workflow(s)"
else
    WORKFLOWMSG="workflow: $WORKFLOW"
fi
if [ -z $SCENARIO ]; then
    SCENARIOMSG="scenario(s)"
else
    SCENARIOMSG="scenario: $SCENARIO"
fi

echo "   Run $WORKFLOWMSG and $SCENARIOMSG"
$ECLIPSEDIR/eclipse -nosplash -consoleLog -application org.ietr.preesm.cli.workflowCli -data $WORKSPACE $PROJECT $WORKFLOW $SCENARIO