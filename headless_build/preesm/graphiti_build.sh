#!/bin/bash

NBARGS=3
function print_usage() {
    echo
    echo "Usage: $0 <working_directory> <feature_dir> <plugin_dir> [<plugin_dir> <plugin_dir> ...]"
    echo "    <working_directory>           Path to folder used to perform build & tests"
    echo "    <features_dir>                Path to eclipse features folder"
    echo "    <plugin_dir>                  Path(s) to folder(s) containing eclipse plugins directories"
}

source $(dirname $0)/preesm_defines.sh

if [ $# -lt $NBARGS ]; then
    print_usage
    exit $E_BADARGS
fi

[ ! -d "$2" ] && echo "Missing features directory" && print_usage && exit $E_BADARGS
[ ! -d "$3" ] && echo "Missing plugins directory" && print_usage && exit $E_BADARGS

SOURCESFEATUREDIR=$2

echo "***START*** $(date -R) Build type: $BUILDTYPE"
rm -fr $BUILDDIR
mkdir -p $PLUGINSDIR
mkdir -p $FEATURESDIR

cp -ur $SOURCESFEATUREDIR/* $FEATURESDIR

# Remove the 2 first arg from command line
shift 2
# Loop over resulting cli arguments
for arg; do
    cp -ur $arg/* $PLUGINSDIR
done

rm -fr $PLUGINSDIR/**/xtend-gen/*
rm -fr $PLUGINSDIR/**/src-gen/*
rm -fr $PLUGINSDIR/**/bin/*

echo ""
echo "****************************************************************"
echo "*             Generates Java sources from Xtend                *"
echo "****************************************************************"
echo ""

xtendoutputdir="xtend-output"
pushd $PLUGINSDIR
java -cp $ECLIPSECP:$SOURCEFOLDERS \
    org.eclipse.xtend.core.compiler.batch.Main \
    -useCurrentClassLoader \
    -d ./${xtendoutputdir} \
    "$SOURCEFOLDERS"

for xtendfile in $(find -name "*.xtend"); do
    # The path of the generated java file, under ${xtendoutputdir} folder
    fromJavaFile=$(echo $xtendfile | sed -e 's/.xtend/.java/g' | sed -e 's/\/src\//%/g' | cut -d'%' -f2)
    # The path where this java file should be moved before running java compilation
    toJavaFile=$(echo $xtendfile | sed -e 's/.xtend/.java/g' | sed -e 's/\/src\//\/xtend-gen\//g')
    mkdir -p $(dirname $toJavaFile)
    mv ${xtendoutputdir}/$fromJavaFile $toJavaFile
done

rm -fr $xtendoutputdir
popd

echo ""
echo "****************************************************************"
echo "*                    Launches PDE Build                        *"
echo "****************************************************************"
echo ""

# Define PDE build specific variables
BUILDFILE=$(echo $ECLIPSEBUILD/plugins/org.eclipse.pde.build_*)/scripts/build.xml
KEEPONLYLATESTVERSIONS=true # Set to false when a Release build will be defined

if [ "$BUILDTYPE" == "tests" ]; then
    PDEBUILDTYPE=I
    REPONAME="GRAPHITI Tests repository"
    NBUILDSTOKEEP=3
elif [ "$BUILDTYPE" == "nightly" ]; then
    PDEBUILDTYPE=N
    REPONAME="GRAPHITI Nightly builds"
    NBUILDSTOKEEP=45
else
    # Release build (not active yet)
    PDEBUILDTYPE=R
    REPONAME="GRAPHITI - Stable releases"
    NBUILDSTOKEEP=999999
fi

mkdir -p $BUILDDIR

# This will be used as default name for the top level folder of
# build features and plugins. Needs to rename it
ARCHIVEPREFIX=GRAPHITI_latest

BUILDID="${BUILDTYPE}_build"

GRAPHITIMAINFEATUREID="org.ietr.dftools.graphiti.feature"
ARTIFACTSFOLDER="final_artifacts"

# For information on following properties:
# - open build.properties from <eclipse_dir>/plugins/org.eclipse.pde.build_*/templates/headless-build/build.properties
# - http://help.eclipse.org/kepler/index.jsp?topic=%2Forg.eclipse.pde.doc.user%2Ftasks%2Fpde_feature_build.htm&cp=4_2_0_1
$ECLIPSEBUILD/eclipse   -nosplash -consoleLog -application org.eclipse.ant.core.antRunner \
                        -buildfile $BUILDFILE \
                        -DskipFetch=true \
                        -DtopLevelElementId=$GRAPHITIMAINFEATUREID \
                        -DtopLevelElementType=feature \
                        -DjavacSource=1.6 -DjavacTarget=1.6 \
                        -DbaseLocation=$ECLIPSEBUILD \
                        -DpluginPath=$ECLIPSEBUILD:$BUILDDIR \
                        -DbuildDirectory=$BUILDDIR \
                        -Dbase=$BUILDDIR \
                        -DbuildId=$BUILDID \
                        -DbuildType=$PDEBUILDTYPE \
                        -DbuildLabel=$ARTIFACTSFOLDER \
                        -DarchivePrefix=$ARCHIVEPREFIX \
                        -DcollectingFolder=binary_output \
                        -DoutputUpdateJars=true

echo ""
echo "****************************************************************"
echo "*                  Builds the p2 repository                    *"
echo "****************************************************************"

LOCALREPO=$PREESMWORK/repository.$BUILDTYPE
mkdir -p $LOCALREPO

echo ""
echo "-> Extract built zip file"
# Unzip the built zip, the created folder is $ARCHIVEPREFIX
unzip -o $BUILDDIR/$ARTIFACTSFOLDER/$GRAPHITIMAINFEATUREID-$BUILDID.zip -d $LOCALREPO

pushd $LOCALREPO > /dev/null

# Load version number computed from the build
featureFile=$(basename $ARCHIVEPREFIX/features/${GRAPHITIMAINFEATUREID}*)
VERSION=$(echo ${featureFile%.*} | cut -d'_' -f2)
CURRENTBUILD="${GRAPHITIMAINFEATUREID}_${VERSION}"

echo ""
echo "-> Rename $ARCHIVEPREFIX/ into $CURRENTBUILD/"
# Rename it to its final name
mv $ARCHIVEPREFIX $CURRENTBUILD

# Initialize a p2 repository in the extracted folder
echo ""
echo "-> Transform $CURRENTBUILD into a standard p2 repository"

$P2ADMIN -application org.eclipse.equinox.p2.publisher.FeaturesAndBundlesPublisher \
    -metadataRepository file:$(pwd)/${CURRENTBUILD} \
    -artifactRepository file:$(pwd)/${CURRENTBUILD} \
    -source $(pwd)/${CURRENTBUILD} \
    -compress

# Print p2.index files...
p2Index=<<EOF
version = 1
metadata.repository.factory.order = compositeContent.xml,\!
artifact.repository.factory.order = compositeArtifacts.xml,\!
EOF
# ... in the current repository
echo $p2Index > $(pwd)/${CURRENTBUILD}/p2.index
# ... in the top level composite repository
echo $p2Index > ./p2.index

# Create a tempoary file defining the category we will publish
pushd ${CURRENTBUILD} > /dev/null
CATEGORY=$GRAPHITIMAINFEATUREID.category.$BUILDTYPE
TMPFILE=$(mktemp)
cat > $TMPFILE <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<site>
    <category-def name="$CATEGORY" label="${REPONAME}"/>
    <feature url="$(ls features/${GRAPHITIMAINFEATUREID}*)" id="${GRAPHITIMAINFEATUREID}" version="${VERSION}">
        <category name="$CATEGORY"/>
    </feature>
</site>
EOF
popd > /dev/null

# Publish category for the current build
echo ""
echo "-> Register $CURRENTBUILD into category \"${REPONAME}\""
$P2ADMIN -application org.eclipse.equinox.p2.publisher.CategoryPublisher \
    -metadataRepository file:$(pwd)/${CURRENTBUILD} \
    -categoryDefinition file:$TMPFILE \
    -categoryQualifier -compress

# Delete oldest builds before creating the composite repo
echo ""
echo "-> Delete useless builds (all but the last ${NBUILDSTOKEEP})"
for oldDirectory in $(find -mindepth 1 -maxdepth 1 -type d -name "${GRAPHITIMAINFEATUREID}_*" | sort | head -n -${NBUILDSTOKEEP}); do
    echo "Delete ${oldDirectory}"
    rm -fr "${oldDirectory}"
done

# Delete repository indexes, will be fully re-generated in the next command
rm -fr compositeArtifacts.* compositeContent.*

echo ""
echo "-> Create p2 composite repository (top level, references all sub-repositories)"
$P2ADMIN -application org.eclipselabs.equinox.p2.composite.repository \
    -location file:$(pwd) \
    -add $(echo ${GRAPHITIMAINFEATUREID}_* | sed -e "s/ /,/g") \
    -repositoryName "$REPONAME" \
    -compressed

popd > /dev/null

# We don't want to install just built releases into eclipse.runtime
if [ "$BUILDTYPE" == "releases" ]; then
    exit 0
fi

echo ""
echo "****************************************************************"
echo "*       Installs GRAPHITI plugins into eclipse runtime         *"
echo "****************************************************************"

echo ""
echo "-> Uninstall old GRAPHITI feature"
$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSERUN \
  -uninstallIU ${GRAPHITIMAINFEATUREID}.feature.group \
|| echo -e "\n*** There is no existing GRAPHITI feature to uninstall. This is probably the first time this script is \n\
launched since last eclipse reinstall. Please ignore the previous error message. ***"

echo ""
echo "-> Install new GRAPHITI feature"
$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSERUN \
  -artifactRepository file:$LOCALREPO \
  -metadataRepository file:$LOCALREPO \
  -repository $ECLIPSEREPOSITORY \
  -installIU ${GRAPHITIMAINFEATUREID}.feature.echo

group ""
echo "***END*** $0 $(date -R)"
