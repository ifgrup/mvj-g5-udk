class PWorldPathNode extends Info placeable;

var Float Radius;
var() int id;
var() Const EditConst DrawSphereComponent RadiusComponent;
var() float ScanRange;
var array<int> Tags;
var bool generado;
var float DistanceToBase;
var int Cuantos;

function PostBeginPlay()
{
	Super.PostBeginPlay();
}

function Inicia()
{
	Radius = RadiusComponent.SphereRadius;
	id = Rand(255);
	Tags.AddItem(id);
	generado = false;
	//DistanceToBase = VSize(Location - PGame(WorldInfo.Game).Base.Location);
}

function Scan(bool OnlyGenerated)
{
	local array<PWorldPathNode> pNodos;
	local int i;
	local PWorldPathNode pNodo, pNuevoNodo;
	local Vector vMidPoint;


	pNodos = PGame(WorldInfo.Game).NodosMundo;
	
	for(i = 0; i < pNodos.Length; i++)
	{
		pNodo = pNodos[i];
	
		if(pNodo == self)
			continue;
		
		if(pNodo.Cuantos > 3)
			continue;

		if(FastTrace(Location, pNodo.Location,,true))
		{
			if(VSize(Location - pNodo.Location) < ScanRange)
			{
				Cuantos++;
				vMidPoint = (Location + pNodo.Location) / 2;
				//Trace(HitLocation, HitNormal, PGame(Worldinfo.Game).GetCentroPlaneta(), vMidPoint,,,,TRACEFLAG_Bullet);
				pNuevoNodo = spawn(class'PWorldPathNode',,,vMidPoint);
				pNuevoNodo.generado = true;
				pNuevoNodo.Tags.AddItem(id);
				pNuevoNodo.Cuantos++;
				PGame(WorldInfo.Game).AddWorldPathNode(pNuevoNodo);
			}
		}
	}
}

function Proyecta()
{
	local Vector HitLocation, HitNormal;
	local float Distance;

	Trace(HitLocation, HitNormal, PGame(WorldInfo.Game).GetCentroPlaneta(), Location,,,,TRACEFLAG_Bullet);

	//SetLocation(HitLocation);
	DistanceToBase = VSize(PGame(WorldInfo.Game).PlayerBase.Location - Location);
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
	Cuantos=0
}