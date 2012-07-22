class PEnemy_AI_Scout extends AIController;

var Actor thePlayer;
var Actor theObjective;
var int id;
var vector OldLocation;
var vector OldDecalLocation;
var vector CurrentDestination;
var int RandomTicksCounter;
var int RandomTicksMax;
var int OffX, OffY;
var int OffsetX, OffsetY;
var int Step;
var array<PWorldPathNode> ListaNodosRecorridos;
var DecalMaterial Decal;
var MaterialInstanceConstant Mat;
var LinearColor ColorDecal;
var bool HasPath;
var int id_Path;
var float DestinationOffset;
var bool ArrivedCurrentDestination;
var Actor Destination;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	theObjective = PGame(WorldInfo.Game).PlayerBase;
	//RandomTicksMax = Rand(10) + 1;
	
	ColorDecal = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);

	Mat = new class'MaterialInstanceConstant';
	Mat.SetParent(MaterialInstanceConstant'Materiales.Decals.DecalSuelo1_INST');
	Mat.SetVectorParameterValue('Color', ColorDecal);
	/*Mat.SetScalarParameterValue('R', ColorDecal.R);
	Mat.SetScalarParameterValue('G', ColorDecal.G);
	Mat.SetScalarParameterValue('B', ColorDecal.B);*/

	SetTimer(1, false, 'BrainTimer');
}

function SetColor(LinearColor Col)
{
	ColorDecal = Col;
	Mat.SetVectorParameterValue('Color', ColorDecal);
}

function SetID(int i)
{
	id = i;
}

function DrawDebugInfo()
{
	DrawDebugLine(Pawn.Location, CurrentDestination, 0, 255, 0, false);
	DrawDebugSphere(CurrentDestination, 20, 20, 0, 255, 0, false);
}

function BrainTimer()
{
	local PPathNode nodo;
	local array<PWorldPathNode> pWNodos;
	local PPlayerBase pBase;
	local float fTimer;
	local int i;
	local int j;
	local float distancia, tmp;

	ClearTimer('BrainTimer');
	//FlushPersistentDebugLines();

	// si no tengo un destino
	if(HasPath == false)
	{
		ArrivedCurrentDestination = false;
		// busco el más cercano
		id_Path = PGame(WorldInfo.Game).ObtenerIdNodosMundo();
		pWNodos = PGame(WorldInfo.Game).ObtenerNodosMundo(id_Path);
		j = 0;
		distancia = VSize(pWNodos[0].Location - self.Location);
		for(i = 0; i < pWNodos.Length; ++i)
		{
			tmp = VSize(pWNodos[i].Location - self.Location);
			if(distancia > tmp)
			{
				distancia = tmp;
				j = i;
			}
		}

		// me lo asigno
		PGame(WorldInfo.Game).Broadcast(self, "El nodo mas cercano es el"@pWNodos[j].Name);
		DrawDebugSphere(pWNodos[j].Location, 500, 10, 0, 255, 0, false);
		HasPath = true;
		CurrentDestination = pWNodos[j].Location;
		Destination = pWNodos[j];
		PGame(WorldInfo.Game).DeleteWorldPathNode(id_Path, j);
	}

	if(VSize(OldLocation - Pawn.Location) > (Step/4))
	{
		nodo = spawn(class'PPathNode',,,Pawn.Location);
		nodo.id = id;
		PGame(WorldInfo.Game).AddPathNode(id, nodo, ColorDecal);
		
		OldLocation = Pawn.Location;
	}

	RandomTicksCounter++;

	if(FastTrace(theObjective.Location, self.Location,,true))
	{
		CurrentDestination = theObjective.Location;
		fTimer = 0.5;
	}
	else
	{
		fTimer = 1;
	}

	DrawDebugInfo();

	SetTimer(fTimer, false, 'BrainTimer');

	GotoState('MoveToDestination');

}

function Vector NextPath()
{
	local array<PWorldPathNode> pWNodos;
	local int i;
	local int j;
	local float distancia, tmp;

	ArrivedCurrentDestination = false;
	// busco el más cercano
	pWNodos = PGame(WorldInfo.Game).ObtenerNodosMundo(id_Path);
	
	j = 0;
	distancia = 100000;

	for(i = 0; i < pWNodos.Length; ++i)
	{
		tmp = VSize(pWNodos[i].Location - Pawn.Location);
		if(distancia > tmp && pWNodos[i].id == id_Path)
		{
			distancia = tmp;
			j = i;
		}
	}

	// me lo asigno
	PGame(WorldInfo.Game).Broadcast(self, "Voy hacia el nodo "@pWNodos[j].Name);
	DrawDebugSphere(pWNodos[j].Location, 500, 10, 0, 255, 0, true);
	Destination = pWNodos[j];
	PGame(WorldInfo.Game).DeleteWorldPathNode(id_Path, j);
	return pWNodos[j].Location;
}

state MoveToDestination
{
	event Tick(float DeltaTime)
	{
		local Pawn pDetectado;
		DrawDebugInfo();
		PEnemy(Pawn).ActualizaRotacion(DeltaTime);

		if(VSize(OldDecalLocation - Pawn.Location) > (PGame(WorldInfo.Game).fDecalSize))
		{
			OldDecalLocation = Pawn.Location;
			WorldInfo.MyDecalManager.SpawnDecal
			(
				Mat,
				Pawn.Location,
				rotator(-Pawn.Floor),
				PGame(WorldInfo.Game).fDecalSize, PGame(WorldInfo.Game).fDecalSize,
				PGame(WorldInfo.Game).fDecalSize,
				true,
				0,,,,,,,100000
			);
		}
		
		foreach Pawn.OverlappingActors(class'Pawn', pDetectado, 200,,true)
		{
			// Me aseguro que no me estoy detectando a mi mismo
			if(pDetectado != Pawn)
			{
				//DBG WorldInfo.Game.Broadcast(self, Name@"Ha chocado con"@pDetectado.Name);
				//DBG DrawDebugSphere(pDetectado.Location, 200, 10, 255, 0, 0, false);
				GotoState('MoveToDestination');
			}
		}
	}

Begin:

	if(VSize(theObjective.Location - Pawn.Location) < Step)
	{
		ClearTimer('BrainTimer');
		Pawn.Velocity = vect(0,0,0);
		GotoState('ArrivedDestination');
	}
	else if(VSize(theObjective.Location - Pawn.Location) < Step * 4)
	{
		Destination = theObjective;
	}
	else if(VSize(CurrentDestination - Pawn.Location) < DestinationOffset)
	{
		CurrentDestination = NextPath();
	}

	MoveToward(Destination,,DestinationOffset/2, false, true);
}

state ArrivedDestination
{
	event BeginState(name PreviousStateName)
	{
		PGame(WorldInfo.Game).PlayerBase.pupitabase();
		`log("vida de la base" @PGame(WorldInfo.Game).PlayerBase.life);
		//DBG WorldInfo.Game.Broadcast(self, Name@" ha llegado a destino");
		Pawn.Acceleration = vect(0,0,0);
		Pawn.Velocity = vect(0,0,0);
		StopLatentExecution();
		
		
	}

	
}

defaultproperties
{
	Step=1000
	RandomTicksCounter=0
	RandomTicksMax=2
	HasPath=false
	id_Path=0
	ArrivedCurrentDestination=false
	DestinationOffset=200;
}
