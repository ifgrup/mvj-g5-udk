class PWorldPathNode extends Info placeable;

var Float Radius;
var() int id;
var() Const EditConst DrawSphereComponent RadiusComponent;

function PostBeginPlay()
{
	Super.PostBeginPlay();
}

function Inicia()
{
	Radius = RadiusComponent.SphereRadius;
}

defaultproperties
{
	Begin Object Class=DrawSphereComponent Name=DrawSphere0
     	SphereColor=(B=0,G=0,R=255,A=255)
     	SphereRadius=100.000000
		HiddenGame=false
	End Object
	RadiusComponent=DrawSphere0
	Components.Add(DrawSphere0);
	ScanRange=11000.0
}