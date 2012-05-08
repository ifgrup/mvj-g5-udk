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
var int NegX;
var int NegY;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	theObjective = PGame(WorldInfo.Game).PlayerBase;
	//RandomTicksMax = Rand(10) + 1;
	
	ColorDecal = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);

	Mat = new class'MaterialInstanceConstant';
	Mat.SetParent(MaterialInstanceConstant'Materiales.DecalSuelo2_INST');
	Mat.SetVectorParameterValue('Color', ColorDecal);
	/*Mat.SetScalarParameterValue('R', ColorDecal.R);
	Mat.SetScalarParameterValue('G', ColorDecal.G);
	Mat.SetScalarParameterValue('B', ColorDecal.B);*/

	if(Rand(10) <= 5)
		NegX = -1;
	else
		NegX = 1;

	if(Rand(10) >= 5)
		NegY = -1;
	else
		NegY = 1;

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
	FlushPersistentDebugLines();

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
		CurrentDestination = RandomDest();
		fTimer = 1;
	}

	DrawDebugInfo();

	SetTimer(fTimer, false, 'BrainTimer');

	GotoState('MoveToDestination');

}

function vector RandomPathDest()
{
	local PWorldPathNode pNodo;
	local float DistanceToBase;

	DistanceToBase = VSize(self.Location - theObjective.Location);
	foreach DynamicActors(class'PWorldPathNode', pNodo)
	{
		if(ListaNodosRecorridos.Find(pNodo) != -1)
			continue;

		if((pNodo.DistanceToBase < DistanceToBase))
		{
			if(VSize(pNodo.Location - Location) < 1000)
			{
				DrawDebugSphere(pNodo.Location, 300, 10, 255, 255,0, true);
				ListaNodosRecorridos.AddItem(pNodo);
				return pNodo.Location;
			}
		}
	}

	return RandomDest();
}

function bool CalcMoveToDestination()
{
	local Vector HitLocation, HitNormal;
	local Vector StartTrace, EndTrace;
	local Actor pBase;

	StartTrace = Pawn.Location;
	EndTrace = theObjective.Location;

	pBase = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true,,, TRACEFLAG_Bullet);

	return pBase.IsA('PPlayerBase');
}

function Vector RandomDest()
{
	local vector R;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;
	local vector StartTrace, EndTrace;
	local vector rr;

	rr = VRandCone(self.Location, DegToRad * 360);	

	OffsetX = Rand(Step)+Rand(Step);
	OffsetY = Rand(Step)+Rand(Step);
	
	R.X = Pawn.Location.X * rr.x + OffsetX * NegX;
	R.Y = Pawn.Location.Y * rr.Y + OffsetY * NegY;
	R.Z = Pawn.Location.Z;

	StartTrace = R;
	EndTrace = theObjective.Location;
		//PGame(WorldInfo.Game).GetCentroPlaneta();

	Trace(HitLocation, HitNormal, EndTrace, StartTrace, TRUE,, HitInfo, TRACEFLAG_Bullet);

	return HitLocation;
}

state MoveToDestination
{
	event Tick(float DeltaTime)
	{
		local Pawn pDetectado;
		local PWorldPathNode pNodo;
		DrawDebugInfo();

		if(VSize(OldDecalLocation - Pawn.Location) > (PGame(WorldInfo.Game).fDecalSize / 2))
		{
			OldDecalLocation = Pawn.Location;
			WorldInfo.MyDecalManager.SpawnDecal
			(
				Mat,
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
	Step=1000
	RandomTicksCounter=0
	RandomTicksMax=2
}
