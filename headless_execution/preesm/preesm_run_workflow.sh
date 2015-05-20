#!/bin/bash
NBARGS=3
function print_usage() {
    echo
    echo "Usage: $0 <workspace> <eclipse_directory> <project> [<workflow> <scenario>]"
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

WORKSPACE=$1
ECLIPSEDIR=$2
PROJECT=$3
WORKFLOW=$4
SCENARIO=$5

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