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

var bool bSpawnBoss;

simulated function PostBeginPlay()
{
    local PEnemySpawner ES;

    //super.PostBeginPlay();
    GoalScore = 1;

    foreach DynamicActors(class'PEnemySpawner', ES)
        EnemySpawners[EnemySpawners.length] = ES;

    SetTimer(1.0, false, 'ActivateSpawners');
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

    if(bSpawnBoss)
        EnemySpawners[Rand(EnemySpawners.length)].SpawnBoss();
    else
    {
        EnemySpawners[Rand(EnemySpawners.length)].SpawnEnemy();
		// Con esto controlamos que sólo haya un spawn activo a la vez y que no spawneen todos los enemigos a la vez
        SetTimer(1.0 + FRand() * 3.0, false, 'ActivateSpawners');
    }
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
}
