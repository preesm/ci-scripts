#! /bin/bash

source $(dirname $0)/env_setup.sh

echo "Downloading Eclipse"
wget --progress=dot:mega $ECLIPSEURL

ECLIPSEARCHIVE=$(echo eclipse-platform-*.tar.gz)

echo "Uncompressing"
tar -xzaf $ECLIPSEARCHIVE

echo "Update java max heap size"
sed -i -e "s/-Xmx384m/-Xmx512m/g" eclipse/eclipse.ini

echo "Moving eclipse/* into $ECLIPSE_RUN_MAVEN"
rm -rf $ECLIPSE_RUN_MAVEN
mkdir $ECLIPSE_RUN_MAVEN
cp -r eclipse/* $ECLIPSE_RUN_MAVEN
rm -r eclipse

echo "Cleaning archive"
rm $ECLIPSEARCHIVE

cd $ECLIPSE_RUN_MAVEN

echo ""
echo "****************************************************************"
echo "*       Installs DFTOOLS plugins into eclipse runtime          *"
echo "****************************************************************"
echo ""

echo "-> Uninstall old DFTOOLS feature"
$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSE_RUN_MAVEN \
  -uninstallIU ${DFTOOLSMAINFEATUREID}.feature.group \
|| echo -e "\n*** There is no existing DFTOOLS feature to uninstall. This is probably the first time this script is \n\
launched since last eclipse reinstall. Please ignore the previous error message. ***"

echo ""
echo "-> Install new DFTOOLS feature"

$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSE_RUN_MAVEN \
  -artifactRepository file:$LOCALREPO_MAVEN \
  -metadataRepository file:$LOCALREPO_MAVEN \
  -repository $ECLIPSEREPOSITORY \
  -installIU ${DFTOOLSMAINFEATUREID}.feature.group

echo ""

echo ""
echo "****************************************************************"
echo "*       Installs GRAPHITI plugins into eclipse runtime         *"
echo "****************************************************************"
echo ""

echo "-> Uninstall old GRAPHITI feature"
$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSE_RUN_MAVEN \
  -uninstallIU ${GRAPHITIMAINFEATUREID}.feature.group \
|| echo -e "\n*** There is no existing GRAPHITI feature to uninstall. This is probably the first time this script is \n\
launched since last eclipse reinstall. Please ignore the previous error message. ***"

echo ""
echo "-> Install new GRAPHITI feature"

$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSE_RUN_MAVEN \
  -artifactRepository file:$LOCALREPO_MAVEN \
  -metadataRepository file:$LOCALREPO_MAVEN \
  -repository $ECLIPSEREPOSITORY \
  -installIU ${GRAPHITIMAINFEATUREID}.feature.group

echo ""

echo ""
echo "****************************************************************"
echo "*       Installs PREESM plugins into eclipse runtime           *"
echo "****************************************************************"
echo ""

echo "-> Uninstall old PREESM feature"
$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSE_RUN_MAVEN \
  -uninstallIU ${PREESMMAINFEATUREID}.feature.group \
|| echo -e "\n*** There is no existing PREESM feature to uninstall. This is probably the first time this script is \n\
launched since last eclipse reinstall. Please ignore the previous error message. ***"

echo ""
echo "-> Install new PREESM feature"
$P2ADMIN -application org.eclipse.equinox.p2.director \
  -destination $ECLIPSE_RUN_MAVEN \
  -artifactRepository file:$LOCALREPO_MAVEN \
  -metadataRepository file:$LOCALREPO_MAVEN \
  -repository $ECLIPSEREPOSITORY \
  -installIU ${PREESMMAINFEATUREID}.feature.group

echo ""

echo "***END*** $0 $(date -R)"
