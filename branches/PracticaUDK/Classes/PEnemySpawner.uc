class PEnemySpawner extends PActor
    placeable;

var MaterialInstanceConstant mat;
var StaticMeshComponent ColorMesh;
var LinearColor Col1;
var LinearColor Col2;

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

	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Props.Huevos.Huevo01_Mat');
	mat.SetVectorParameterValue('Color_Emissive01', Col1);
	mat.SetVectorParameterValue('Color_Emissive02', Col2);

	ColorMesh.SetMaterial(0, mat);
}

/**
 * Genera enemigos. El primero de todos siempre es el Scout, que se encarga de ir generando el camino
 * */
function SpawnEnemy()
{
	local PEnemy EN;
	local Penemy_AI_Bot AIB;
	local vector posspawn;
	local int i;

    if(EnemyScout == none)
    {
        EnemyScout = spawn(class'PEnemyPawn_Scout',,,Location);
		if (EnemyScout == none)
		{
			//_DEBUG_ ("No se ha podido crear el scout");
			return;
		}
        EnemyScout.SetColor(Col2);

		AI = spawn(class'PEnemy_AI_Scout',,,Location);
		AI.SetColor(Col2);
		AI.SetID(Group);
		AI.Possess(EnemyScout, false);
    }
	else
	{
		if(CanSpawnEnemy())
		{
			for (i=0;i<3;i++)
			{
				posspawn= generarPosicionSpawn(Location);
				EN = spawn(class'PEnemyPawn_Minion',,, posspawn);
				if (EN!=None) //Proteccion Víctor
				{
					EN.SetColor(Col2);
					AIB = spawn(class'PEnemy_AI_Bot',,, posspawn);
					AIB.SetID(Group);
					Enemy.AddItem(EN);
					AIBot.AddItem(AIB);
					AIB.Possess(EN, false);
				}
			}
		}
	}
}

function vector generarPosicionSpawn(vector poshuevo)
{
	local vector valcentro;
	local vector parriba;
	local vector vrandom;

	valcentro=PGame(Worldinfo.Game).GetCentroPlaneta()-poshuevo;
	parriba = poshuevo-  200*normal(valcentro);
	vrandom = vrand()* 200;
	return parriba + vrandom;
}

function bool CanSpawnEnemy()
{
    return Enemy.Length <= MaxEnemies;
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object

    LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)
	
	Begin Object class=StaticMeshComponent Name=BaseMesh
		StaticMesh=StaticMesh'Props.Huevos.Huevo01'
		LightEnvironment=MyLightEnvironment
		Scale=2
    End Object

	ColorMesh=BaseMesh
	Components.Add(BaseMesh)

	MaxEnemies=12;
}