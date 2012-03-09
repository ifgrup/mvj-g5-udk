/**
 * Configuración general del juego
 * */

class PGame extends FrameworkGame;

var const float fDecalSize;
var bool bActivateDecalsOnWalk;
var int EnemiesLeft;
var bool bEarthNotFlying;
var int creditos;
var array<PEnemySpawner> EnemySpawners;

var float MinSpawnerDistance, MaxSpawnerDistance;

var bool bSpawnBoss;

simulated function PostBeginPlay()
{
    local PEnemySpawner ES;

    //super.PostBeginPlay();
	WorldInfo.Game.Broadcast(self, "derp");
	`log("derp");
    GoalScore = 1;

    foreach DynamicActors(class'PEnemySpawner', ES)
        EnemySpawners[EnemySpawners.length] = ES;

    SetTimer(5.0, false, 'ActivateSpawners');
}

function ActivateSpawners()
{
    local int i;
    local array<PEnemySpawner> InRangeSpawners;
    local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
        break;

    if(PC.Pawn == none)
    {
        SetTimer(1.0, false, 'ActivateSpawners');
        return;
    }

    for(i=0; i<EnemySpawners.length; i++)
    {
        if(VSize(PC.Pawn.Location - EnemySpawners[i].Location) > MinSpawnerDistance && VSize(PC.Pawn.Location - EnemySpawners[i].Location) < MaxSpawnerDistance)
        {
            if(EnemySpawners[i].CanSpawnEnemy())
                InRangeSpawners[InRangeSpawners.length] = EnemySpawners[i];
        }
    }

    if(InRangeSpawners.length == 0)
    {
        SetTimer(1.0, false, 'ActivateSpawners');
        return;
    }

    if(bSpawnBoss)
        InRangeSpawners[Rand(InRangeSpawners.length)].SpawnBoss();
    else
    {
        InRangeSpawners[Rand(InRangeSpawners.length)].SpawnEnemy();
        SetTimer(1.0 + FRand() * 3.0, false, 'ActivateSpawners');
    }
}

function SetCredito(int credito)
{
creditos=credito;
}


function EnemyKilled()
{
    local int i;

    EnemiesLeft--;
    if(EnemiesLeft <= 0)
    {
        for(i=0; i<EnemySpawners.length; i++)
            EnemySpawners[i].MakeEnemyRunAway();
        ClearTimer('ActivateSpawners');
        bSpawnBoss = true;
        ActivateSpawners();
    }
}

function ScoreObjective(PlayerReplicationInfo Scorer, Int Score)
{
    super.ScoreObjective(Scorer, Score);
}


defaultproperties
{
	PlayerControllerClass=class'PGame.PPlayerController'
	DefaultPawnClass=class'PGame.PPawn'
	HUDType=class'PGame.PHUD'
    	MinSpawnerDistance=0.0
    	MaxSpawnerDistance=3000.0
    	EnemiesLeft=10
    	bScoreDeaths=false
	fDecalSize=512.0f
	bActivateDecalsOnWalk=false
	creditos=1000000
	bEarthNotFlying=true
	bDelayedStart=false
}
