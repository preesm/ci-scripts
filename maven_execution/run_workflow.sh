#!/bin/bash
NBARGS=4
function print_usage() {
    echo
    echo "Usage: $0 <applications_directory> <project> <workflow> <scenario>"
    echo "    <applications_directory>      Path to folder containing the project(s) to execute"
    echo "    <project>                     Name of the project containing the workflow and the scenario to execute"
    echo "    <workflow>                    Name of the workflow to execute"
    echo "    <scenario>                    Name of the scenario to execute"
}

if [ $# -lt $NBARGS ]; then
    print_usage
    exit $E_BADARGS
fi

APPDIR=$1
PROJECT=$2
WORKFLOW=$3
SCENARIO=$4

rm -rf workspace
mkdir workspace

echo "Register projects in eclipse workspace"
$ECLIPSE_RUN_MAVEN/eclipse -nosplash -consoleLog -application org.ietr.preesm.cli.workspaceSetup -data workspace $APPDIR
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
$ECLIPSE_RUN_MAVEN/eclipse -nosplash -consoleLog -application org.ietr.preesm.cli.workflowCli -data workspace $PROJECT -w $WORKFLOW -s $SCENARIO

echo "***END*** $0 $(date -R)"
