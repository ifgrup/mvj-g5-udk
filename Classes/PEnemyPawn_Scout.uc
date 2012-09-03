class PEnemyPawn_Scout extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;

var float ira,max_ira;

simulated function PostBeginPlay()
{
	//super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Ogro.Materials.Ogro_Mat');
	mat.SetVectorParameterValue('BaseColor', Col1);
	mat.SetVectorParameterValue('EmissiveColor', Col2);

	ColorMesh.SetMaterial(0, mat);
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
}

//Gestionamos la ira del Scout true para incrementar ira, flase para decrementarla
function GestionIra(bool mecabreo)
{
	`log("--------------------------------ira"@self.ira);

		if(mecabreo)
		{    

			if(ira<=max_ira) ira=ira+1;
			
		}
		else
		{
			if(ira>0)ira=ira-1;
		}
	

}

defaultproperties
{
	Begin Object Name=PEnemySkeletalMeshComponent
		//SkeletalMesh=SkeletalMesh'Gelatinos.Gusano.GelatinoGusano01'
		SkeletalMesh=SkeletalMesh'Ogro.Ogre'
		PhysicsAsset=PhysicsAsset'Ogro.Ogre_Physics_V2'
		AnimTreeTemplate=AnimTree'Ogro.Ogro_AnimTree'
		AnimSets(0)=AnimSet'Ogro.Ogro_Anim'


		Translation=(Z=-50.0)
		Scale=3
	End Object

	ColorMesh=PEnemySkeletalMeshComponent

	GroundSpeed=25.0
	m_defaultGroundSpeed=GroundSpeed
	m_puntos_al_morir = 300
	ira=0;
	max_ira=100;
}
