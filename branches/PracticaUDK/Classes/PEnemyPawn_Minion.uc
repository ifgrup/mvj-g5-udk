class PEnemyPawn_Minion extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;


var SkeletalMesh minionMesh0, minionMesh1;
var Material minionMaterial0, minionMaterial1;
var AnimTree minionAnimTree0, minionAnimTree1;
var Array<AnimSet> minionAnimSet0, minionAnimSet1;
var PhysicsAsset minionPhysicsAsset0, minionPhysicsAsset1;

function CambiaBicho()
{
	local int i;
	local Vector translation;
	
	i = Rand(2);
	switch(i)
	{
		case 0:
			ColorMesh.SetSkeletalMesh(minionMesh0,true);
			//ColorMesh.SetMaterial(0,minionMaterial0);
			ColorMesh.SetPhysicsAsset(minionPhysicsAsset0);
			ColorMesh.AnimSets=minionAnimSet0;
			ColorMesh.SetAnimTreeTemplate(minionAnimTree0);
			translation.Z = 3;
			ColorMesh.SetTranslation(translation);
		break;
		case 1:
			ColorMesh.SetSkeletalMesh(minionMesh1,true);
			//ColorMesh.SetMaterial(0,minionMaterial1);
			ColorMesh.SetPhysicsAsset(minionPhysicsAsset1);
			ColorMesh.AnimSets=minionAnimSet1;
			ColorMesh.SetAnimTreeTemplate(minionAnimTree1);
		break;
	}
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
/*	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'enemigos.Material_Enemigos');
	mat.SetVectorParameterValue('ColorBase', Col1);
	mat.SetVectorParameterValue('DetailColor', Col2);
*/

	CambiaBicho();

	//ColorMesh.SetMaterial(0, mat);

	
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
}

function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	`log("Soy un Minion, y Giru me acaba de disparar el muy cabrón" @self.Name @self.GetStateName());
}
function RecibidoDisparoTurretCannon(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	`log("Soy un Minion, y una torreta cannon me acaba de disparar la muy guarra" @self.Name);
}

function PararEsperar()
{
	local Vector newLocation;
	local Vector retroceso;

    
	//Hacemos que la velocidad sea la opuesta al vector formado por PAwn.Location -> Other.Location	retroceso=Normal(self.Location-Other.Location);
	//Nos colocamos ligeramente alejados del colisionado, por intentar evitar que si ha entrado en la caja de colision,
	//el inicio del salto siga estando dentro de la caja y vuelva a ejecutarse el Bump
	retroceso=self.velocity*-1;
//	newLocation=self.Location+retroceso*5;
	//self.SetLocation(newLocation);

	self.Velocity=retroceso*100;//*Fclamp(Vsize(Velocity),3,5); 

	`log("_______________PARAR_ESPERAR __________"@self.Name);	
	self.Salta(true);
	

}


defaultproperties
{


	Begin Object Name=PEnemySkeletalMeshComponent
	//Begin Object Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Enemigos.Minion.Topota'
		PhysicsAsset=PhysicsAsset'Enemigos.Minion.Topota_Physics'
		AnimTreeTemplate=AnimTree'Enemigos.Minion.Topota_AnimTree'
		AnimSets(0)=AnimSet'Enemigos.Minion.Topota_Animset'
		Translation=(Z=-40.0)
		//Scale=3.7
		//demo
		/*****************
		SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		Scale=3
        **************************/
		//Translation=(Z=-1670.0)
		//demo
	End Object

	minionMesh0=SkeletalMesh'enemigos.Murciegalo'
	minionMaterial0=Material'enemigos.Material_Enemigos'
	minionAnimTree0=AnimTree'enemigos.Minion.Murciegalo_AnimTree'
	minionAnimSet0(0)=AnimSet'enemigos.Minion.Murciegalo_Animset'
	minionPhysicsAsset0=PhysicsAsset'enemigos.Minion.Murciegalo_Physics'

	minionMesh1=SkeletalMesh'enemigos.Minion.Topota'
	minionMaterial1=Material'enemigos.Material_Enemigos'
	minionAnimTree1=AnimTree'enemigos.Minion.Topota_AnimTree'
	minionAnimSet1(0)=AnimSet'enemigos.Minion.Topota_Animset'
	minionPhysicsAsset1=PhysicsAsset'enemigos.Minion.Topota_Physics'


	ColorMesh=PEnemySkeletalMeshComponent


		

	GroundSpeed=50.0
	m_puntos_al_morir = 100
}
