#! /bin/bash

ARCH=`uname -m`
if [ "$ARCH" == "x86_64" ]; then
	ECLIPSE_ARCH="-x86_64"
	P2ADMIN_ARCH="x86_64"
else
	ECLIPSE_ARCH=""
	P2ADMIN_ARCH="x86"
fi

ECLIPSEVERSION=mars
export ECLIPSEREPOSITORY="http://download.eclipse.org/releases/$ECLIPSEVERSION"
export ECLIPSEURL="http://www.mirrorservice.org/sites/download.eclipse.org/eclipseMirror/eclipse/downloads/drops4/R-4.5.2-201602121500/eclipse-platform-4.5.2-linux-gtk$ECLIPSE_ARCH.tar.gz"

export P2ADMIN="$WORKSPACE/git/ci-scripts/p2-admin/org.eclipselabs.equinox.p2.admin.product/target/products/org.eclipse.equinox.p2.admin.rcp.product/linux/gtk/$P2ADMIN_ARCH/p2-admin/p2-admin"

export DFTOOLSMAINFEATUREID="org.ietr.dftools.feature"
export GRAPHITIMAINFEATUREID="org.ietr.dftools.graphiti.feature"
export PREESMMAINFEATUREID="org.ietr.preesm.feature"
