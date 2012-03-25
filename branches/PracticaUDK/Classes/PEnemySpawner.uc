class PEnemySpawner extends PActor
    placeable;

var PEnemy MySpawnedEnemy;
var PEnemyBot AI;

function SpawnEnemy()
{
    if(MySpawnedEnemy == none)
    {
        MySpawnedEnemy = spawn(class'PEnemy_Minion',,, Location);
		AI = spawn(class'PEnemyBot',,,Location);
		AI.Possess(MySpawnedEnemy, false);
    }

}

function bool CanSpawnEnemy()
{
    return MySpawnedEnemy == none;
}

function SpawnBoss()
{
    MySpawnedEnemy = spawn(class'PEnemy_Boss', self,, Location);
	AI = spawn(class'PEnemyBot',,,Location);
	AI.Possess(MySpawnedEnemy, false);
}

defaultproperties
{
    Begin Object Class=SpriteComponent Name=Sprite
        Sprite=Texture2D'EditorResources.S_NavP'
        HiddenGame=False
    End Object
    Components.Add(Sprite)
}