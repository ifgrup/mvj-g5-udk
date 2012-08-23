class PEnemyPawn_Minion extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;


simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Gelatinos.Walker.Gelatino_Walker_MASTER');
	mat.SetVectorParameterValue('ColorBase', Col1);
	mat.SetVectorParameterValue('DetailColor', Col2);

	ColorMesh.SetMaterial(0, mat);
	
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
}

function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	`log("Soy un Minion, y Giru me acaba de disparar el muy cabr�n" @self.Name @self.GetStateName());
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
		SkeletalMesh=SkeletalMesh'Gelatinos.Walker.GelatinoBipedoEsqueleto'
		PhysicsAsset=PhysicsAsset'Gelatinos.Walker.GelatinoBipedoEsqueleto_physics'
	
		Translation=(Z=-70.0)
		Scale=0.7
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


	ColorMesh=PEnemySkeletalMeshComponent


		

	GroundSpeed=50.0
	m_puntos_al_morir = 100
}
