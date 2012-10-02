class PEnemyPawn_Scout extends PEnemy;

var MaterialInstanceConstant mat;
var MaterialInstanceConstant matBandera;

var SkeletalMeshComponent ColorMesh;
var StaticMeshComponent Bandera;
var LinearColor Col1, Col2;

var int ira, max_ira;
var PShield escudo;
var EmitterSpawnable m_particulas_muerte; //Partículas de escudo hacia el Scout

simulated function PostBeginPlay()
{
	local int yes;
	local StaticMeshComponent lmesh;
	//super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Ogro.Materials.Ogro_Mat');
	mat.SetVectorParameterValue('BaseColor', Col1);
	mat.SetVectorParameterValue('EmissiveColor', Col2);
	
	// Bandera
	if(ColorMesh.GetSocketByName('Espalda') != none)
	{
		Bandera = new class'StaticMeshComponent';
		Bandera.SetStaticMesh(StaticMesh'Ogro.Bandera');
		ColorMesh.AttachComponentToSocket(Bandera, 'Espalda');

		matBandera = new class'MaterialInstanceConstant';
		matBandera = Bandera.CreateAndSetMaterialInstanceConstant(0);
		matBandera.SetParent(Material'Ogro.Bandera_Mat');
		matBandera.SetVectorParameterValue('BaseColor', Col1);
		Bandera.SetMaterial(0, matBandera);
	}

	// Barriga
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Barriga') != none)
		{
			lmesh = new class'StaticMeshComponent';
			lmesh.SetStaticMesh(StaticMesh'Ogro.ArmaduraBarriga');
			ColorMesh.AttachComponentToSocket(lmesh, 'Barriga');
		}
	}

	// Cuernos
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Cuernos') != none)
		{
			lmesh = new class'StaticMeshComponent';
			lmesh.SetStaticMesh(StaticMesh'Ogro.Cuernos');
			ColorMesh.AttachComponentToSocket(lmesh, 'Cuernos');
		}
	}

	// Mascara
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Mascara') != none)
		{
			lmesh = new class'StaticMeshComponent';
			yes = Rand(10);
			if(yes > 5)
			{
				lmesh.SetStaticMesh(StaticMesh'Ogro.Mascara001');
			}
			else
			{
				lmesh.SetStaticMesh(StaticMesh'Ogro.Mascara002');
			}
			ColorMesh.AttachComponentToSocket(lmesh, 'Mascara');
		}
	}

	// Hombrera Derecha
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('HombroDerecho') != none)
		{
			lmesh = new class'StaticMeshComponent';
			lmesh.SetStaticMesh(StaticMesh'Ogro.Hombrera_Derecha');
			ColorMesh.AttachComponentToSocket(lmesh, 'HombroDerecho');
		}
	}

	// Hombrera Izquierda
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('HombroIzquierdo') != none)
		{
			lmesh = new class'StaticMeshComponent';
			lmesh.SetStaticMesh(StaticMesh'Ogro.Hombrera_Izquierda');
			ColorMesh.AttachComponentToSocket(lmesh, 'HombroIzquierdo');
		}
	}

	// Mano Derecha
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('ManoDerecha') != none)
		{
			lmesh = new class'StaticMeshComponent';
			lmesh.SetStaticMesh(StaticMesh'Ogro.ManoDerecha');
			ColorMesh.AttachComponentToSocket(lmesh, 'ManoDerecha');
		}
	}

	// Cinturon
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Pelvis') != none)
		{
			lmesh = new class'StaticMeshComponent';
			lmesh.SetStaticMesh(StaticMesh'Ogro.Cinturon');
			ColorMesh.AttachComponentToSocket(lmesh, 'Pelvis');
		}
	}
	


	//Escudo
	if(ColorMesh.GetSocketByName('SocketEscudo') != none)
	{
		`log("encuentra socket escudo");
		escudo= Spawn(class 'PShield');
		self.ColorMesh.AttachComponentToSocket(escudo.Mesh,'SocketEscudo');
		escudo.ShieldMIC.SetVectorParameterValue('Color',col1);
		escudo.Mesh.SetScale(7);

	
	}

	//Toma colisiones güenas...
	CylinderComponent.SetActorCollision(false,false); //Desactivamos cilindro de colisión
	ColorMesh.SetActorCollision(true, true,true);
	ColorMesh.SetTraceBlocking(true, true);
	ColorMesh.SetBlockRigidBody(true);
	ColorMesh.SetActorCollision(true, true);

	//Partículas de muerte
	m_particulas_muerte = Spawn(class'EmitterSpawnable',Self);
	m_particulas_muerte.ParticleSystemComponent.bAutoActivate = false;
	m_particulas_muerte.ParticleSystemComponent.SetActive(false);
	m_particulas_muerte.SetTemplate(ParticleSystem'PGameParticles.Particles.P_MuerteOgro');
}



function Vector GetFireLocation()
{
	local vector FireLocation;
	local Rotator FireRotation;

	ColorMesh.GetSocketWorldLocationAndRotation('Mascara',FireLocation,FireRotation);
	return FireLocation;
}


function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
	matBandera.SetVectorParameterValue('ColorBase', Col1);
}

//Gestionamos la ira del Scout true para incrementar ira, flase para decrementarla
function GestionIra(bool mecabreo)
{
	//_DEBUG_ `log("--------------------------------ira"@self.ira);
	if(mecabreo)
	{    
		if(ira <= max_ira)
		{
			ira = ira + 1;
		}
	}
	else
	{
		if(ira > 0)
		{
			ira = ira - 1;
		}
	}
}

function int ValorIra()
{
	return self.ira;
}

function int NivelIra()
{
	//Devuelve el nivel de Ira en función de la ira actual respecto al máximo de ira
	local int pct;
	pct = (ira*100) / max_ira;

	if (pct < 30)
	{
		return 0;
	}

	if (pct < 50)
	{
		return 1;
	}

	if (pct < 98)
	{
		return 2;
	}

	return 3;
}

function ResetIra()
{
	//Rebajamos la nube poco a poco
	ira = 0.97*max_ira; //Así seguro que no vuelve a devolver ira máxima
	SetTimer(0.2,true,'BajaIra');
}

function BajaIra()
{
	ira = ira -5;
	if (ira<=0)
	{
		ClearTimer('BajaIra');
	}
}

event NuevoPaso()
{
	//EL ogro ha empezado otro paso. Ruido y sistema de partículas
	//_DEBUG_`log("Nuevo Paso Ogro!");
}

/***************** FUNCIONES DE RECEPCIÓN DE DISPAROS PARA LOS SCOUTS ******************************/
function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	local int lescudo;
	//Sólo afecta si no tiene escudo
	//El escudo lo gestiona el AI, le preguntamos cómo lo tiene
	if (self.Owner!=None)
	{
		lescudo = PEnemy_AI_Scout(Owner).m_escudo;
		if (lescudo > 0)
		{
			return;
		}
		else
		{
			self.life--;
			if (life <=0)
			{
				Destruccion();
			}
		}
	}

}
function RecibidoDisparoTurretCannon(vector HitLocation, vector Momentum,Actor DamageCauser)
{
    //Sólo afecta si no tiene escudo, o tiene muy poquito.
    //Molaría que este disparo también restara escudo, pero se complica al regenerarse con los minions..
	local int lescudo;
	
	if (self.Owner!=None)
	{
		lescudo = PEnemy_AI_Scout(Owner).m_escudo;
		if (lescudo >2 ) //Con poquito escudo ya le sirve
		{
			return;
		}
		else
		{
			self.life-=2;
			if (life <=0)
			{
				Destruccion();
			}
		}
	}


}
function RecibidoDisparoTurretIce(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//El Scout es un chicarrón del norte, el hielo se lo pasa por los sockets, así que no le afecta
	return;
}

function Destruccion()
{
	ActivarParticulasMuerte();
	self.escudo.mesh.SetHidden(true); //Ocultamos el escudo
	
	//self.escudo.Destroy();
	//escudo.Mesh.SetScale(7);

	SetTimer(0.7,false,'MuerteScout');
}

function ActivarParticulasMuerte()
{
	m_particulas_muerte.SetLocation(self.Location);
	m_particulas_muerte.SetRotation(self.Rotation);
	m_particulas_muerte.ParticleSystemComponent.ActivateSystem();
	m_particulas_muerte.ParticleSystemComponent.SetActive(false);
	m_particulas_muerte.ParticleSystemComponent.SetActive(true);
}

function MuerteScout()
{
	self.ColorMesh.SetHidden(true);
	
	if(PGame(WorldInfo.Game) != none)
	{
	    PGame(WorldInfo.Game).EnemyKilled(self);
	}
	self.Owner.Destroy();//muerte al opresor!!
	self.UnPossessed(); //No tenemos Owner, LIBRES!!!
	self.Destroy(); //Qué poco ha durado la libertad...
	
}


defaultproperties
{
	Begin Object Name=PEnemySkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Ogro.Ogre'
		PhysicsAsset=PhysicsAsset'Ogro.Ogre_Physics_V2'
		AnimTreeTemplate=AnimTree'Ogro.Ogro_AnimTree'
		AnimSets(0)=AnimSet'Ogro.Ogro_Anim'
		Translation=(Z=-90)
		Scale=3
	End Object

/******************
 * **************** PUEDE QUE NOS HAGA FALTA REACTIVARLO ...
 * Cómo me gustan las colisiones de UDK ....
 * 
 * 
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0092.000000
		CollisionHeight=+0120.000000
	End Object

	// Lo añadimos al motor
	CylinderComponent=CollisionCylinder
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
*****************************/

	ColorMesh=PEnemySkeletalMeshComponent

	GroundSpeed=50.0
	m_defaultGroundSpeed=GroundSpeed
	m_puntos_al_morir = 300
	ira=0;
	max_ira=50;
	life=3;
}
