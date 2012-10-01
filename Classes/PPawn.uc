
/** En UDK un Pawn es cualquier objeto que:
 * - Pueda controlar el jugador
 * - Pueda controlar la IA
 * - Pueda controlar mediante scripts
 * 
 * Por ejemplo: Un Pawn podría ser el personaje jugador, un enemigo, un compañero controlado por la IA 
 * o un amigo que juegue con nosotros en modo multijugador.
 * No se considera Pawn cosas como misiles, disparos, items, etc.
 */

// Siempre debemos derivar nuestra clase Pawn de GamePawn
class PPawn extends GamePawn;
// 

// Para que a nuestro Pawn le afecte la iluminación
var DynamicLightEnvironmentComponent LightEnvironment;
var vector FallDirection;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un límite, para evitar que se pire volando, lo bajamos
var vector m_TranslateZ;
var bool m_VenimosDeBump;
var vector m_ULtimoFloorAntesSalto; //Por si en el salto el floor se ha perdido al saltar, chocar, etc
var int m_DistanciaAlSuelo; //Distancia del robot al suelo
var int m_backupDistanciaAlSuelo; //para guardar el valor de m_DistanciaAlSuelo cuando se modifica


//Los sistemas de partículas del robot, para poder encenderlos y apagarlos todos juntos:
var array<EmitterSpawnable>	m_ParticulasPropulsoresRobot;
var vector m_NormalAlCaerSuelo;
var bool m_RecienEstrellado;
var bool m_permiteMoverSaltando;

//Guardamos valores del translateZ para hacer la media y que el translate sea más suave
var array<float> m_array_translatez;

var float m_tiempoEstado;

//Indices del vector de partículas de m_ParticulasPropulsoresRobot
var int m_idx_brazo_ido,m_idx_brazo_dcho,m_idx_antebrazo_ido,m_idx_antebrazo_dcho,m_idx_base;

var int m_roll_antes_caer_cielo; //Roll que teníamos antes de caer del cielo para mantener la orientación
var bool m_bEstoyCayendoDelCielo; //Para saber si debemos utilizar m_roll_antes_caer_cielo o no

var float life;

var EmitterSpawnable m_particulas_tonyazo; //Al caer al suelo desde el cielo

var vector m_pos_deseada_nube; //Para ir moviendo el sistema de partículas
var bool m_rayazo_recibido; //Si el Giru acaba de recibir un rayaco
var PNubeIra  m_nubeIra;

function float CalcularMediaTranslateZ(float valorZ)
{
	local int i;
	local float z;
	local int tam;
	tam=20;

	//añadimos al array, y calculamos la media
	m_array_translatez.AddItem(valorZ);
	if (m_array_translatez.Length > tam)
	{
		m_array_translatez.Remove(0,1);
	}
	z=0;
	for (i=0;i<m_array_translatez.Length;i++)
	{
		z+=m_array_translatez[i]/m_array_translatez.Length;
	}
	////_DEBUG_ ("Filtro vale "@z @m_array_translatez.Length @valorZ);
	return z;
}

event Tick(float DeltaTime)
{
    local vector vlocation,vnormal;
	local vector vZ;
	local vector rx,ry,rz;
	local vector posActual;
	local float valorZ;
	local vector posNubeActual;
	local vector desp;
	local rotator rot;
	local quat qact,qgiro;
	local float dist,v;

	super.Tick(DeltaTime);

	//COntrol de posición de la nube de ira
	if (m_nubeIra.EstaActiva())
	{
		ActualizaPosicionDeseadaNube();
		posNubeActual = m_nubeIra.Location;
		dist = vsize(m_pos_deseada_nube - posNubeActual);
		//Cuanto más lejos, más rápido queremos que se acerque
		v = dist *3 ;
		if (dist > 10) //para evitar flickering
		{
			posNubeActual = m_nubeIra.Location;
			desp = v*DeltaTime*Normal(m_pos_deseada_nube - posNubeActual);
			m_nubeIra.posicionar(posNubeActual+desp,self.Rotation);
		}
	}

	//Si estoy recien estoñao por un rayo, giru el pawn:
	if (m_rayazo_recibido)
	{
		//Puedo cambiar la rotación aquí porque en el controller, si m_rayazo_recibido, no actualiza la rotación ;)
		GetAxes(self.Rotation,rx,ry,rz);
		qact = QuatFromRotator(self.Rotation);
		
		//qgiro = QuatFromAxisAndAngle(ry,25*DegToRad); 
		//qact = QuatProduct(qgiro,qact);
	
		qgiro = QuatFromAxisAndAngle(rz,600*DeltaTime*DegToRad); 
		qact = QuatProduct(qgiro,qact);
		

		rot = QuatToRotator(qact);
		self.SetRotation(rot);
	}

	//if (self.IsInState('PawnFalling') || self.IsInState('PawnFallingSky') || self.IsInState('PawnFlaying'))

	if (!self.IsInState('PPawn') && !self.IsInState('PawnPreparandoFlaying'))
	{
		//No hacemos nada si no está caminando
		return;
	}
		
	//Actualizamos el Floor, que nos hará falta para el salto, sobretodo después de chocar contra algo
	if (m_ULtimoFloorAntesSalto!=self.Floor)
	{
		self.m_ULtimoFloorAntesSalto=self.Floor;
		////_DEBUG_ ("FT "@self.m_ULtimoFloorAntesSalto);
	};

	//Calculamos la distancia del bicho al suelo
	GetAxes(Rotation,rx,ry,rz);
	posActual = self.Location; 

	trace(vlocation,vnormal,posActual - rz*200,posActual,true,vect(1,1,1));
	//FlushPersistentDebugLines();
	//DrawDebugCylinder(self.Location,self.Location-Floor*300,5,5,0,10,10,true);
	//DrawDebugCylinder(self.Location,self.Location-rz*200,5,15,0,0,255,true);
	//DrawDebugCylinder(posActual,vlocation,5,15,0,0,255,true);
	//if (vlocation == vect(0,0,0))
		//_DEBUG_ ("Trace nulo");
	
	//DrawDebugSphere(posActual,5,50,200,0,0,true);
	//DrawDebugSphere(vlocation,5,50,200,200,0,true);
	

	vZ.X=0;
	vZ.Y=0;
	valorZ = vsize( Normal(vlocation - posActual) * (vsize(vlocation-posActual)-m_DistanciaAlSuelo));
	vz.Z = CalcularMediaTranslateZ(valorZ);
	if (vz.Z > vsize(vlocation-posActual))
	{
		//_DEBUG_ ("Bajo tierra");
		//Lo corregimos, fijando la distancia al suelo
		vz.Z=vsize(vlocation-posActual)-m_DistanciaAlSuelo;
	}

	mesh.SetTranslation(-vz);
	m_TranslateZ = -vz;
	//DrawDebugSphere(posActual,5,50,200,0,0,true);

}


function ReboteRespectoA(Actor Other, float aceleracion_caida = JumpZ)
{
	local Vector newLocation;
	local Vector retroceso;
	local float jump_z_temp;


	m_VenimosDeBump=true; //Para control del salto

	//Hacemos que la velocidad sea la opuesta al vector formado por PAwn.Location -> Other.Location	retroceso=Normal(self.Location-Other.Location);
	//Nos colocamos ligeramente alejados del colisionado, por intentar evitar que si ha entrado en la caja de colision,
	//el inicio del salto siga estando dentro de la caja y vuelva a ejecutarse el Bump
	retroceso=Normal(self.Location-Other.Location);
	newLocation=self.Location+retroceso*2;
	self.SetLocation(newLocation);


	//Si estoy saltando y choco,hago salto en dirección contraria, de forma análoga que si estoy caminando
	//Por tanto, no hay que hacer distinción, si bumpea por salto o por andar tiene que hacer exactamente lo mismo.

	self.Velocity=retroceso*Fclamp(Vsize(Velocity),100,500); 
	
	
    //Guardamos el jumpz anterior para luego restaurarlo.
	jump_z_temp = self.JumpZ;
	self.JumpZ = aceleracion_caida;

   //just in case, podríamos poner  como floor de salto contra torreta el de la normal de la torreta
   //por si el impacto es en un montículo de terreno con inclinación muy diferente a dicha normal,
   //evitar un raro efecto
   //De momento, lo comento, ya veremos si es necesario
    /*
	if (PAutoTurret(Other) != None)
	{
		m_ULtimoFloorAntesSalto = PAutoTurret(Other).m_NormalSuelo;
	}
    */
	self.DoJump(true);
	self.JumpZ = jump_z_temp; //restauramos jupz
	
	m_VenimosDeBump=false;
}


/*
 * Intento de hacer que al caer el Pawn rebota a saco. Pero no lo consigo porque enseguida que empieza
 * se produce el evento Bump normal con su velocidad, así que no sirve de mucho.
 * Pero hay que implementarlo por si NO se ejecuta el Bump normal luego.
 */
function ReboteGrandeBumpCayendo(Actor Other, Vector BumpLocation, Vector BumpNormal,float aceleracion_caida = JumpZ)
{
	local float jump_z_temp;

	m_VenimosDeBump=true; //Para control del salto

	
	self.Velocity = (BumpNormal Cross normal(-self.Velocity)) *500;//rebote a tomar por culo
	
	//_DEBUG_DrawDebugCylinder(self.Location,self.Location+self.Velocity,3,5,100,255,50,true);
    //Guardamos el jumpz anterior para luego restaurarlo.
	jump_z_temp = self.JumpZ;
	self.JumpZ = 2000;
	self.DoJump(true);
	self.JumpZ = jump_z_temp; //restauramos jupz
	
	m_VenimosDeBump=false;
}


singular event Bump(Actor Other,PrimitiveComponent OtherComp, Vector HitNormal)
{
	if(PAutoTurret(Other)!= None)
	{  //Es una torreta. Rebotamos
		//_DEBUG_ ("Bump contra Torreta"@Other.Name);
		ReboteRespectoA(Other);
	}
	else
	{
		//_DEBUG_ ("Bump contra Noseque"@Other.Name);
		ReboteRespectoA(Other,200);
	}

	if(PTree(other) != None)
	{
		PTree(other).Toque();
	}
	
}


event Touch(Actor Other,PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	//_DEBUG_ ("TOUUUUUUCH!!");
}
event bool EncroachingOn(Actor Other)
{
	//_DEBUG_ ("ENCROACHING OOOOOOOOON!!");
	
	return true; //to cancel the move
}

event EncroachedBy(Actor Other)
{
	//_DEBUG_ ("ENCROACHED BYYY!!");
}

event RanInto (Actor Other)
{
	//_DEBUG_ ("RANITOOOOO!!");


}


simulated function PostBeginPlay()
{
	//local ParticleSystemComponent PSC;
    local EmitterSpawnable PSC;
	super.PostBeginPlay();
	//CollisionComponent = Mesh;
    // Turning collision on for skelmeshcomp and off for cylinder
	CylinderComponent.SetActorCollision(false, false);
	Mesh.SetActorCollision(true, true);
	Mesh.SetTraceBlocking(true, true);

	if (self.Mesh.GetSocketByName('Socket_Cabeza') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'CTF_Flag_IronGuard.Effects.P_CTF_Flag_IronGuard_Idle_Blue');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Cabeza');
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Brazo_Derecho') != None)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);
		if (PSC != None)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Brazo_Derecho');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_brazo_dcho = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.3);			
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Antebrazo_Derecho') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);

		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Antebrazo_Derecho');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_antebrazo_dcho = m_ParticulasPropulsoresRobot.Length -1;
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Brazo_Izquierdo') != None)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);

		if (PSC != None)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Brazo_Izquierdo');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_brazo_ido = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.3);			
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Antebrazo_Izquierdo') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Antebrazo_Izquierdo');
			m_ParticulasPropulsoresRobot.AddItem(PSC);

			m_idx_antebrazo_ido = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.3);			
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Base') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);

		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Base');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_base = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.1);			
			//_DEBUG_ ("" @PSC.ParticleSystemComponent.InstanceParameters[0].Name);
			//_DEBUG_ ("" @PSC.ParticleSystemComponent.InstanceParameters[0].Scalar);
			//_DEBUG_ ("" @PSC.ParticleSystemComponent.InstanceParameters[0].ParamType);

		}
	}

	//Partículas del tonyazo contra el suelo
	m_particulas_tonyazo = Spawn(class'EmitterSpawnable',Self);
	if (m_particulas_tonyazo != none)
	{
			m_particulas_tonyazo.ParticleSystemComponent.bAutoActivate = false; 
			m_particulas_tonyazo.SetTemplate(ParticleSystem'PGameParticles.Particles.P_TonyazoGiru');
	}

	//Activamos propulsores
	EstadoPropulsores(true);

	//Instanciamos la Nube de Ira, que se activará al acercarnos al ogro
	m_nubeIra = spawn(class 'PNubeIra',self);
}

function ActivarNubeIra()
{
	//if (!m_particulas_Nube_Ira.ParticleSystemComponent.bIsActive)
	//{
		//ActualizaPosicionDeseadaNube();
		m_nubeIra.Activar();
	//}
}

function DesactivarNubeIra()
{
	m_nubeIra.Desactivar();
}

function EstadoNubeIra(int rayitos)
{
	//Si no estamos en el estado base, o saltando,nada de nubes.
	//Si no, al volar y tal también se pinta y hace cosicas feas ;)

	local name estado;
	estado = self.GetStateName();

	if ( (estado != 'PPawn' &&  estado != 'PawnFalling')
		 || rayitos == 0)
	{
		DesactivarNubeIra();
		return;
	}
	else
	{
		ActivarNubeIra();
		`log("____Activando nube ira");
		//Aplica el valor de la ira al número de rayitos que tiene la nuve
		m_nubeIra.SetNumRayitos(rayitos);
	}

	//La posición de la nube se actualiza a cada tick, si está activa
	
}

function RayazoNubeIra()
{
	//Hace que salga el rayazo de la nube hacia el Giru
	m_nubeIra.Rayaco();
	//sólo debe estár así un instante o saldrán rayos sin parar:
	//Por sistema de partículas no he sabido hacerlo..... mierda UDK de las narices... :( 
	SetTimer(0.8,false,'SaltaPorRayaco');
}

function SaltaPorRayaco()
{
	//Hacemos que el Giru pegue un saltico, rollo 'me ha hecho pupita'
	m_rayazo_recibido = true; //Para que vaya girando
	//IMPORTANTE::
	//Este booleano se pondrá a true cuando se acabe el salto, en el EndState de PawnFalling

	self.ReboteGrandeBumpCayendo(none,vect(0,0,0),vect(0,0,0));
}


function ActualizaPosicionDeseadaNube()
{
	local vector rx,ry,rz;
	local vector posNube;

	GetAxes (Self.Rotation,rx,ry,rz);
	posNube = self.GetPosicionSocketCabeza() + (rz * 55);
	m_pos_deseada_nube = posNube;
	
	//DrawDebugSphere(posNube,50,20,0,200,0,false);
	//DrawDebugCylinder(self.GetPosicionSocketCabeza(),posNube,6,5,200,0,0,false);
}
	


function Vector GetPosicionSocketCabeza()
{
	local vector sLocation;
	local rotator sRotation;

	self.Mesh.GetSocketWorldLocationAndRotation('Socket_Cabeza',sLocation,sRotation);
	return sLocation;
}

function Vector GetPosicionSocketCuerpo()
{
	local vector sLocation;
	local rotator sRotation;

	self.Mesh.GetSocketWorldLocationAndRotation('Socket_Cuerpo',sLocation,sRotation);
	return sLocation;
}


function EstadoPropulsores(bool bEstado)
{
	local int i;

	for (i=0;i<m_ParticulasPropulsoresRobot.Length;i++)
	{
		m_ParticulasPropulsoresRobot[i].ParticleSystemComponent.SetActive(bEstado);
	}
}

function OrientarPropulsores(float player_aTurn, float player_astrafe,float player_aforward)
{
	local Rotator r;
	////_DEBUG_ ("escaalar " @player_aTurn @player_astrafe @player_aforward);
	
	//Los dos brazos tendrán la misma rotación, así que usamos una de cualquiera de los dos para los cálculos
	r=m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.Rotation;

	if (player_astrafe <0 || player_aTurn <0)
    {
		//Girando a la izquierda
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.2);

		r.yaw =-15*DegToUnrRot;
    }
	else if (player_astrafe >0 || player_aTurn >0)
	{
		//Girando a la derecha
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.2);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);

		r.yaw = 15*DegToUnrRot;
	}
	else if (player_astrafe ==0 && player_aTurn == 0)
	{
		//es cero
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);
		r.yaw = 0;
	}

	//___Y AHORA PARA EL MOVIMIENTO HACIA DELANTE Y HACIA ATRAS _________
	if (player_aforward >0)
	{
		r.pitch = -25*DegToUnrRot;
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);

	}
	else if  (player_aforward <0)
	{
		r.pitch = 25*DegToUnrRot;
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);

	}
	else if  (player_aforward == 0)
	{
		r.pitch = 0;
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);

	}
    
	//Y asignamos la nueva rotación a los 2 brazos
	m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetRotation(r);
	m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetRotation(r);



}

function PotenciaPropulsorBase(float pot)
{
	//Ponemos la potencia del proyector base.
	//La usamos para el salto, para que en el momento del salto pase a máxima potencia
	//Y luego vaya bajando. Se hace en el tick del estado Falling.
	m_ParticulasPropulsoresRobot[m_idx_base].ParticleSystemComponent.SetFloatParameter('ParamAlpha',pot);
}


/**
 * Añadimos el arma al inventario
 * 
 * */
function AddDefaultInventory()
{
	InvManager.CreateInventory(class'PGame.PWeapon');
}

exec function qbase()
{
	//_DEBUG_ ("La Base actual es "@self.Base);
}
/** BaseChange
 * Función que se llamará una única vez por Pawn cada vez que cambie el
 * objeto físico sobre el que esté posado el Pawn.
 * Comprobamos si el objeto es de tipo PPaintCanvas y de ser así, le decimos que
 * tiene que cambiar de color/textura.
 */
singular event BaseChange()
{
	local vector direc;

	if (Base!=None) 
	{
		//_DEBUG_ ('Base Changed '@self.Base.Name);
	}
	else
	{
		//_DEBUG_ ('Base Changed to None');
	}
    
	if(PPaintCanvas(self.Base) != none)
	{
		PPaintCanvas(self.Base).ChangeTexture();
	}

	//Hacemos lo mismo que en Bump pa probar
	if(Base!=None &&   !PGame(Worldinfo.game).EsPlaneta(Base)  )
	{
	     if(PAutoTurret (Base) != None)
	     {  //Es una torreta. Rebotamos
			if (GetStateName() == 'PawnFallingSky')
			{
				//self.m_ULtimoFloorAntesSalto = 
				ReboteRespectoA(Base,500);
			}
			else
			{
				ReboteRespectoA(Base);
			}
	     }
		 else
		 {
			//Por si nos subimos a un extremo de un objeto y el spyder trepa...
			if(PTree(Base) != None)
			{
				PTree(Base).Toque();
			}

			ReboteRespectoA(Base, 200);
			/* Esto era la opción de simplemente alejarlo un pelín, pero daba problemas
			 * No lo borro just in case, aunque si se demuestra que lo del rebote funciona, a eliminarlo ;)
			direc=Base.Location-self.Location;
			self.SetLocation(self.Location+Normal(-direc)*5); //Nos alejamos un pelín
		 	self.SetBase(Base);
			*/

		 }
	}
}

// called when the pawn lands or hits another surface
event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
{
	
	//`log('Hit Wall neng');
	GotoState('');
	SetBase(Wall, HitNormal);

	if(PPaintCanvas(Wall) != none)
	{
		PPaintCanvas(Wall).ChangeTexture();
	}
}


/** Función DoJump
 * Sobreescribimos la función para decirle que si estás en disposición de saltar, no estas agachado (ni agachándote) 
 * y tienes un modelo físico válido, calcules la velocidad (el vector velocidad por el que te moverás) a partir de 
 * una constante de la altura a la que puedes saltar (JumpZ) y el vector del suelo.
 * 
 * El vector de suelo (Floor) siempre se considera en UDK como la superficie sobre la cual estás de pie.
 */
function bool DoJump( bool bUpdating )
{
	local vector tmpFloor;

	// Si podemos saltar...
	//Controlamos que no vengamos del Bump contra la torreta en este if. En el else sí se hace ese salto

	//IMPORTANTE!!!
	//Por cosas del UDK que desconozco, es mejor pasarle al Estado PawnFalling del salto la dirección de caída
	//con el floor que ahora sabemos que tenemos, o en el bump, si ya estaba saltando, como el Floor será de 0,0,1, 
	//hará cositas raras. Por tanto, FallDirection lo inicializamos aquí, y no en el BeginState de PawnFalling.
	//A tener en cuenta por si se necesita el salto desde otro sitio.

	if(!m_VenimosDeBump && bJumpCapable && !bIsCrouched && !bWantsToCrouch && Physics == PHYS_Spider)
	{
		// Calculamos la velocidad a partir de la constante de salto + el vector de suelo
		tmpFloor=Floor;
		if (Floor == vect(0,0,1) || Floor== vect(0,0,0))
		{
			//_DEBUG_  ("No lo entiendo...");
			tmpFloor=m_ULtimoFloorAntesSalto;
		}

		Velocity += JumpZ * tmpFloor;
		FallDirection = -tmpFloor;
		// Y vamos al estado PawnFalling
		//_DEBUG_ ('SALTO NORMAL  ' @tmpFloor);
		GotoState('PawnFalling');
		////_DEBUG_ ('DoJump de PPawn');
		return true;
	}
 	//_DEBUG_ ('DoJump de PPawn NO PUEDE SALTAR');
	//Si no puede saltar porque ya está saltando, no salta.
	//Pero si está saltando y la petición de salto viene desde el evento Bump, significa que durante el recorrido
	//del salto, ha encontrado una colisión, y se ha solicitado que salte hacia atrás.
	//En ese caso, sí que lo permitimos
	if(m_VenimosDeBump)
	{
		//_DEBUG_ ('SALTO por BUMP ' @m_ULtimoFloorAntesSalto);
		//_DEBUG_DrawDebugCylinder(self.Location,self.Location+m_ULtimoFloorAntesSalto*100,4,10,0,255,255,true);
		Velocity += JumpZ * m_ULtimoFloorAntesSalto;
		FallDirection = -m_ULtimoFloorAntesSalto;
		GotoState('PawnFalling');
		return true;
	}
	return false;
}


/*
 * Funcion OrientarPawnPorNormal.
 * Recibe la normal del suelo donde se acaba de colocar tras un salto o al volver de la vista aérea
 * En función de esa normal, orientamos al pawn
 */

function OrientarPawnPorNormal ( Vector normalsuelo, out Rotator pawnRotation)
{
	local Rotator rPawn;
	local Vector rX,rY,rZ;
	local Quat quatRZ,quatNormal;

	rPawn=Rotator(-normalsuelo);

	quatNormal=QuatFromRotator(rPawn);
	GetAxes(rPawn,rX,rY,rZ);
	quatRZ=QuatFromAxisAndAngle(rY,-90*DegToRad);
	quatRZ=QuatProduct(quatRZ,quatNormal);
	rPawn=QuatToRotator(quatRZ);

	//Intentamos mantener la orientación de roll de cuando estábamos arriba :
	if (m_bEstoyCayendoDelCielo)
	{
		m_bEstoyCayendoDelCielo = false;
		quatNormal=QuatFromRotator(rPawn);
		GetAxes(rPawn,rX,rY,rZ);
		quatRZ=QuatFromAxisAndAngle(rZ,m_roll_antes_caer_cielo*UnrRotToRad);
		quatRZ=QuatProduct(quatRZ,quatNormal);
		rPawn=QuatToRotator(quatRZ);
	}

    SetRotation(rPawn);
	self.Floor=normalsuelo;
	pawnRotation=rPawn;
	//c4 
	//DrawDebugCylinder(self.Location,self.Location+vector(rPawn)*100,5,20,255,0,0,true);
	//DrawDebugCylinder(self.Location,self.Location+normalSuelo*100,5,20,0,255,0,true);
}

/** -----------------------
 * ---Estado PawnFalling---
 * ------------------------
 * 
 * Estado personalizado al que pasará el Pawn cada vez que salte.
 * Se utiliza para saber cómo y hacia dónde aplicar la gravedad
 */
state PawnFalling
{


	event BeginState(Name PrevName)
	{

		//_DEBUG_ ('pawn en estado Falling');
		//DBG WorldInfo.Game.Broadcast(self,"Entrando en PawnFalling");
		//VMH: Lo inicializo en DoJump 
		//FallDirection = -Floor;
		
        // Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;

		// flying instead of Falling as flying allows for custom gravity
		SetPhysics(PHYS_Flying);
		fTiempoDeSalto=0.0; //tiempo de salto
		m_permiteMoverSaltando=true; //Si el salto se prolonga no permitimos que 'vuele'
		PotenciaPropulsorBase(1.0); //El máximo
	}

	event Tick(float DeltaTime)
	{	
		local vector vAlCentro;

		super.Tick(DeltaTime);

		// Apply Gravitational Force
		ApplyGravity(DeltaTime);
		fTiempoDeSalto+=DeltaTime;
		if (fTiempoDeSalto>3.0) //Se le ha ido la castaña al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Location; 
			FallDirection = Normal(vAlCentro);
			//_DEBUG_ ("volviendo pa la tierra neng!");
			m_permiteMoverSaltando=false;
			PotenciaPropulsorBase(0); //parecerá prácticamente apagado
		}
		PotenciaPropulsorBase(fclamp(1-(fTiempoDeSalto),0.1,0.8)); //Va perdiendo potencia
	}

	/** Adds gravity to the velocity based on floor normal pawn was last on */
	function ApplyGravity(float DeltaTime)
	{
		local Vector Gravity;

		Gravity = FallDirection * WorldInfo.WorldGravityZ * -1 * DeltaTime;

		// Add force to velocity
		Velocity += Gravity;
		////_DEBUG_ ('Gravity on Pawn en estado Falling');
	}

	// called when the pawn lands or hits another surface
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;
		local Rotator routPawn;

		GotoState('');
		PC = PPlayerController(Instigator.Controller);
		//_DEBUG_PC.ClientMessage("HitWallPawn");

		if (PGame(Worldinfo.game).EsPlaneta(Wall))
		{
			OrientarPawnPorNormal(HitNormal,routPawn);
			PC.GotoState('PlayerSpidering'); //Porque si veniamos de rebote al caer del planeta, el PC esta en otro estado
			
			//_DEBUG_ ('el pawn ha caido al suelo despues de saltar');
			SetBase(Wall, HitNormal);
		}
		else
		{
			ReboteRespectoA(Wall);
		}

		if(PPaintCanvas(Wall) != none)
		{
			PPaintCanvas(Wall).ChangeTexture();
		}
		PotenciaPropulsorBase(0.1); //El valor base
	}
   
	event EndState(Name NextState)
	{
		FallDirection = vect(0,0,0); // CLEAR DESTINATION FLOOR
		bDirectHitWall = false; 
		SetPhysics(PHYS_None); 
		SetPhysics(PHYS_Spider); // "Glue" back to surface
		
		//Ponemos a falso m_rayazo_recibido, para que el pawn deje de girar por el rayaco, si es que lo estaba haciendo ;)
		m_rayazo_recibido = false;
	}
}



/** -----------------------
 * ---Estado PawnFallingSky---
 * ------------------------
 * 
 * Copia de PawnFalling, con 4 cambios para la gestión de cuando caemos del cielo después de estar en vista aérea
 */
state PawnFallingSky
{
    ignores BaseChange;

	event BeginState(Name PrevName)
	{
		//_DEBUG_ ('pawn cayendo del cielo');
		// Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;
		//No tocamos las físicas, que siga en flying como en PC
		m_bEstoyCayendoDelCielo = true; //Para que sepa que venimos de caer del cielo

	}

	singular event Bump(Actor Other,PrimitiveComponent OtherComp, Vector HitNormal)
    {
		//SI mientras cae choca contra algo.
		//el tratamiento NO SE PORQUE se ejecuta este en lugar del hitwall, supongo que porque una torreta por ejemplo
		//no la considera como Wall.... Total, hacemos un tratamiento análogo, con otros estados casi copiados.
		local PPlayerController PC;
		PC = PPlayerController(Instigator.Controller);
		
		if(PAutoTurret(Other)!= None)
		{  //Es una torreta. Rebotamos
		   PC.GotoState('PlayerBumpCayendo');
		   ReboteGrandeBumpCayendo(Other,self.location,HitNormal, 100);
		}
		else if (PEnemy(Other)!=None)
		{
			//Lo reventamos llamando a su PawnCaidoEncima
			//Debe asegurarse que se elimina, se chafa, para que al hacer return
			//no vuelva a ejecutarse este Bump
			//_DEBUG_ ("Bump contra un PEnemy "@Other.Name);
			if(!PEnemy(Other).IsInState('ChafadoPorPawn')) //Estado en el que le pongamos cuando lo chafemos, por si está un rato
			{
				PEnemy(Other).PawnCaidoEncima();
			}
			return; //No hacemos nada más con él, lo ignoramos, hasta llegar al suelo
		}
		else if (Other.Name == 'PShield_0')
		{
			//_DEBUG_ ("Bump contra el escudo, lo ignoramos");
			return; //lo ignoramos, para que siga cayendo
		}
		else if (PTree(Other)!=None)
		{
			//_DEBUG_ ("Bump contra el escudo, lo ignoramos");
			PTree(Other).Destruccion(); //Nos cargamos el árbol y punto
			return; //lo ignoramos, para que siga cayendo
		}

		else
		{
			//_DEBUG_ ("Bump contra NO SE QUÉ!!! CUIDADOOOOOOO!!!");
			return; //lo ignoramos, para que siga cayendo
		}
    }
	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;


		if (Wall.Name == 'PShield_0')
		{
			return; //Lo ignoramos, para que siga cayendo
		}
		PC = PPlayerController(Instigator.Controller);
		//_DEBUG_PC.ClientMessage("HitWallPawn al caer del cielo_________________________________________");
		
		if (  PGame(Worldinfo.game).EsPlaneta(Wall))
		{
			//_DEBUG_ ('el pawn ha caido al suelo despues de bajar de vista aerea');
			SetBase(Wall, HitNormal);
			
			if(PPaintCanvas(Wall) != none)
			{
				PPaintCanvas(Wall).ChangeTexture();
			}
	
			//Se acaba de estoñar contra el suelo.
			//Guardamos la normal del piñazo para luego orientar el Pawn más tade
			m_NormalAlCaerSuelo=HitNormal;
			GoToState('PawnRecienCaido'); 
		}
		else if (PTree(Wall)!=None)
		{
			PTree(Wall).Destruccion();
		}
		else
		{
			//_DEBUG_ ('el pawn ha caido contra algo desde el cielo '@wall.Name);
			self.m_ULtimoFloorAntesSalto = HitNormal;
			self.ReboteRespectoA(wall,500);
			
		}
	}//event HitWall

	event EndState(Name NextState)
	{

		bDirectHitWall = false; 
		SetPhysics(PHYS_None);
		SetPhysics(PHYS_Spider); // "Glue" back to surface. Si no, se iría cayendo
		////_DEBUG_ ('el pawn deja de esar en FallingSky y va a '@NextState);
	}
}

//STATE PawnRecienCaido
function ActivarParticulasTonyazo()
{
	m_particulas_tonyazo.SetLocation(self.Location);
	m_particulas_tonyazo.SetRotation(self.Rotation);
	m_particulas_tonyazo.ParticleSystemComponent.ActivateSystem();
	m_particulas_tonyazo.ParticleSystemComponent.SetActive(false);
	m_particulas_tonyazo.ParticleSystemComponent.SetActive(true);
}

state PawnRecienCaido
{
	//ignores HitWall;

	event BeginState(Name prevstate)
	{
		//S.Particules de caida, y a los dos segundos, volvemos al estao normal.
		//Al PlayerController le ponemos también en un estado dummy para que no pueda hacer nada el jugador
		local PPlayerController PC;

		PC = PPlayerController(Instigator.Controller);
		PC.GotoState('PlayerRecienCaido');
		ActivarParticulasTonyazo();
		SetTimer(2,false,'TimerCaida');
	}

	function TimerCaida()
	{

		//Apagamos el sistema de partículas, y volvemos a la normalidad
		m_particulas_tonyazo.ParticleSystemComponent.SetActive(false);
		m_particulas_tonyazo.ParticleSystemComponent.DeactivateSystem();
		GoToState('');

	}
	
	event EndState(Name nexstate)
	{
		local PPlayerController PC;
		local Rotator routPawn;

		PC = PPlayerController(Instigator.Controller);
   
		OrientarPawnPorNormal(m_NormalAlCaerSuelo,routPawn);
		//_DEBUG_DrawDebugCylinder(self.Location,self.location+self.Floor*140,6,10,255,0,0,true);
		PC.GotoState('PlayerSpidering'); //--> OJO con la ÑAPA en player Controller para coger el floor inicial...

		EstadoPropulsores(true);
	}

}


//STATE PAWNFLAYING:

state PawnFlaying
{
	//En este estado, no queremos que el pawn haga absolutamente nada, ya que estará invisible, y el control lo haremos
	//entero desde PPlayerController, con el estado PlayerFlaying

	event BeginState(Name PreviousState)
	{
		//_DEBUG_ ("Pawn en PawnFlaying, previous was: "@PreviousState);
		//Invisible, y a volar!
		Mesh.SetOwnerNoSee(true);
		SetPhysics(PHYS_Flying);
		
	}
	
	event EndState(Name NextState)
	{
		//_DEBUG_ ("Pawn END state: "@NextState);
		//la ponemos visible de nuevo
		Mesh.SetOwnerNoSee(false);
		
	}

}//STATE PLAYERFLAYING


/******************************************************************************************************************/
state PawnPreparandoFlaying
{
	event BeginState(Name prevstate)
	{
		//_DEBUG_ ("Preparando para saltar");
		m_tiempoEstado=0;
		m_backupDistanciaAlSuelo = m_DistanciaAlSuelo; //Porque lo modificamos, para restaurarlo
	}

	event EndState(Name nextstate)
	{
		//_DEBUG_ ("Fin de PlayerPreparandoFlaying");
		m_DistanciaAlSuelo = m_backupDistanciaAlSuelo;
	}

	event Tick(float DeltaTime)
	{
		local PPlayerController PC;
		local vector Parriba;
		local vector vx,vy,vz;

		m_tiempoEstado += DeltaTime;
		
		PC = PPlayerController(Instigator.Controller);

		if(m_tiempoEstado < 2)
		{
			//Vamos disminuyendo m_DistanciaAlSuelo para que baje
			//Tenemos que ir llamando al Tick del estado base para que lo haga
			//Pero sólo en este if,no hacer sl super.Tick al principio de la función
			//O el efecto de salto no se notará puesto que el tick lo baja al suelo
			super.Tick(DeltaTime);
			
			m_DistanciaAlSuelo -= int(1+(m_tiempoEstado*1.5));
			if (m_DistanciaAlSuelo <2) //que no llegue al suelo
			{
				m_DistanciaAlSuelo = 2;
			}
		}
		else if (m_tiempoEstado >2 && m_tiempoEstado <2.5)
		{
			//Iniciamos el despegue parriba
			GetAxes(self.Rotation,vX,vY,vZ);
			Parriba = 50 * vZ ;
			self.SetLocation(self.Location+Parriba);
			
		}
		else if (m_tiempoEstado > 2.5)
		{
			
			PC.GotoState('PlayerFlaying'); //El PC ya pone al Pawn en el estado que toca
		}
	}

}//state PawnPreparandoFlaying



event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{

	//Ha sido por disparo de Minion?
	if(PMisilMinion(DamageCauser) != None)
	{
		//_DEBUG_ ("Giru me ha disparado (Global TakeDamage PEnemy)"@self.Name);
		RecibidoDisparoMisil(HitLocation, Momentum,Projectile(DamageCauser));
		return;
	}
	if(PMisilScout(DamageCauser) != None)
		{
			//_DEBUG_ ("Giru me ha disparado (Global TakeDamage PEnemy)"@self.Name);
			RecibidoDisparoMisil(HitLocation, Momentum,Projectile(DamageCauser));
			return;
		}



} //TakeDamage


function RecibidoDisparoMisil(vector HitLocation, vector Momentum,Projectile misil)
{
	self.Life -= misil.Damage;
	`log("Toñazo recibido en Giru "@self.life);

	if (self.Life <= 0)
	{
		self.GotoState('GiruMuerto');
	}
}



defaultproperties
{
	// Propiedades que daremos por defecto
	WalkingPct=+0.4
	CrouchedPct=+0.4
	BaseEyeHeight=38.0
	EyeHeight=38.0
	GroundSpeed=440.0
	AirSpeed=440.0
	WaterSpeed=220.0
	AccelRate=2048.0
	JumpZ=500.0
	CrouchHeight=29.0
	CrouchRadius=21.0
	WalkableFloorZ=0.78
	bDirectHitWall=true
	bRollToDesired=True
	

	// Elimina el sprite del editor
	Components.Remove(Sprite)

	/** Hacemos que el Pawn pueda estar afectado por la iluminación.
	 * Si no incluimos esto, el Pawn no estará iluminado y se verá totalmente oscuro.
	 */
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object


	// Una vez configurada la iluminación, la añadimos al renderizador...
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	/** Propiedades de visualización del Pawn:
	 * - Esqueleto que usará
	 * - Modelo 3D que usará
	 * - Set de animaciones
	 * - Modelo físico del modelo
	 */
	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		

		//giru
		SkeletalMesh=SkeletalMesh'Giru.Giru'
		PhysicsAsset=PhysicsAsset'Giru.Giru_Physics'
		Scale=0.8

		//General Mesh Properties
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		bUseOnePassLightingOnTranslucency=TRUE
		bPerBoneMotionBlur=true
		HiddenGame=False
	End Object

	// Lo añadimos al motor
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)



	// Esto tiene algo que ver con el modelo físico de colisiones del modelo
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
	End Object

	// Lo añadimos al motor
	CylinderComponent=CollisionCylinder

	//Components.Remove(CollisionCylinder)

	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	//VLR Inventario para el arma
	InventoryManagerClass=class'PGame.PInventoryManager'

	//Para colisiones:
	bCollideComplex=true
	BlockRigidBody=true
	bCollideActors=true
	bCollideWorld=true
	CollisionType=COLLIDE_BlockAll
	
	m_DistanciaAlSuelo= 10
	life=100;
}
