/**
 * Configuración general del juego
 * */

class PGame extends FrameworkGame;

var const float fDecalSize;
var bool bActivateDecalsOnWalk;
var int EnemiesLeft;
var bool bEarthNotFlying;
var int creditos;
var PPlayerBase PlayerBase;

struct Spawner
{
	var int id;
	var PEnemySpawner SpawnPoint;
};

struct GrupoNodos
{
	var int r, g, b;
	var int id;
	var array<PPathNode> Nodos;
};

//var array<GrupoNodos> Nodos;
var array<GrupoNodos> Nodos;
var array<Spawner> EnemySpawners;

var bool bSpawnBoss;
var Vector  m_CentroPlaneta;

simulated function PostBeginPlay()
{
    local PEnemySpawner ES;
	local PPlayerBase PB;

	local Spawner SP;


    foreach DynamicActors(class'PEnemySpawner', ES)
    {
		if(EnemySpawners.Find('id', ES.Group) == -1)
		{
			SP.SpawnPoint = ES;
			SP.id = ES.Group;
			EnemySpawners.AddItem(SP);
		}
    }

	`log("Hay"@EnemySpawners.Length);

	CreatePathNodes();

	foreach DynamicActors(class'PPlayerBase', PB)
		PlayerBase = PB;

	SetTimer(1.0, false, 'ActivateSpawners');
	super.PostBeginPlay();
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
			GP.r = Rand(255);
			GP.g = Rand(255);
			GP.b = Rand(255);

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
	DrawNodes();
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

			DrawDebugLine(v1, v2, GP.r, GP.g, GP.b, false);
			DrawDebugSphere(v1, 20, 10, GP.r, GP.g, GP.b, false);
		}
	}
}

function AddPathNode(int id, PPathNode pNodo)
{
	local int indice;
	local GrupoNodos GP;

	indice = Nodos.Find('id', id);
	if(indice == -1)
	{
		GP.Nodos.AddItem(pNodo);
		GP.id = pNodo.id;
		GP.r = Rand(255);
		GP.g = Rand(255);
		GP.b = Rand(255);

		Nodos.AddItem(GP);
		Broadcast(none, "Creando nuevo grupo de nodos...");
	}
	else
		Nodos[indice].Nodos.AddItem(pNodo);
}

function PPathNode GetNextPath(int id, out int NodeIndex)
{
	local int indice;

	indice = Nodos.Find('id', id);
	NodeIndex++;
	if(NodeIndex >= Nodos[indice].Nodos.Length)
		return none;
	else
		return Nodos[indice].Nodos[NodeIndex];
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
	fDecalSize=512.0f
	bActivateDecalsOnWalk=false
	creditos=1000000
	bEarthNotFlying=true
	bDelayedStart=false
	m_CentroPlaneta=(X=48.000000,Y=16.000000,Z=0.000000)
}
