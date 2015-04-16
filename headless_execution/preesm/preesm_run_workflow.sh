#!/bin/bash

source $(dirname $0)/preesm_defines.sh

NBARGS=3
function print_usage() {
    echo
    echo "Usage: $0 <working_directory> <project_name> <workspace_directory> [<plugin_dir> <plugin_dir> ...]"
    echo "    <working_directory>           Path to folder used to perform build & tests"
    echo "    <project_path>              	Path to the project containing the workflow and scenario to execute"
    echo "	  <workspace_directory>			Path to the workspace where to execute"
}

if [ $# -lt $NBARGS ]; then
    print_usage
    exit $E_BADARGS
fi

[ ! -d "$2" ] && echo "Missing features directory" && print_usage && exit $E_BADARGS

PROJECT=$2
RUNWORKSPACE=$3

echo "***START*** $0 $(date -R)"

echo "Register projects in eclipse workspace"
$ECLIPSERUN/eclipse     -nosplash -consoleLog \
                        -application net.sf.orcc.cal.workspaceSetup \
                        -data $RUNWORKSPACE \
                        $APPDIR

echo "Run workflow from project $PROJECT"
$ECLIPSERUN/eclipse     -nosplash -consoleLog \
                        -application org.ietr.preesm.cli \
                        -data $RUNWORKSPACE \
                        $PROJECT

echo "***END*** $0 $(date -R)"