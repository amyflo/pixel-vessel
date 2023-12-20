GG.camera().position( @(0, 0, 12) );
SphereGeometry bulb;

GScene scene;
NormalsMaterial normalMat;
normalMat.polygonMode(Material.POLYGON_FILL);

GMesh teapot;
teapot.set(bulb, normalMat);
teapot --> scene;
teapot.position(@(0, 0, 0));

GMesh meshes[geos.size()*4];