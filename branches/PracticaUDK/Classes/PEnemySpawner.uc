class PEnemySpawner extends PActor
    placeable;

var PEnemy MySpawnedEnemy;

function SpawnEnemy()
{
    if(MySpawnedEnemy == none)
        MySpawnedEnemy = spawn(class'PEnemy_Minion', self,, Location);
}

function bool CanSpawnEnemy()
{
    return MySpawnedEnemy == none;
}

function MakeEnemyRunAway()
{
    if(MySpawnedEnemy != none)
        MySpawnedEnemy.RunAway();
}

function SpawnBoss()
{
    spawn(class'PEnemy_Boss', self,, Location);
}

defaultproperties
{
    Begin Object Class=SpriteComponent Name=Sprite
        Sprite=Texture2D'EditorResources.S_NavP'
        HiddenGame=False
    End Object
    Components.Add(Sprite)
}