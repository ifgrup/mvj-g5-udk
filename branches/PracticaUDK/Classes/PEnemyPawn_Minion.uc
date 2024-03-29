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

var int minionId; //Para el tipo de Minion, Murci�galo,Topota, o Moco

var class<Actor> m_ClaseMisilKamikaze,m_ClaseMisilKamikazeto,m_ClaseMisilKamikazemo;
var EmitterSpawnable KamikazeEmitter;
var EmitterSpawnable m_part_muerte;
var EmitterSpawnable m_part_congelacion;

var ParticleSystem Kamikazepst,Kamikazetemtopota,Kamikazetemmoco;
var bool eresmoko;
function CambiaBicho()
{
	local bool bMaterialActivo;
	minionId = Rand(2);
	switch(minionId)
	{
		case 0: //Moco
			ColorMesh.SetSkeletalMesh(minionMesh0,true);
			ColorMesh.SetMaterial(0,minionMaterial0);
			ColorMesh.SetPhysicsAsset(minionPhysicsAsset0);
			ColorMesh.AnimSets=minionAnimSet0;
			ColorMesh.SetAnimTreeTemplate(minionAnimTree0);
			//translation.Z = 3;
			//ColorMesh.SetTranslation(translation);
			//kamikaze
			m_ClaseMisilKamikaze=m_ClaseMisilKamikazemo;
			
			Kamikazepst=Kamikazetemmoco;
			bMaterialActivo = true;
			eresmoko=true;

		break;
		case 1: //topota
			ColorMesh.SetSkeletalMesh(minionMesh1,true);
			//ColorMesh.SetMaterial(0,minionMaterial1);
			ColorMesh.SetPhysicsAsset(minionPhysicsAsset1);
			ColorMesh.AnimSets=minionAnimSet1;
			ColorMesh.SetAnimTreeTemplate(minionAnimTree1);
			//kamikaze
			m_ClaseMisilKamikaze=m_ClaseMisilKamikazeto;
			Kamikazepst=Kamikazetemtopota;
			bMaterialActivo = false;
		break;
	}

	if(bMaterialActivo)
	{
		mat = new class'MaterialInstanceConstant';
		mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
		mat.SetParent(Material'enemigos.TexturaMoco_Mat');
		mat.SetVectorParameterValue('ColorBase', Col1);
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
	local vector v_color;

	super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);

	CambiaBicho();

	//ColorMesh.SetMaterial(0, mat);

	//Preparamos las part�culas para el escudo hacia el scout
	ParticulasEscudo = Spawn(class'EmitterSpawnable',Self);
	ParticulasEscudo.SetTemplate(ParticleSystem'PGameParticles.Particles.FuerzaEscudo');
	ParticulasEscudo.ParticleSystemComponent.bAutoActivate = false;
	ParticulasEscudo.ParticleSystemComponent.SetActive(false);
	

	self.ColorMesh.AttachComponentToSocket(ParticulasEscudo.ParticleSystemComponent,'Socket_Cuerpo');

	//Preparamos las part�culas para el estado Kamikaze
	
	KamikazeEmitter = Spawn(class'EmitterSpawnable',Self);
	KamikazeEmitter.SetTemplate(Kamikazepst);
	KamikazeEmitter.ParticleSystemComponent.bAutoActivate = false;
	KamikazeEmitter.ParticleSystemComponent.SetActive(false);
	self.ColorMesh.AttachComponentToSocket(KamikazeEmitter.ParticleSystemComponent,'Socket_Cuerpo');


	//Toma colisiones g�enas...
	CylinderComponent.SetActorCollision(false, false); //Desactivamos cilindro de colisi�n
	ColorMesh.SetActorCollision(true, true,true);
	ColorMesh.SetTraceBlocking(true, true);
	ColorMesh.SetBlockRigidBody(true);
	ColorMesh.SetTraceBlocking(true,true);

	//Part�culas para muerte
	
	m_part_muerte = Spawn(class'EmitterSpawnable',Self);
	m_part_muerte.SetTemplate(ParticleSystem'PGameParticles.Particles.P_MuerteMinion');
	m_part_muerte.ParticleSystemComponent.bAutoActivate = false;
	m_part_muerte.ParticleSystemComponent.SetActive(false);
	
	v_color.x=Col1.R;//*2;
	v_color.y=Col1.G;//*2;
	v_color.z=Col1.B;//*2;
	m_part_muerte.ParticleSystemComponent.SetVectorParameter('ColorMuerte',v_color);
	self.ColorMesh.AttachComponentToSocket(m_part_muerte.ParticleSystemComponent,'Socket_Cuerpo');

	//Part�culas de congelaci�n:
	m_part_congelacion = Spawn(class'EmitterSpawnable',Self);
	m_part_congelacion.SetTemplate(ParticleSystem'PGameParticles.Particles.CristalesCuarzo');
	m_part_congelacion.ParticleSystemComponent.bAutoActivate = false;
	m_part_congelacion.ParticleSystemComponent.SetActive(false);
	ColorMesh.AttachComponentToSocket(m_part_congelacion.ParticleSystemComponent,'Socket_Cuerpo');
}

function SetColor(LinearColor Col)
{
	local vector colorpsmoko;
	
	Col1 = Col;
	colorpsmoko.X=col1.R/255;
	colorpsmoko.Y=col1.G/255;
	colorpsmoko.Z=col1.B/255;
	if(eresmoko)
	{
		mat.SetVectorParameterValue('ColorBase', Col1);
	}
}


function PararEsperar()
{
	local Vector retroceso;

    
	//Hacemos que la velocidad sea la opuesta al vector formado por PAwn.Location -> Other.Location	retroceso=Normal(self.Location-Other.Location);
	//Nos colocamos ligeramente alejados del colisionado, por intentar evitar que si ha entrado en la caja de colision,
	//el inicio del salto siga estando dentro de la caja y vuelva a ejecutarse el Bump
	retroceso=self.velocity*-1;
//	newLocation=self.Location+retroceso*5;
	//self.SetLocation(newLocation);

	self.Velocity=retroceso*100;//*Fclamp(Vsize(Velocity),3,5); 

	//_DEBUG `log("_______________PARAR_ESPERAR __________"@self.Name);	
	self.Salta(true);
}

function activarEscudoScout(vector posParticulas, float radio, float speedScout)
{
	self.GroundSpeed = speedScout;//Igualamos velocidad al scout
	//_DEBUG_DrawDebugCylinder(self.Location,scout.Location,10,10,0,0,200,false);
	ParticulasEscudo.ParticleSystemComponent.SetActive(true);
	ParticulasEscudo.SetFloatParameter('RangoAtraccion',radio);
	ParticulasEscudo.SetVectorParameter('Destino',posParticulas);
}

function desactivarEscudoScout()
{
	self.GroundSpeed = self.m_defaultGroundSpeed; //Restauramos velocidad
	ParticulasEscudo.ParticleSystemComponent.SetActive(false);
	//_DEBUG `log("Desactivo");
}

function Vector GetPosicionSocketCuerpo()
{
	local vector sLocation;
	local rotator sRotation;
	self.ColorMesh.GetSocketWorldLocationAndRotation('Socket_Cuerpo',sLocation,sRotation);
	return sLocation;

}

function Vector GetFireLocation()
{
	local vector FireLocation;
	local Rotator FireRotation;

	ColorMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
	return FireLocation;
}


function activarParticulasKamikaze(optional vector locaenemigo)
{
	KamikazeEmitter.ParticleSystemComponent.SetActive(true);
	KamikazeEmitter.ParticleSystemComponent.SetRotation(self.Rotation);
}

function ActivarPartCongelacion()
{
	m_part_congelacion.SetRotation(self.Rotation);
	m_part_congelacion.ParticleSystemComponent.SetActive(true);
	//m_part_congelacion.SetCollision(false,false,false);
	//m_part_congelacion.SetCollisionSize(100,100);
}

function DesactivarPartCongelacion()
{
	m_part_congelacion.ParticleSystemComponent.SetActive(false);
	m_part_congelacion.ParticleSystemComponent.KillParticlesForced();
	m_part_congelacion.ParticleSystemComponent.DeactivateSystem();

	//m_part_congelacion.SetCollision(false,false,false);
}

function Destruccion()
{
	//Sistema Part�culas de Muerte, y eliminarse del vector de enemigos de su spawner para control de m�ximo de minions
	m_part_muerte.ParticleSystemComponent.SetRotation(self.Rotation);
	m_part_muerte.ParticleSystemComponent.SetActive(false);
	m_part_muerte.ParticleSystemComponent.SetActive(true);
	//Si muere en este instante, las part�culas dejan de verse, as� que lanzamos un timer para que muera dentro de
	//un segundo, pero antes lo ponemos invisible para que parezca que ha desaparecido
	//self.SetDrawScale3D(vect(0,0,0));
	SetTimer(0.5,false,'MuerteVerdadera');
}
function DestruccionPorHielo()
{
	//No queremos la animaci�n de destrucci�n normal del penemy, la de las part�culas ya ha sido suficiente
	SetTimer(0.5,false,'MuerteVerdadera');
	MuerteVerdadera();

}

function MuerteVerdadera ()
{
	//m_part_muerte.ParticleSystemComponent.SetActive(false);
	//Notificamos a PGame que eliminie al minion del array de minions
	if(PGame(WorldInfo.Game) != none)
	{
	    PGame(WorldInfo.Game).EnemyKilled(self);
	}

	//m_part_muerte.ParticleSystemComponent.SetActive(false);
	self.Owner.Destroy();//muerte al opresor!!
	//self.UnPossessed(); //No tenemos Owner, LIBRES!!!
	self.Destroy(); //Qu� poco ha durado la libertad...
}

/***************** FUNCIONES DE RECEPCI�N DE DISPAROS PARA LOS MINIONS ******************************/

function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepci�n de disparo de Giru. Si no se redefine en las PEnemy hijas, ser� 
	//este. Si se quiere un tratamiento espec�fico, se redefine el hijo.
	//Y si quiere hacer algo m�s aparte de esto, pues que haga super.RecibidoDisparoGiru + lo que deba hacer

    life--;
	//_DEBUG_ ("Vida PEnemy" @life);
	if(life <= 0)
	{
		Destruccion();
	}
}


function RecibidoDisparoTurretCannon(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepci�n de disparo de TurretIce. Si no se redefine en las PEnemy hijas, ser� 
	//este. Si se quiere un tratamiento espec�fico, se redefine el hijo.
	//Y si quiere hacer algo m�s aparte de esto, pues que haga super.RecibidoDisparoTurretCannon + lo que deba hacer

    life-=3; //Cada disparo de torreta es un to�azo 3 veces m�s grande que el del Giru, por ejemplo
	//_DEBUG_ ("Vida PEnemy" @life);
	if(life <= 0)
	{
		Destruccion();		
	}
}

function RecibidoDisparoTurretIce(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepci�n de disparo de TurretIce. Si no se redefine en las PEnemy hijas, ser� 
	//este. Si se quiere un tratamiento espec�fico, se redefine el hijo.
	//Y si quiere hacer algo m�s aparte de esto, pues que haga super.RecibidoDisparoTurretIce + lo que deba hacer

    //No afecta a la vida, simplemente lo para (por ejemplo)..
	//As� que no hay que hacer nada m�s de momento
}




defaultproperties
{
	Begin Object Name=PEnemySkeletalMeshComponent
	//Begin Object Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Enemigos.Minion.Topota'
		PhysicsAsset=PhysicsAsset'Enemigos.Minion.Topota_Physics'
		AnimTreeTemplate=AnimTree'Enemigos.Minion.Topota_AnimTree'
		AnimSets(0)=AnimSet'Enemigos.Minion.Topota_Animset'

		
		Translation=(Z=-20.0)
	End Object

	Begin Object Name=CollisionCylinder
		CollisionRadius=+0015.000000
		CollisionHeight=+0028.000000
	End Object

	// Lo a�adimos al motor
	CylinderComponent=CollisionCylinder
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	minionMesh0=SkeletalMesh'enemigos.Slime'
	minionMaterial0=Material'enemigos.TexturaMoco_Mat'
	minionAnimTree0=AnimTree'enemigos.Slime_AnimTree'
	minionAnimSet0(0)=AnimSet'enemigos.Slime_Anims'
	minionPhysicsAsset0=PhysicsAsset'enemigos.Slime_Physics'
	minionPortrait0=Texture2D'PGameHudIco.Murciegalo_Portrait'
	Kamikazetemmoco=ParticleSystem'PGameMisilakos.mokokamikazeSP'
	m_ClaseMisilKamikazemo=class 'PMisiKamimoco'



	minionMesh1=SkeletalMesh'enemigos.Minion.Topota'
	minionMaterial1=Material'enemigos.Material_Enemigos'
	minionAnimTree1=AnimTree'enemigos.Minion.Topota_AnimTree'
	minionAnimSet1(0)=AnimSet'enemigos.Minion.Topota_Animset'
	minionPhysicsAsset1=PhysicsAsset'enemigos.Minion.Topota_Physics'
	minionPortrait1=Texture2D'PGameHudIco.Topota_Icono'
	Kamikazetemtopota=ParticleSystem'PGameMisilakos.topotakamikazeSP'
	m_ClaseMisilKamikazeto=class 'PMisiKamitopota'


	ColorMesh=PEnemySkeletalMeshComponent

	GroundSpeed=80.0
	m_defaultGroundSpeed=80
	m_puntos_al_morir = 100
	life=4
	eresmoko=false
}
