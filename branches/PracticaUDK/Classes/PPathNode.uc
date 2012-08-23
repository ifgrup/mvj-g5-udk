class PPathNode extends Info placeable;

var Float Radius;
var() int id;
var() Const EditConst DrawSphereComponent RadiusComponent;

var vector m_floor_nodo; //Floor del punto donde estaba el scout al crear el nodo
var vector m_direccion_nodo; //Dirección del scout cuando creó el punto. Usado para crear el random

function PreBeginPlay()
{
	Radius = RadiusComponent.SphereRadius;
	Super.PreBeginPlay();
}

defaultproperties
{
	Begin Object Class=DrawSphereComponent Name=DrawSphere0
     	SphereColor=(B=255,G=70,R=64,A=255)
     	SphereRadius=48.000000
		HiddenGame=false
	End Object
	RadiusComponent=DrawSphere0
	Components.Add(DrawSphere0);
}