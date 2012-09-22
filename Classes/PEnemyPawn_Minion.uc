class PEnemyPawn_Minion extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;


var SkeletalMesh minionMesh0, minionMesh1;
var Material minionMaterial0, minionMaterial1;
var AnimTree minionAnimTree0, minionAnimTree1;
var Array<AnimSet> minionAnimSet0, minionAnimSet1;
var PhysicsAsset minionPhysicsAsset0, minionPhysicsAsset1;
var Texture2D minionPortrait0, minionPortrait1;

var EmitterSpawnable ParticulasEscudo; //Part�culas de escudo hacia el Scout

var int minionId;

function CambiaBicho()
{
	local Vector translation;
	minionId = Rand(2);
	switch(minionId)
	{
		case 0: //Murci�galo
			ColorMesh.SetSkeletalMesh(minionMesh0,true);
			//ColorMesh.SetMaterial(0,minionMaterial0);
			ColorMesh.SetPhysicsAsset(minionPhysicsAsset0);
			//ColorMesh.AnimSets=minionAnimSet0;
			//ColorMesh.SetAnimTreeTemplate(minionAnimTree0);
			translation.Z = 3;
			ColorMesh.SetTranslation(translation);
		break;
		case 1: //topota
			ColorMesh.SetSkeletalMesh(minionMesh1,true);
			//ColorMesh.SetMaterial(0,minionMaterial1);
			ColorMesh.SetPhysicsAsset(minionPhysicsAsset1);
			ColorMesh.AnimSets=minionAnimSet1;
			ColorMesh.SetAnimTreeTemplate(minionAnimTree1);
		break;
	}
}

function Texture2D GetPortrait()
{
	local Texture2D portrait;
	switch(minionId)
	{
		case 0:
			portrait = minionPortrait0;
		break;
		case 1:
			portrait = minionPortrait1;
		break;
	}

	return portrait;
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

	//Preparamos las part�culas para el escudo hacia el scout
	ParticulasEscudo = Spawn(class'EmitterSpawnable',Self);
	ParticulasEscudo.SetTemplate(ParticleSystem'PGameParticles.Particles.FuerzaEscudo');
	ParticulasEscudo.ParticleSystemComponent.bAutoActivate = false;
	ParticulasEscudo.ParticleSystemComponent.SetActive(false);
	

	self.ColorMesh.AttachComponentToSocket(ParticulasEscudo.ParticleSystemComponent,'Socket_Cuerpo');


	
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	//mat.SetVectorParameterValue('ColorBase', Col1);
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

function activarEscudoScout(PEnemyPawn_Scout scout, float radio)
{
	self.GroundSpeed = scout.GroundSpeed; //Igualamos velocidad al scout
	//_DEBUG_DrawDebugCylinder(self.Location,scout.Location,10,10,0,0,200,false);
	ParticulasEscudo.ParticleSystemComponent.SetActive(true);
	ParticulasEscudo.SetFloatParameter('RangoAtraccion',radio);
	ParticulasEscudo.SetVectorParameter('Destino',scout.GetPosicionCuerno());
}

function desactivarEscudoScout()
{
	self.GroundSpeed = self.m_defaultGroundSpeed; //Restauramos velocidad
	ParticulasEscudo.ParticleSystemComponent.SetActive(false);
	`log("Desactivo");
}

event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
{

	PEnemy_AI_Controller(Owner).HitWall(HitNormal,Wall,WallComp);

}

function Vector GetPosicionSocketCuerpo()
{
	local vector sLocation;
	local rotator sRotation;
	self.ColorMesh.GetSocketWorldLocationAndRotation('Socket_Cuerpo',sLocation,sRotation);
	return sLocation;

}

defaultproperties
{


	Begin Object Name=PEnemySkeletalMeshComponent
	//Begin Object Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Enemigos.Minion.Topota'
		PhysicsAsset=PhysicsAsset'Enemigos.Minion.Topota_Physics'
		AnimTreeTemplate=AnimTree'Enemigos.Minion.Topota_AnimTree'
		AnimSets(0)=AnimSet'Enemigos.Minion.Topota_Animset'

		Translation=(Z=-90.0)
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

	minionMesh0=SkeletalMesh'enemigos.Minion.Murciegalo'
	minionMaterial0=Material'enemigos.Material_Enemigos'
	//minionAnimTree0=AnimTree'enemigos.Minion.Murciegalo_AnimTree'
	//minionAnimSet0(0)=AnimSet'enemigos.Minion.Murciegalo_Animset'
	minionPhysicsAsset0=PhysicsAsset'enemigos.Minion.Murciegalo_Physics'
	minionPortrait0=Texture2D'PGameHudIco.Murciegalo_Portrait'


	minionMesh1=SkeletalMesh'enemigos.Minion.Topota'
	minionMaterial1=Material'enemigos.Material_Enemigos'
	minionAnimTree1=AnimTree'enemigos.Minion.Topota_AnimTree'
	minionAnimSet1(0)=AnimSet'enemigos.Minion.Topota_Animset'
	minionPhysicsAsset1=PhysicsAsset'enemigos.Minion.Topota_Physics'
	minionPortrait1=Texture2D'PGameHudIco.Topota_Icono'


	ColorMesh=PEnemySkeletalMeshComponent


		

	GroundSpeed=80.0
	m_defaultGroundSpeed=GroundSpeed
	m_puntos_al_morir = 100
}
