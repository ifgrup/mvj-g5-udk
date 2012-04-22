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

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	theObjective = PGame(WorldInfo.Game).PlayerBase;
	RandomTicksMax = Rand(10) + 1;

	SetTimer(1, false, 'BrainTimer');
}

function SetID(int i)
{
	id = i;
}

function DrawDebugInfo()
{
	if(theObjective != none)
	{
		DrawDebugLine(Pawn.Location, CurrentDestination, 0, 255, 0, false);
		DrawDebugSphere(CurrentDestination, 20, 20, 0, 255, 0, false);
	}
}

function BrainTimer()
{
	local PPathNode nodo;
	local float fTimer;

	ClearTimer('BrainTimer');

	if(VSize(OldLocation - Pawn.Location) > Step)
	{
		nodo = spawn(class'PPathNode',,,Pawn.Location);
		nodo.id = id;
		PGame(WorldInfo.Game).AddPathNode(id, nodo);
		
		OldLocation = Pawn.Location;
	}

	RandomTicksCounter++;

	if(RandomTicksCounter < RandomTicksMax)
	{		
		CurrentDestination = RandomDest();
		fTimer = 1.0;
	}
	else
	{
		RandomTicksCounter = 0;

		CurrentDestination = theObjective.Location;
		fTimer = 3.0;
	}

	DrawDebugInfo();

	SetTimer(fTimer, false, 'BrainTimer');

	GotoState('MoveToDestination');

}

function Vector RandomDest()
{
	local vector R;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;
	local vector StartTrace, EndTrace;

	if(Rand(Step) < Step /2)
		OffsetX = Rand(Step)+Rand(Step);
	else
		OffsetX = Rand(Step)-Rand(Step);

	if(Rand(Step) < Step /2)
		OffsetY = Rand(Step)+Rand(Step);
	else
		OffsetY = Rand(Step)-Rand(Step);
	
	R.X = Pawn.Location.X + OffsetX;
	R.Y = Pawn.Location.Y + OffsetY;
	R.Z = Pawn.Location.Z;

	StartTrace = R;
	EndTrace = PGame(WorldInfo.Game).GetCentroPlaneta();

	Trace(HitLocation, HitNormal, EndTrace, StartTrace, TRUE,, HitInfo, TRACEFLAG_Bullet);

	return HitLocation;
}

state MoveToDestination
{
	event Tick(float DeltaTime)
	{
		local Pawn pDetectado;
		DrawDebugInfo();

		if(VSize(OldDecalLocation - Pawn.Location) > (PGame(WorldInfo.Game).fDecalSize / 2))
		{
			OldDecalLocation = Pawn.Location;
			WorldInfo.MyDecalManager.SpawnDecal
			(
				DecalMaterial'WP_BioRifle.Materials.Bio_Splat_Decal_001',
				Pawn.Location,
				rotator(-Pawn.Floor),
				PGame(WorldInfo.Game).fDecalSize * 2, PGame(WorldInfo.Game).fDecalSize * 2,
				PGame(WorldInfo.Game).fDecalSize * 4,
				true,
				FRand() * 360,,,,,,,100000
			);
		}

		foreach Pawn.OverlappingActors(class'Pawn', pDetectado, 200,,true)
		{
			// Me aseguro que no me estoy detectando a mi mismo
			if(pDetectado != Pawn)
			{
				WorldInfo.Game.Broadcast(self, Name@"Ha chocado con"@pDetectado.Name);
				DrawDebugSphere(pDetectado.Location, 200, 10, 255, 0, 0, false);
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
	
	MoveTo(CurrentDestination);
}

state ArrivedDestination
{
	event BeginState(name PreviousStateName)
	{
		WorldInfo.Game.Broadcast(self, Name@" ha llegado a destino");
		Pawn.Acceleration = vect(0,0,0);
		Pawn.Velocity = vect(0,0,0);
		StopLatentExecution();
	}
}

defaultproperties
{
	Step=200;
	RandomTicksCounter=0;
	RandomTicksMax=10;
}
