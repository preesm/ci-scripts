#!/bin/bash
source $(dirname $0)/preesm_defines.sh

echo "***START*** $0 $(date -R)"


mkdir -p $PREESMWORK

rm -fr $ECLIPSERUN
rm -fr $ECLIPSEBUILD

mkdir $ECLIPSERUN
mkdir $ECLIPSEBUILD

pushd $PREESMWORK

echo "Downloading Eclipse"
wget --progress=dot:mega $ECLIPSEURL

ECLIPSEARCHIVE=$(echo eclipse-platform-*.tar.gz)

echo "Uncompressing"
tar -xzaf $ECLIPSEARCHIVE

echo "Update java max heap size"
sed -i -e "s/-Xmx384m/-Xmx512m/g" eclipse/eclipse.ini

echo "Copying eclipse/* into $ECLIPSERUN and $ECLIPSEBUILD"
cp -r eclipse/* $ECLIPSERUN
cp -r eclipse/* $ECLIPSEBUILD

echo "Deleting 'eclipse' directory and archive downloaded"
rm -rf eclipse
rm $ECLIPSEARCHIVE

echo "Installing plugins required for build step into eclipse.build"
BUILDDEPS="org.eclipse.pde.feature.group,org.eclipse.emf.sdk.feature.group,org.eclipse.xtext.sdk.feature.group,org.eclipse.graphiti.sdk.feature.feature.group,org.eclipse.cdt.feature.group"
$ECLIPSEBUILD/eclipse   -nosplash -consoleLog \
                        -application org.eclipse.equinox.p2.director \
                        -destination $ECLIPSEBUILD \
                        -repository $ECLIPSEREPOSITORY \
                        -followReferences \
                        -installIU $BUILDDEPS

popd

pushd $DIR/../../p2-admin
mvn clean package
popd

echo "***END*** $0 $(date -R)"
