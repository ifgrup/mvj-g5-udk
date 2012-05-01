class PEnemySpawner extends PActor
    placeable;

var(SpawnConfig) int Group;
var PEnemy EnemyScout;
var PEnemy_AI_Scout AI;

var array<PEnemy> Enemy;
var array<PEnemy_AI_Bot> AIBot;

var(SpawnConfig) int MaxEnemies;

function PostBeginPlay()
{
	// Si no tenemos grupo, generamos uno
	if(Group == 0)
		Group = Rand(255);
}

/**
 * Genera enemigos. El primero de todos siempre es el Scout, que se encarga de ir generando el camino
 * */
function SpawnEnemy()
{
	local PEnemy EN;
	local Penemy_AI_Bot AIB;

    if(EnemyScout == none)
    {
        EnemyScout = spawn(class'PEnemyPawn_Scout',,,Location);
		AI = spawn(class'PEnemy_AI_Scout',,,Location);
		AI.SetID(Group);
		AI.Possess(EnemyScout, false);
    }
	else
	{
		if(CanSpawnEnemy())
		{
			EN = spawn(class'PEnemyPawn_Minion',,, Location);
			AIB = spawn(class'PEnemy_AI_Bot',,, Location);
			AIB.SetID(Group);
			Enemy.AddItem(EN);
			AIBot.AddItem(AIB);
			AIB.Possess(EN, false);
		}
	}
}

function bool CanSpawnEnemy()
{
    return Enemy.Length != MaxEnemies;
}

defaultproperties
{
    Begin Object Class=SpriteComponent Name=Sprite
        Sprite=Texture2D'EditorResources.S_NavP'
        HiddenGame=False
    End Object
    Components.Add(Sprite)
	MaxEnemies=1;
}