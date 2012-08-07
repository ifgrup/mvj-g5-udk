/**
 * Configuración general del juego
 * */

class PGame extends GameInfo;

var const float fDecalSize;
var bool bActivateDecalsOnWalk;
var int EnemiesLeft;
var bool bEarthNotFlying;
var int creditos;
var PPlayerBase PlayerBase;
var bool NodosCreados;
var int EScoutLeft;
struct Spawner
{
	var int id;
	var PEnemySpawner SpawnPoint;
};

struct GrupoNodos
{
	var LinearColor Col;
	var int id;
	var array<PPathNode> Nodos;
};

struct GrupoNodosMundo
{
	var int id;
	var array<PWorldPathNode> Nodos;
};

var array<GrupoNodos> Nodos;
var array<Spawner> EnemySpawners;
var array<GrupoNodosMundo> NodosMundo;

var bool bSpawnBoss;
var Vector  m_CentroPlaneta;

simulated function PostBeginPlay()
{
    local PEnemySpawner ES;
	local PPlayerBase PB;

	local Spawner SP;

	local InteractiveFoliageActor IFA;


    foreach DynamicActors(class'PEnemySpawner', ES)
    {
		if(EnemySpawners.Find('id', ES.Group) == -1)
		{
			SP.SpawnPoint = ES;
			SP.id = ES.Group;
			EnemySpawners.AddItem(SP);
			EScoutLeft++;
		}
    }

	`log("Hay"@EnemySpawners.Length);

	CreatePathNodes();

	foreach DynamicActors(class'PPlayerBase', PB)
		PlayerBase = PB;

	CreaNodosMundo();

	if(EnemySpawners.Length != 0)
		SetTimer(1.0, false, 'ActivateSpawners');

	super.PostBeginPlay();
}

function CreaNodosMundo()
{
	local PWorldPathNode pNodo;

	local Vector vInicial;
	local Rotator rRotacion;

	local Vector HitLocation,HitNormal;
	local int i,j;
	local int deltaAngulo;
	local int id;

	deltaAngulo = 15 * DegToUnrRot;
	vInicial = vect(0, 0, 15000);

	NodosMundo.Add(5);

	for (i = 0; i < 65535; i += deltaAngulo)
	{
		for (j = 0; j < 65535; j += deltaAngulo)
		{
			rRotacion.Yaw += deltaAngulo;
			vInicial = TransformVectorByRotation(rRotacion, vInicial);
			Trace(HitLocation, HitNormal, m_CentroPlaneta, m_CentroPlaneta + vInicial, true, vect(0, 0, 1));
			if(CanSpawnNode(HitLocation) == false)
				continue;
			//DrawDebugSphere(HitLocation,50,25,255,0,0,true);
			id = Rand(5);
			pNodo = Spawn(class'PWorldPathNode',,, HitLocation);
			//DrawDebugCylinder(m_CentroPlaneta, m_CentroPlaneta + vInicial, 25, 25, 0, 255, 0, true);

			pNodo.id = id;

			NodosMundo[pNodo.id].id = pNodo.id;
			NodosMundo[pNodo.id].Nodos.AddItem(pNodo);
		}

		rRotacion.Pitch += deltaAngulo;
		rRotacion.Yaw = 0;
	}

	NodosCreados = true;
}

function bool CanSpawnNode(Vector loc)
{
	local PNoSpawnVolume vol;
	foreach AllActors(class'PNoSpawnVolume', vol)
	{
		if(vol.ContainsPoint(loc))
			return false;
	}

	return true;
}

function array<PWorldPathNode> ObtenerNodosMundo(int id)
{
	return NodosMundo[id].Nodos;
}

/// Devuelve un id random de todos los posibles nodos
function int ObtenerIdNodosMundo()
{
	return Rand(NodosMundo.Length);
}

function DeleteWorldPathNode(int id, int i)
{
	NodosMundo[id].Nodos.Remove(i, 1);
}

function CreatePathNodes()
{
	local GrupoNodos GP;
	local PPathNode PN;
	local int i;
	foreach DynamicActors(class'PPathNode', PN)
	{
		i = Nodos.Find('id', PN.id);
		if(i == -1)
		{
			GP.Nodos.AddItem(PN);
			GP.id = PN.id;
			GP.Col = MakeLinearColor(Frand(), FRand(), FRand(), 1.0);

			Nodos.AddItem(GP);
		}
		else
		{
			Nodos[i].Nodos.AddItem(PN);
		}
	}
}

event Tick(float DeltaTime)
{
	local int i;
	local int j;
	local vector v0;
	local vector v1;

	//FlushPersistentDebugLines();
	if(NodosCreados)
		DrawWorldNodes();
	DrawNodes();

	for(i = 0; i < NodosMundo.Length; ++i)
	{
		for(j = 0; j < NodosMundo[i].Nodos.Length; ++j)
		{
			if(j+1 >= NodosMundo[i].Nodos.Length)
				v1 = NodosMundo[i].Nodos[0].Location;
			else
				v1 = NodosMundo[i].Nodos[j+1].Location;
	
			v0 = NodosMundo[i].Nodos[j].Location;
			DrawDebugLine(v0, v1, 255, 0, 0, false);
			//DrawDebugSphere(v0, 200, 10, 255, 0, 0, false);
		}
	}
}

function DrawWorldNodes()
{
	local int i, j;

	for(i = 0; i < NodosMundo.Length; i++)
	{
		//DBG DrawDebugSphere(NodosMundo[i].Location, 30, 10, 255, 0, 0, false);
	}
}

function DrawNodes()
{
	local int i, j;
	local GrupoNodos GP;
	local vector v1, v2;

	for(j = 0; j < Nodos.Length; j++)
	{
		GP = Nodos[j];
		for(i = 0; i < GP.Nodos.Length; i++)
		{
			v1 = GP.Nodos[i].Location;
			if(i >= GP.Nodos.Length-1)
				v2 = GP.Nodos[i].Location;
			else
				v2 = GP.Nodos[i+1].Location;

			//DBG DrawDebugLine(v1, v2, GP.Col.R * 255, GP.Col.G * 255, GP.Col.B * 255, false);
			//DBG DrawDebugSphere(v1, 20, 10, GP.Col.R * 255, GP.Col.G * 255, GP.Col.B * 255, false);
		}
	}
}

function AddPathNode(int id, PPathNode pNodo, optional LinearColor col)
{
	local int indice;
	local GrupoNodos GP;

	indice = Nodos.Find('id', id);
	if(indice == -1)
	{
		GP.Nodos.AddItem(pNodo);
		GP.id = pNodo.id;
		GP.Col = col;

		Nodos.AddItem(GP);
		Broadcast(none, "Creando nuevo grupo de nodos...");
	}
	else
		Nodos[indice].Nodos.AddItem(pNodo);
}

function PPathNode GetNextPath(int id, out int NodeIndex)
{
	local int indice;
	local int NodeIndexTmp;
	NodeIndexTmp = NodeIndex +1;

	indice = Nodos.Find('id', id);
	//NodeIndex++;
	if(NodeIndexTmp >= Nodos[indice].Nodos.Length)
	{
		return none;
	}
	else
	{
		NodeIndex ++;
		return Nodos[indice].Nodos[NodeIndex];
	}
}

function ActivateSpawners()
{
    local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
        break;

    if(PC.Pawn == none)
    {
        SetTimer(1.0, false, 'ActivateSpawners');
        return;
    }
    
    EnemySpawners[Rand(EnemySpawners.length)].SpawnPoint.SpawnEnemy();
	// Con esto controlamos que sólo haya un spawn activo a la vez y que no spawneen todos los enemigos a la vez
    SetTimer(3, false, 'ActivateSpawners');
}

function SetCredito(int credito)
{
	creditos=credito;
}


function EnemyKilled()
{
    EnemiesLeft--;
    if(EnemiesLeft <= 0)
    {
        ClearTimer('ActivateSpawners');
        bSpawnBoss = true;
        ActivateSpawners();
    }
}

function ScoutKilled()
{

	EScoutLeft--;
	if(EScoutLeft <= 0)
	{
		MapaFinalizado();
	}
}



//control de Game Over
function BaseDestrozada()
{
`log("Base destrozada");

    consolecommand("Open PGameMenuini");


}


function GameOver()
{

consolecommand("Open PGameMenuini");


}


function MapaFinalizado()
{


}


function ScoreObjective(PlayerReplicationInfo Scorer, Int Score)
{
    super.ScoreObjective(Scorer, Score);
}

function Vector GetCentroPlaneta()
{
	return m_CentroPlaneta;
}

defaultproperties
{
	PlayerControllerClass=class'PGame.PPlayerController'
	DefaultPawnClass=class'PGame.PPawn'
	HUDType=class'PGame.PHUD'
    	EnemiesLeft=10
    	bScoreDeaths=false
	fDecalSize=256.0f
	bActivateDecalsOnWalk=false
	creditos=1000000
	bEarthNotFlying=true
	bDelayedStart=false
	//m_CentroPlaneta=(X=528,Y=144,Z=8752)
	m_CentroPlaneta=(X=0.000000,Y=0.000000,Z=0.000000)
	NodosCreados=false
}
