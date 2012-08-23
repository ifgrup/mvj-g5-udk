/**
 * Controlador del personaje.
 * Controla todas las funciones de input del jugador en el juego para interactuar con el Pawn.
 * */
class PPlayerController extends GamePlayerController;

/**
 * Variables globales para el control de la posición y de la cámara.
 * */
var vector OldFloor;
var vector ViewX, ViewY, ViewZ;
var vector OldLocation;

var float mOffsetCamaraUpDown; //Para ir acumulando la altura de la cámara
var float mUltimoLookup; //para guardar el ultimo aLookUp de PlayerInput, no accesible desde el evento GetPlayerViewPoint

/**
 * Para calcular el Pitch de la cámara al mover el ratón.
 * */
var vector CamViewX, CamViewY, CamViewZ;

/**
 * Último vector normal de "suelo" antes de saltar.
 * */
var vector mUltimoFloorAntesSalto;
var float m_DistanciaAlCentro; //distancia que queremos mantener alrededor del planeta hasta su centro
var float m_ZoomMaxAcercar;
var float m_ZoomMaxAlejar;
var float m_DistanciaAlCentro_desiredZoom; //Destino deseable de la distancia tras el zoom con la rueda del mouse
var float m_distZoomActual;// Distancia actual que debe recorrerse con la rueda. Se actualiza a cada nuevo evento
var int m_stepZoom ;//unidades en las que se acerca o aleja la distancia con la rueda del mouse
//Variables para controlar la rotación
var Quat m_CurrentQuadFlaying;
var Quat m_DesiredQuadFlaying;
var float m_velocidad_rotacion;
var Vector m_posicionPawn; //Para ir guardando la posicion del pawn mientras volamos, porque parece que no se actualiza???
var bool m_vCaidaMax; //al caer al planeta, hemos llegadoa velocidad máxima de caida

var UberPostProcessEffect PPE;


//Control de caida PlayerFallingSky
var float m_tiempoCayendo;
var float m_acercandoCamaraCayendo;
var float m_aceleracionCaidaLibre;
var vector m_PosInicialCamaraCayendo;
var float m_minDistanciaCamaraCayendo;
var bool m_inicioAcercamiento;
var float m_tiempoCaidaSinMoverCamara;
var float m_tiempoTonyazo; //tiempo que hace que nos hemos estoñao al caer al planeta
var bool m_cambioEstadoPropulsores;
var float m_ultimoATurn; //Para que la camara pueda acceder a este valor
var float m_ultimoAStrafe; //Para guardarlo y poder pasarlo a OrientarPropulsores
var float m_ultimoAForward;//Para guardarlo y poder pasarlo a OrientarPropulsores
var rotator m_Rotation_4cam;
var rotator m_Rotation_4pawn;

var Vector m_PosicionCaidaPlaneta,m_NormalCaidaPlaneta; //Posicion y normal de caida al planeta
var float m_distCentroCaida; //Distancia al centro del planete desde el punto de caída del pawn al planeta
var Vector m_posicionRealCaidaSuelo,m_PosicionCaidaContraActor,m_NormalCaidaActor;
var bool  m_bContraSuelo;
var Actor m_ActorContraElQueCaemos; 

var vector  m_PosInicialAlSaltar;
var Rotator m_RotInicialAlSaltar;
var bool m_initPosAlSaltar;

var vector	m_donde_victor,m_floor_victor;
var PTurretIce m_torreta_victor;

/**
 *Gestión del ratón RR
 * 
 * */
//enum para el evento del mouse
enum EMouseEvent
{
	LeftMouseButton,
	RightMouseButton,
	MiddleMouseButton,
	ScrollWheelUp,
	ScrollWheelDown,
};



var SkeletalMesh transformedmesh;
var MaterialInterface transformedMaterial0;
var AnimTree transformedAnimTree;
var array<AnimSet> transformedAnimSet;
var AnimNodeSequence transformedAnimSeq;
var PhysicsAsset transformedPhysicsAsset;

exec function derp()
{
	self.Pawn.GroundSpeed+=500;
	self.Pawn.Mesh.SetSkeletalMesh(transformedMesh);
	self.Pawn.Mesh.SetMaterial(0,MaterialInstanceConstant'VH_TheCar.TheCar_Material');
	self.Pawn.Mesh.SetMaterial(1,MaterialInstanceConstant'VH_TheCar.TheCar_Material');
	self.Pawn.Mesh.SetPhysicsAsset(transformedPhysicsAsset);
	self.Pawn.Mesh.AnimSets=transformedAnimSet;
	self.Pawn.Mesh.SetAnimTreeTemplate(transformedAnimTree);
	self.Pawn.Mesh.SetTranslation(vect(0,0,80));
}



exec function ActivateDecals()
{
	PGame(WorldInfo.Game).bActivateDecalsOnWalk = !PGame(WorldInfo.Game).bActivateDecalsOnWalk;

	ClientMessage("Estado de las decals"@PGame(WorldInfo.Game).bActivateDecalsOnWalk);
}



/**
 * Función para actualizar la rotación del Pawn respecto a los inputs del jugador.
 * */
function UpdateRotation( float DeltaTime )
{
	local Rotator DeltaRot, newRotation, ViewRotation;
 
	ViewRotation = Rotation;
	if (Pawn!=none)
	{
		Pawn.SetDesiredRotation(ViewRotation);
	}
 
	// Calculate Delta to be applied on ViewRotation
	DeltaRot.Yaw    = PlayerInput.aTurn;
	DeltaRot.Pitch  = PlayerInput.aLookUp;
 
	ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
	SetRotation(ViewRotation);
 
	ViewShake( deltaTime );
 
	NewRotation = ViewRotation;
 
	if( Rotation.Roll != 0)
	{
		NewRotation.Roll = Rotation.Roll - (Rotation.Roll * deltaTime * 6);
	}
	else
	{
		NewRotation.Roll = 0;
	}
	
	if( Pawn != None )
		Pawn.FaceRotation(NewRotation, deltatime);

	SetRotation(NewRotation);
}

/**
 * Estado básico por defecto del Pawn.
 * Nada mas entrar en este estado, le decimos que active el estado Spidering.
 * */
state PlayerWalking
{
	event BeginState(Name PreviousStateName)
	{
		ClientMessage("Vamos al estado Spidering");
		//_DEBUG_ ("******************************Inicio de PlayerControler en PlayerWalking********************");
		GotoState('PlayerSpidering');
	}
	
	event EndState(Name NextStateName)
	{
		//DBG WorldInfo.Game.Broadcast(self,"Saliendo de PlayerWalking");
	}
}

/**
 * Estado de spidering.
 * Sobreescribimos la física del jugador para que se quede enganchado a cualquier superficie
 * del mundo. Se desactiva la gravedad por defecto del Pawn.
 * */
state PlayerSpidering
{
	ignores SeePlayer, HearNoise, Bump;

    /**
     * Actualizamos la rotación basándonos en el Floor en el que estamos actualmente.
     * */
	function UpdateRotation(float DeltaTime)
	{
		local rotator ViewRotation,lRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
		local bool bSaltando;
		local Vector ViewX_4pawn,ViewY_4pawn;
		local Vector lastX,lastY,lastZ;
		local float faTurn_discreto;
		local int signo;
		//ClientMessage("UPdate Estado spider" $ DeltaTime);
 
		
		/*
		 * PRUEBA ÑORDA PARA COMPROBAR CUÁL ES LA ROTACION DESEADA
		lRotation=Pawn.Rotation;
		lRotation.yaw+=DeltaTime*3*DegToUnrRot;
		Pawn.SetRotation(lRotation);
		return;
		*/

		//Mientras salta, Pawn.Base vale None
		//Si tiene que saltar, saltará en la vertical que YA tiene al estar caminando sobre el planeta
		//por lo que no hay que cambiar ninguna rotación
		if ( (Pawn.Base == None) || (Pawn.Floor == vect(0,0,0)) )
		{
			//MyFloor = vect(0,0,1);
			MyFloor=Normal(mUltimoFloorAntesSalto);
			//OldFloor=MyFloor;
			bSaltando=True;
			//return; //No recalculamos nada
		}
		else
		{
			MyFloor = Pawn.Floor;
			mUltimoFloorAntesSalto=MyFloor; //porque si salta, Base es null y no podremos calcular la normal desde donde saltamos
			bSaltando=False;
		}
        
		//Si estoy saltando, nada de transiciones de normales, sigo teniendo como normal la vertical del salto y punto
		if ( MyFloor != OldFloor && !bSaltando )
		{
			// smoothly transition between floors
			//Para colocar al bicho en la perpendicular del suelo
			RealFloor = MyFloor;
			MyFloor = Normal(6*DeltaTime * MyFloor + (1 - 6*DeltaTime) * OldFloor);
 
			if ( (RealFloor dot MyFloor) > 0.999 )
			{
				MyFloor = RealFloor;
			}
			else
			{
				// translate view direction
				CrossDir = Normal(RealFloor Cross OldFloor);
				FwdDir = CrossDir cross MyFloor; //Hacia delante, forward
				OldFwdDir = CrossDir cross OldFloor; //El hacia delante que tenía antes
				ViewX = MyFloor * (OldFloor dot ViewX) + CrossDir * (CrossDir dot ViewX) + FwdDir * (OldFwdDir dot ViewX);
				ViewX = Normal(ViewX);
				ViewZ = MyFloor * (OldFloor dot ViewZ) + CrossDir * (CrossDir dot ViewZ) + FwdDir * (OldFwdDir dot ViewZ);
				ViewZ = Normal(ViewZ);
				OldFloor = MyFloor;
				ViewY = Normal(MyFloor cross ViewX);
				//Pawn.mesh.SetRotation(OrthoRotation(ViewX,ViewY,ViewZ));
			}
		}
 
		//Guardamos aLookUp para GetPlayerViewPoint
		mUltimoLookup=PlayerInput.aLookUp;
		//Ahora giro de la cámara.
		//Al girar por aTurn,sólo nos afectará la rotación sobre el eje Z.
		//Por tanto, la Z quedará igual, la X es la que rotará, y la Y será el producto cartesiano de la nueva X por la Z que ya tenemos
		if ( (PlayerInput.aTurn != 0))
		{
			m_ultimoATurn = PlayerInput.aTurn;
		   // adjust Yaw based on aTurn

			if ( PlayerInput.aTurn != 0 )
			{
				ViewX = Normal(ViewX + 10 * ViewY * Sin(0.0005*DeltaTime*PlayerInput.aTurn));
				//Discretizamos el aTurn del pawn en escalas de 300, para que la rotación no haga flicker
				//Para que el nivel empiece en 1, sumanos 1*signo a la escala discreta calculada
				//El sin de la rotación del pawn lo hacemos constante para que siempre sea el mismo
				//o si no también hará flicker. Esto puede hacer que en cada máquina sea diferente.
				//Lo suyo sería rotar x grados sobre el ViewX calculado.
				//Si vemos que es diferente en cada máquina, lo haré así.
				//El código de abajo comentado con KKK es una primera aproximación

				signo=PlayerInput.aTurn/abs(PlayerInput.aTurn);
				faTurn_discreto=int(PlayerInput.aTurn/300) + 1*signo ; //nivel de discretización
				faTurn_discreto=faTurn_discreto*300; 
				////_DEBUG_ ("aTurn "@PlayerInput.aTurn  @faTurn_discreto);
				ViewX_4pawn = Normal(ViewX + 10 * ViewY * Sin(0.00002*faTurn_discreto));
				GetAxes(Pawn.Rotation,lastX,lastY,lastZ);
				ViewX_4pawn=VInterpTo(lastx,ViewX_4pawn,DeltaTime*1.1,30);
			}

 			// calculate new Y axis
			ViewY = Normal(MyFloor cross ViewX);
			//ViewY_4cam = ViewY;
			ViewY_4pawn = Normal(MyFloor cross ViewX_4pawn);
 		}
		else
		{   //Si no hay movimiento, volvemos a la posición normal en la que la rotación del pawn es igual
			//que la de la cámara
			m_ultimoATurn=0;
			ViewY_4pawn = ViewY;
			ViewX_4pawn = ViewX;

		}

		//Y ahora, asignamos al Pawn la rotación que hemos hecho para él
		//Pero para el resto de cosas, la 'correcta', para que sea la que utilice la cámara y el controller
		ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		m_Rotation_4pawn = OrthoRotation(ViewX_4pawn,ViewY_4pawn,ViewZ);

		/***********KKK*************/
		/*
		if ( PlayerInput.aTurn != 0 )
		{
			lRotation=ViewRotation;
			GetAxes(Pawn.Rotation,lastX,lastY,lastZ);
			lRotation.Yaw+=4000*signo;
			lastx = TransformVectorByRotation(lRotation,vect(1,0,0),false);
			lasty = Normal(MyFloor cross lastx);
			m_Rotation_4pawn = OrthoRotation(lastx,lasty,ViewZ);
		}
		*/
		
		
		SetRotation(m_Rotation_4pawn);
		if(Pawn != None)
		{
			Pawn.SetRotation(m_Rotation_4pawn);
		}		

		//Y la rotación para los efectos de cámara, la guardamos.
		//IMPORTANTE entonces, que siempre que queramos la rotación de cámara usemos esta, y no Pawn.Rotation
		m_Rotation_4cam=ViewRotation;
	}

	//Funcion que devuelve en el booleano parametro si se debe hacer rotacion up/down de la camara.
	//sólo será así si el cursor está por encima del límite horizontal definido para ese movimiento
	function bool DebeHacerseUPDownCamara()
	{
		
		local Vector2D MousePosition;
		local PPlayerInput pInput;
		
		pInput=PPlayerInput(PlayerInput);

		MousePosition.X = pInput.MousePosition.X;
		MousePosition.Y = pInput.MousePosition.Y;

		
		if (MousePosition.Y < 175)
			return true;
		else
			return false;
	}


	/**
	 * Evento que se ejecuta cuando caes sobre algo al caminar normal (PlayerWalking).
	 * Dentro del estado spidering nunca pasará, ya que estás pegado a las superficies y no se puede caer.
	 * El saltar en este estado genera un evento HitWall dentro de PPawn en el estado PawnFalling. 
	 * */
	
	
    function bool NotifyLanded(vector HitNormal, Actor FloorActor)
	{
		//_DEBUG_ ("He caido sobre algo, NO despues de saltar.Es inicio de juego.");
		if (PPawn(pawn)!=None)
		{
			Pawn.SetPhysics(PHYS_None);
			Pawn.SetPhysics(PHYS_Spider);
			Pawn.SetBase(FloorActor, HitNormal);
			return bUpdating;
		}

	}

	/**
	 * Comprobamos si cambiamos de Volumen de físicas.
	 * Ahora mismo sólo comprobamos si estamos dentro de agua, para no engancharnos a nada y poder nadar 
	 * */
	event NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume )
		{
			GotoState(Pawn.WaterMovementState);
		}
	}
 
	/**
	 * Función para procesar los movimientos generados en PlayerMove.
	 * Actualmente únicamente controlamos:
	 * - Aceleración del personaje.
	 * - Salto del personaje.
	 * */
    function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
    {
		if ( Pawn != None )
		{
			if ( Pawn.Acceleration != NewAccel )
			{
				Pawn.Acceleration = NewAccel;
			}

			if ( bPressedJump )
			{
				ClientMessage("Va a saltar");
				PPawn(Pawn).DoJump(bUpdating);
			}

			/** Comprobamos cada vez que nos movemos si la última posición en la que dejamos un decal
			 * y la posición actual, es mayor a la mitad del tamaño del decal.
			 * Así nos aseguramos de que el próximo decal que pintemos, no se superpondrá al último decal
			 * pintado.
			 * */
			if(PGame(WorldInfo.Game).bActivateDecalsOnWalk)
			if(VSize(OldLocation - Pawn.Location) > (PGame(WorldInfo.Game).fDecalSize / 2))
			{
				if(PPaintCanvas(Pawn.Base) == none && Pawn.Base != none)
				{
					OldLocation = Pawn.Location;
					WorldInfo.MyDecalManager.SpawnDecal
					(
						DecalMaterial'WP_BioRifle.Materials.Bio_Splat_Decal_001',	// UMaterialInstance used for this decal.
						Pawn.Location,	                            // Decal spawned at the hit location.
						rotator(-Pawn.Floor),	                    // Orient decal into the surface.
						PGame(WorldInfo.Game).fDecalSize, PGame(WorldInfo.Game).fDecalSize,	                                    // Decal size in tangent/binormal directions.
						PGame(WorldInfo.Game).fDecalSize *2,	                                        // Decal size in normal direction.
						true,	                                        // If TRUE, use "NoClip" codepath.
						FRand() * 360,	                                // random rotation
						,                    
						,
						,
						,
						,
						,100000 // Hack para que los decals tarden mucho en desaparecer... C U T R E :D
					);
				}
			}
			PPAwn(Pawn).OrientarPropulsores(m_ultimoATurn,m_ultimoAStrafe,m_ultimoAForward);
		}
    }



	/**
	 * bAlgoDelante valdrá !=0 si hay algo delante con lo que colisiona, impidiendo el avance
	 * valdrá false si puede seguir palante sin problemas
	 */
	

    function CheckDelantePawn(Vector direccion,out int bAlgoDelante)
	{
		local Vector pFinTrace,pInitTrace;
		local Vector HitLocation,HitNormal;
		local Actor aTrace1,aTrace2,aTrace3;
		local Vector mFloor;
	
	   
		bAlgoDelante=0;
		return;


		if (direccion==vect(0,0,0))
			return;
		pFinTrace=PPawn(Pawn).Location+Normal(direccion)*20; //Del obstáculo hacia nosotros
		pInitTrace=pFinTrace+Normal(direccion)*120; //Hacia donde nos dirigimos
		//DrawDebugCone(pInitTrace,direccion,45,0.01,0.01,10,MakeColor(200,200,0),false);
		mFloor=PPawn(Pawn).Floor;
		//DrawDebugCone(pInitTrace-(mFloor*20),pFinTrace-pInitTrace,45,0.01,0.01,10,MakeColor(200,200,0),false);
		//DrawDebugCone(pInitTrace+(mFloor*40),pFinTrace-pInitTrace,45,0.01,0.01,10,MakeColor(200,200,0),false);
		
		aTrace1=PPawn(Pawn).Trace(HitLocation,HitNormal,pFinTrace,pInitTrace,true,vect(12,12,12),,TRACEFLAG_Blocking);
		aTrace2=PPawn(Pawn).Trace(HitLocation,HitNormal,pFinTrace+(mFloor*40),pInitTrace+(mFloor*40),true,vect(12,12,12),,TRACEFLAG_Blocking);
		aTrace3=PPawn(Pawn).Trace(HitLocation,HitNormal,pFinTrace-(mFloor*20),pInitTrace-(mFloor*20),true,vect(12,12,12),,TRACEFLAG_Blocking);

		if (None==aTrace1 && none==aTrace2 && none==aTrace3)
		{
			//Raro, como mínimo tendría que colisionar con el propio pawn
			bAlgoDelante=0;
			return;
		}
		else
		{
			
			if (None!=aTrace1)
			{
				
				 if (aTrace1.Name!=name("StaticMeshActor_0") && aTrace1.Name!=name("StaticMeshActor_1"))
				 {
					//_DEBUG_ ("Nombre impacto trace "@aTrace1.Name);
					bAlgoDelante=1;
					return;
				 }
			}
			if (None!=aTrace2)
			{
				
				 if (aTrace2.Name!=name("StaticMeshActor_0") && aTrace2.Name!=name("StaticMeshActor_1") )
				 {
					//_DEBUG_ ("Nombre impacto trace2 "@aTrace2.Name);
					bAlgoDelante=1;
					return;
				 }

			}

			if (None!=aTrace3)
			{
				
				 if (aTrace3.Name!=name("StaticMeshActor_0") && aTrace3.Name!=name("StaticMeshActor_1") )
				 {
					//_DEBUG_ ("Nombre impacto trace3 "@aTrace3.Name);
					bAlgoDelante=1;
					return;
				 }

			}

		}
		bAlgoDelante=0;
		return;
	}
    

	/**
	 * Función para controlar el movimiento del personaje.
	 * */
    function PlayerMove( float DeltaTime )
    {
        local vector NewAccel;
        local eDoubleClickDir DoubleClickMove;
        local rotator OldRotation, ViewRotation;
        local bool  bSaveJump;
		local int bAlgoDelante;

        GroundPitch = 0;
        ViewRotation = Rotation;
		
        // Update rotation.
        SetRotation(ViewRotation);
        OldRotation = Rotation;
       
        //Giramos al pawn para que esté siempre perpendicular al suelo
        UpdateRotation(DeltaTime);

        // Update acceleration.

        NewAccel = PlayerInput.aForward*Normal(ViewX - OldFloor * (OldFloor Dot ViewX)) + PlayerInput.aStrafe*ViewY;
        m_ultimoAStrafe = PlayerInput.aStrafe;
		m_ultimoAForward = PlayerInput.aForward;

		//Comprobamos si al aplicar el movimiento, chocaría contra un objeto, y en tal caso, para no 'spidearlo', pues
		//no llamamos a ProcessMove, o ponemos el vector NewAccel a (0,0,0) para que no se mueva
       
        CheckDelantePawn(NewAccel,bAlgoDelante);
		if (bAlgoDelante!=0)
		{
			//_DEBUG_ ("tiene algo delante. No seguimos el movimiento");
			NewAccel=vect(0,0,0);
		}
       
		
		if (PPawn(pawn).GetStateName()=='PawnFalling' ) //&& PPAwn(pawn).bSaltoAcabado)
		{
			//Si está saltando, seguramente por un rebote, dejamos que se mueva durante el salto, pero
			//sólo un poquito, para poder evitar rebotes infinitos si siempre rebota en el mismo sitio
			//Pero si el salto se ha prolongado demasiado al ir volando, lo evitamos
			if (PPawn(pawn).m_permiteMoverSaltando)
			{
				NewAccel= NewAccel /10; //Si lo ponemos en vect(0,0,0), no se puede mover mientras salta
			}
			else
			{
				NewAccel = vect(0,0,0);
			}
		}

        if ( VSize(NewAccel) < 1.0 )
        {
            NewAccel = vect(0,0,0);
        }
 
        if ( bPressedJump && Pawn.CannotJumpNow() )
        {
            bSaveJump = true;
            bPressedJump = false;
        }
        else
            bSaveJump = false;
 
        DoubleClickMove = DCLICK_None;
        ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
        bPressedJump = bSaveJump;

		//drawdebugcone(pawn.Location,pawn.Floor,100,0.1,0.1,100,MakeColor(200,0,0));
		//drawdebugcone(pawn.Location,vector(PPawn(Pawn).rotation),100,0.1,0.1,100,MakeColor(0,0,200));
		
    }

	/**
	 * Inicialización del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		//_DEBUG_ ("__________________________BEGIN STATE PLAYERCONTROLLER.PLAYERSPIDERING_____________________");
		if (PreviousStateName!='PlayerRecienCaido' )
		{

			if(PPawn(Pawn).Floor==vect(0,0,0))
			{
				OldFloor = vect(0,0,1);
			}
			else
			{
				OldFloor=PPawn(Pawn).Floor;
			}

			GetAxes(PPawn(Pawn).Rotation,ViewX,ViewY,ViewZ);
		}
		else
		{
			//ÑAPA
			//Parece que hay veces en las que el BaseChanged del Pawn no se ejecuta o se ejecuta cuando le sale de los
			//cataplines, y se pone el PC en Spider antes de que el Pawn esté en el suelo.
			//Por tanto, el floor es 0,0,0, y el OldFloor que se rellena aquí es 0,0,0, y eso provoca que
			//luego nunca se cambie, y el UpdateRotation no cambie nunca la rotación. Maravilloso.
			//Lo controlamos poniendo el vector en 0,0,1. Se producirá un efecto raro de cojones, pero habrá rotación
			//al tick siguiente y se pondrá bien en principio...
			if(PPawn(Pawn).Floor==vect(0,0,0))
			{
				//_DEBUG_ ("KAGADA");
				GoToState('PlayerSpidering');
				return;
			}
			else
			{
				OldFloor=PPawn(Pawn).Floor;
			}
			GetAxes(PPawn(Pawn).Rotation,ViewX,ViewY,ViewZ);
		}

		DoubleClickDir = DCLICK_None;
		Pawn.ShouldCrouch(false);
		bPressedJump = false;
 
		if (Pawn.Physics != PHYS_Falling)
		{
			Pawn.SetPhysics(PHYS_Spider);
		}
 
		GroundPitch = 0;
		mOffsetCamaraUpDown=15.0; //angulo inicial de up/down de la cámara
	}

	/**
	 * Fin del estado.
	 * */
    event EndState(Name NextStateName)
    {
		//DBG WorldInfo.Game.Broadcast(self,"Saliendo de PlayerSpidering");
		SetPhysics(PHYS_Spider);
    }
}


state PlayerFlaying
{
	ignores SeePlayer, HearNoise, Bump;

	/**
	 * Inicialización del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		/*Debemos poner al Pawn en el cielo, hacerlo invisible, y poner las físicas en vuelo*/
		local Vector pPosition,vAlCentro;
		local vector Centro2Pawn; //del centro del planeta, a donde está el pawn
		local rotator rotPawn;
		local vector rX,rY,rZ;
		local Quat paraRoll;

		//Colocamos al Pawn volando, prolongando su Z actual:
        //_DEBUG_ ("PC Flaying 2");

		pPosition=PPawn(Pawn).Location;
		Centro2Pawn=Normal(pPosition-PGame(WorldInfo.Game).GetCentroPlaneta());
		pPosition=PGame(WorldInfo.Game).GetCentroPlaneta()+Centro2Pawn*m_DistanciaAlCentro;
		PPawn(Pawn).SetLocation(pPosition);
		vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Pawn.Location; //vector de dirección del prota.
		
		//Creamos un rotator que sea el del cielo al centro, pero manteniendo el roll del pawn cuando andaba
		//Obtenemos también así el QUAT inicial sobre el que iremos aplicando la rotación muhahahaha
		rotPawn=Rotator(vAlCentro);
		rotpawn.Roll = pawn.Rotation.yaw;

		/************
		 *INTENTO DE ORIENTARLO CON EL YAW DEL PAWN USANDO QUATERNIONS.
		GetAxes(rotPawn,rX,rY,rZ);

		m_CurrentQuadFlaying=QuatFromRotator(rotPawn);
		paraRoll = QuatFromAxisAndAngle(rx,ppawn(pawn).Rotation. yaw*UnrRotToRad*1);
		
		m_CurrentQuadFlaying = QuatProduct(paraRoll,m_CurrentQuadFlaying);
		rotPawn = QuatToRotator(m_CurrentQuadFlaying);

		m_DesiredQuadFlaying= m_CurrentQuadFlaying;
		
		/*m_CurrentQuadFlaying = QuatFromRotator(rotPawn);
		m_DesiredQuadFlaying= m_CurrentQuadFlaying;
		*/
        ************************************/

		m_CurrentQuadFlaying = QuatFromRotator(rotPawn);
		m_DesiredQuadFlaying= m_CurrentQuadFlaying;
		
        
		PPawn(Pawn).SetRotation(rotPawn);
		SetRotation(rotPawn);

		PPawn(Pawn).GotoState('PawnFlaying');
		SetPhysics(PHYS_None); 

		//DrawDebugCone(m_CentroPlaneta,pPosition-m_CentroPlaneta,m_DistanciaAlCentro,0.01,0.01,200,MakeColor(255,0,0,1),true);
		
		m_DistanciaAlCentro_desiredZoom=m_DistanciaAlCentro;
	}

	event EndState(Name NextState)
	{
		//No hacemos nada en principio.Para volver a bajar al planeta, vamos al estado PlayerFallingSky
		//_DEBUG_ ("PlayerController estaba en PlayerFlaying, yendo al estado "@NextState);
	
	}



	function UpdateRotation(float DeltaTime)
	{
        //Queremos asegurar que no hace nada, así que la dejamos en blanco y no ejecutamos nada de super 
		
	}

	function CalculaPosicionPorQuaternion(Quat pQuat, out Vector pPosicion)
	{
		local Rotator rFromQuad;
		local Vector X,Y,Z;
		local vector vDesdeCentro;

		rFromQuad=QuatToRotator(pQuat);
		GetAxes(rFromQuad,X,Y,Z);
		vDesdeCentro=PGame(WorldInfo.Game).GetCentroPlaneta() - (X*m_DistanciaAlCentro);
		pPosicion=vDesdeCentro;

	}

	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
	
		//m_QuadFlaying está actualizada con el Quad que toca. Obtengo su rotator, y la
		//X me dará la dirección al centro del planeta. Mantengo cte la distancia al centro en dicho X,
		//y punto
		local Vector Posicion;
		local Rotator rFromQuad;
		rFromQuad=QuatToRotator(m_CurrentQuadFlaying);
		out_Rotation=rFromQuad;
		PPawn(Pawn).SetRotation(out_Rotation);
		CalculaPosicionPorQuaternion(m_CurrentQuadFlaying,Posicion);
		PPawn(Pawn).SetLocation(Posicion);
		out_Location=Posicion;

		m_posicionPawn=Posicion;
		//DrawDebugCone(m_CentroPlaneta,Posicion,m_DistanciaAlCentro,0.01,0.01,200,MakeColor(0,255,0,1),false);

	}
    

	function PlayerMove(float aDeltaTime)
	{
		local vector X,Y,Z;
		local Quat qPitch,qYaw;
		local Rotator rActual;
		local float iUD,iLR;

		
        iUD=PlayerInput.aForward;
		iLR=PlayerInput.aStrafe;

		
		if (iUD!=0)
		{
			rActual=QuatToRotator(m_DesiredQuadFlaying);
			GetAxes(rActual,X,Y,Z);
			iUD=(iUD/abs(iUD))*m_velocidad_rotacion*DegToRad; //un grado cada vez
			qPitch=QuatFromAxisAndAngle(Y,iUD);
			m_DesiredQuadFlaying=QuatProduct(qPitch,m_DesiredQuadFlaying);
		}

		if(iLR!=0)
		{
			rActual=QuatToRotator(m_DesiredQuadFlaying);
			GetAxes(rActual,X,Y,Z);
			iLR=(iLR/abs(iLR))*m_velocidad_rotacion*DegToRad; //un grado cada vez
			qYaw=QuatFromAxisAndAngle(Z,-iLR); //Negado por la dirección de izda/dcha va al revés
			m_DesiredQuadFlaying=QuatProduct(qYaw,m_DesiredQuadFlaying);
		}
        
		//Aqui ya tengo actualizado el Quaternon deseado, al que quiero llegar.
		//En el tick lo interpolamos a partir del actual, y la posición la calculamos siempre a partir
		//del actual

	}

	function PlayerTick(float DeltaTime)
	{
		local Vector posCurrent, posDesired;
		local float dist;

		ActualizaZoomRueda(DeltaTime);
		CalculaPosicionPorQuaternion(m_CurrentQuadFlaying,posCurrent);
		CalculaPosicionPorQuaternion(m_DesiredQuadFlaying,posDesired);
		dist=VSize(posCurrent-posDesired);
		if(dist>10)
			m_CurrentQuadFlaying=QuatSlerp(m_CurrentQuadFlaying,m_DesiredQuadFlaying,DeltaTime);
		
		

		super.PlayerTick(DeltaTime);
			
	}

	function ActualizaZoomRueda(float delta)
	{
		//Vamos incrementando/decrementando la distancia al centro para que el zoom sea suave
        local float diff;
		local float decel; //para hacerlo decelerado...
		local float prop,sprop;
        
        diff=abs(m_DistanciaAlCentro-m_DistanciaAlCentro_desiredZoom);
        
		if(diff < 1) //para evitar histéresis, just in case
		{
			return;
		}

		prop=(diff/m_distZoomActual)*90; //irá de 90 a 0
		sprop=abs(sin(prop*DegToRad));
			
		decel=sprop*delta*1000*(m_distZoomActual/m_stepZoom); //Ponderamos en funcion de la distancia actual respecto al step
		
        if (m_DistanciaAlCentro < m_DistanciaAlCentro_desiredZoom)
        {
			m_DistanciaAlCentro+=decel;
			////_DEBUG_ ("Alejando "@decel);
        }
		else
		{	
			m_DistanciaAlCentro-=decel;
			////_DEBUG_ ("Acercando "@decel);
		}

	}

}//State PlayerFlaying



state PlayerFallingSky
{
	ignores SeePlayer, HearNoise;//, Bump;
  
	/**
	 * Inicialización del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		/*Simplemente, vamos cayendo, hasta que el Pawn nos avise de que estamos en el suelo */
		local Vector pPosition,vAlCentro;
        local PPawn  elPaun;
		local Actor  ActorTrace;
		local Vector HitActorTrace,HitActorNormal;
		local float  dist, min_dist_actual;

		
        //_DEBUG_ ("PC Falling Sky");
		elPaun=PPawn(pawn);

		
		pPosition=elPaun.Location;
		m_PosInicialCamaraCayendo=pPosition;

		vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition; //vector de dirección del prota.
		
		elPaun.Velocity=Normal(vAlCentro)*1000;//*10000;
		elPaun.Acceleration=pawn.Velocity*50000;

		//ponemos al pawn 300 unidades más abajo, porque pondremos la cámara 300 unidades más arriba para que se le vea caer
		elPaun.SetLocation(pPosition+Normal(vAlCentro)*300);
		elPaun.GotoState('PawnFallingSky');
		m_vCaidaMax=false;
		m_tiempoCayendo=0;
		m_acercandoCamaraCayendo=1; //Es un factor
		m_aceleracionCaidaLibre=1;
		m_inicioAcercamiento=false; 

		elPaun.EstadoPropulsores(false); //Apagamos los propulsores
		m_cambioEstadoPropulsores=false;
		//elPaun.OrientarPropulsores(elPaun.Rotation);

		//Calculamos la posición en la que caerá el pawn, contando con actores
		min_dist_actual = float(MaxInt);
		foreach	TraceActors(class 'Actor',ActorTrace,HitActorTrace,HitActorNormal,PGame(WorldInfo.Game).GetCentroPlaneta(),elPaun.Location,vect(10,10,10))
		{
			//no sé si podemos garantizar que el que escoja es el primero contra el que impactaríamos. Me aseguro cogiendo el que está
			//a distancia más pequeña del pawn
			dist = vsize (HitActorTrace - elPaun.Location);
			//_DEBUG_  ("TraceActors me devuelve el actor "@ActorTrace.Name);
			//_DEBUG_if(PEnemy(ActorTrace) != None) `log("Lo puedo convertir a pawn");
			if (dist < min_dist_actual && PEnemy(ActorTrace) == none) //pasamos de los pawns
			{
				//_DEBUG_  ("Candidato TraceActors"@ActorTrace.Name);
				m_ActorContraElQueCaemos = ActorTrace;
				m_PosicionCaidaContraActor = HitActorTrace;
				m_NormalCaidaActor = HitActorNormal;
				min_dist_actual = dist;

			}
		}

		//Calculamos posición de choque contra el planeta y nada más, para lo que hacemos el trace de dentro del planeta pa fuera ;)
		Trace(m_PosicionCaidaPlaneta,m_NormalCaidaPlaneta,elPaun.Location,PGame(WorldInfo.Game).GetCentroPlaneta(),false,vect(1,1,1));

		if (m_PosicionCaidaPlaneta == vect(0,0,0))
		{
			//_DEBUG_ ("Kagada en el trace coleguita....");
		}

		//_DEBUG_DrawDebugSphere(m_PosicionCaidaPlaneta,30,40,0,1,200,true);
		//Si caigo sobre algo que no es el planeta ni contra un PEnemy, la caida es contra ese algo
		if(  m_ActorContraElQueCaemos != None && 
			(m_ActorContraElQueCaemos !=elpaun.m_BasePlaneta && (PEnemy(m_ActorContraElQueCaemos) ==None))   )
		{
			
			//_DEBUG_ ("Caemos encima de "@m_ActorContraElQueCaemos.Name);
			m_posicionRealCaidaSuelo = m_PosicionCaidaContraActor;
			m_bContraSuelo = false;
		}
		else //Si el traceactors no ha encontrado nada, o bien el planeta o u PEnemy, pues eso, caemos contra el planeta
		{
			//_DEBUG_ ("Caemos contra el suelo");
			m_posicionRealCaidaSuelo = m_PosicionCaidaPlaneta ;
			m_bContraSuelo = true;
		}
		//_DEBUG_ ("Distancia inicial al suelo ____________" @vsize(elPaun.Location-m_posicionRealCaidaSuelo));
		m_distCentroCaida = vsize (m_posicionRealCaidaSuelo - PGame(WorldInfo.Game).GetCentroPlaneta());

		//Le guardamos al Pawn su roll antes de caer al suelo, para que la orientación al caer sea la misma
		PPawn(Pawn).m_roll_antes_caer_cielo = Pawn.Rotation.roll;
	
	}

	event PlayerTick(float DeltaTime)
	{
		super.PlayerTick(DeltaTime);

		//Primero control de la cámara
		m_tiempoCayendo+=DeltaTime;
		if (m_tiempoCayendo > m_tiempoCaidaSinMoverCamara)
		{
			//Guardamos la distancia actual de la camara hasta el pawn, para ir decrementándola
			if(!m_inicioAcercamiento)
			{
				m_inicioAcercamiento=true;
				m_acercandoCamaraCayendo=vsize(PPawn(Pawn).Location-m_PosInicialCamaraCayendo);
			}
			m_acercandoCamaraCayendo-=800*DeltaTime; //La vamos decrementando
			m_acercandoCamaraCayendo=FClamp(m_acercandoCamaraCayendo,m_minDistanciaCamaraCayendo,30000);
			////_DEBUG_ ("La distancia es "@m_acercandoCamaraCayendo);

			//Update de la aceleración
			m_aceleracionCaidaLibre*=1+DeltaTime/5;
		}

		//Propulsores apagados un segundo (Caída libre), y luego se encienden
		if (m_tiempoCayendo>1 && !m_cambioEstadoPropulsores)
		{
			ppawn(pawn).EstadoPropulsores(true); 
			m_cambioEstadoPropulsores=true;
		}

	}

	event EndState(Name NextState)
	{
		//_DEBUG_ ("PlayerController yendo al estado "@NextState);
	}		

	function UpdateRotation(float DeltaTime)
	{
        //Queremos asegurar que no hace nada, así que la dejamos en blanco y no ejecutamos nada de super 
	}

	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Vector alPlaneta;
		local Vector pPosition;
		
		pPosition=PPawn(pawn).Location;
		alPlaneta=PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition;
		
		//Primero estamos medio segundo sin mover la cámara, viendo la caída libre
		if (m_tiempoCayendo < m_tiempoCaidaSinMoverCamara)
		{
			out_Location=m_PosInicialCamaraCayendo;
		}
		else
		{
			//Cuando pasa medio segundo, acercamos la cámara rápidamente hasta una distancia mínima del pawn, 
			//en la que nos mantendremos hasta que el pawn se estoñe contra el suelo
			/////out_Location=PPawn(pawn).Location-Normal(alPlaneta)*300; //Para que la cámara esté por encima del pawn y se vea
			out_location=PPawn(pawn).Location-Normal(alPlaneta)*m_acercandoCamaraCayendo;
		}

		out_Rotation=PPawn(pawn).Rotation; //No la cambiamos en toda la bajada

	}
    
	
	function PlayerMove(float aDeltaTime)
	{
		//vamos acercando el pawn al planeta
		local Vector pPosition;
		local Vector alPlaneta;
		local Vector step;

		local float distActual;
		local float distCentroActual;

		super.PlayerMove(aDeltaTime);

		pPosition=PPawn(pawn).Location;
		alPlaneta=PGame(WorldInfo.Game).GetCentroPlaneta()-pPosition;
		//Caida libre hasta el suelo
		//controlamos la velocidad máxima
	
		step=Normal(alPlaneta)*aDeltaTime*800*m_aceleracionCaidaLibre;

		if (m_PosicionCaidaPlaneta != vect(0,0,0))
		{
			distActual = vsize(m_posicionRealCaidaSuelo - (pPosition+step));
			distCentroActual = vsize ((pPosition+step) - PGame(WorldInfo.Game).GetCentroPlaneta());
			
			////_DEBUG_ ("Distancia al suelo ____" @distActual);
			//Si nos hemos pasao de 10 (estamos más cerca del centro que el punto de caída)
			if (distCentroActual < m_distCentroCaida+10)
			{

				//_DEBUG_ ("______________Toñazo por distancia contra "@m_ActorContraElQueCaemos.Name);
				if(self.m_bContraSuelo)
				{
					//Invocamos al Hitwall del Pawn, que pasará el Controller a estado PlayerRecienCaido
					PPawn(pawn).SetLocation(m_posicionRealCaidaSuelo - normal(step)*100); //un poquito por encima del planeta porsiaca...
					PPawn(pawn).Velocity = Normal(alPlaneta)*10; //despacito
					PPawn(pawn).Floor = m_NormalCaidaPlaneta; //despacito
					PPawn(pawn).m_ULtimoFloorAntesSalto =  m_NormalCaidaPlaneta;
					PPawn(pawn).m_VenimosDeBump = true; //Si no no deja saltar
					PPawn(pawn).DoJump(true);
					
					//PPawn(pawn).HitWall(m_NormalCaidaPlaneta,PPawn(pawn).m_BasePlaneta,none);
					
					GoToState('PlayerRecienCaido'); //EL Pawn también nos llevará, pero así aseguramos que
				}
				else
				{
					if (PPawn(pawn).IsInState('PawnFallingSky'))
					{
						PPawn(pawn).SetLocation(m_posicionRealCaidaSuelo - normal(step)*5); //un poquito por encima del actor porsiaca...
						PPawn(pawn).Bump(m_ActorContraElQueCaemos,none,m_NormalCaidaActor);
						GoToState('PlayerBumpCayendo'); //EL Pawn también nos llevará, pero así aseguramos que
						//No ejecutará más este PlayerMove.
					}
					else
					{
						//Significa que el bump ya lo ha puesto en PlayerFlying, no hacemos nada
					}
				}
			}
			else
			{
				//Lo dejamos que vaya cayendo como hasta ahora
				PPawn(pawn).SetLocation(pPosition+step);
			}
		}
		else
		{
			//El trace inicial cascó, o sea que lo hacemos como hasta ahora confiando que se ejecute el HitWall
			PPawn(pawn).SetLocation(pPosition+step);
		}

		ProcessMove(aDeltaTime,PPawn(Pawn).Acceleration,DCLICK_None ,Rotator(vect(0,0,0)));
	
	}
}

/************************************************************************************************************************/
state PlayerRecienCaido
{
	//Todo vacío, no queremos que haga nada
	event BeginState(Name prevstate)
	{
		//_DEBUG_ ("Recien estonyao");
		//Es el pawn quien nos pone en este estado al estoñarse (Pawn en estado PawnRecienCaido)
		//Y es el pawn quien con su timer nos devuelve a la situación normal luego
		m_tiempoTonyazo = 0;
	}

	event EndState(Name nextstate)
	{
		//_DEBUG_ ("Fin de estonyamiento");
	}

	event PlayerTick(float DeltaTime)
	{
		super.PlayerTick(DeltaTime);
		m_tiempoTonyazo += DeltaTime;
	}

	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Vector alPlaneta;
		local Vector pPosition;
		local float tick_random,tick_sin;
		
		pPosition = PPawn(pawn).Location;
		alPlaneta = PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition;

		if(m_tiempoTonyazo < 1)
		{
			tick_random = 1;
			tick_sin = 50*sin(m_tiempoTonyazo*25);
		}
		else
		{
			tick_random = 2 - m_tiempoTonyazo; //va decrementando hasta cero
			tick_sin = 10*sin(m_tiempoTonyazo*25);
		}

		//Temblamos la cámara
		out_Location = pPosition - Normal (alPlaneta) * (m_minDistanciaCamaraCayendo+tick_sin);
		out_Rotation=PPawn(pawn).Rotation;
		out_Rotation.Roll += rand(3000*tick_random);
		out_Rotation.Roll -= rand(3000*tick_random);
	
	}

}//state PlayerRecienCaido

/******************************************************************************************************************/
state PlayerBumpCayendo
{
	//Todo vacío, no queremos que haga nada
	event BeginState(Name prevstate)
	{
		//_DEBUG_ ("PC Bump mientras caía");
		//Es el pawn quien nos pone en este estado al hacer Bump en PawnFallingSky. Pawn hará un rebote
		//Así que se irá a PawnFalling
		//Y es el pawn quien cuando después de rebotar vuelve al suelo, pone al PC en Spidering again
		m_tiempoTonyazo = 0; //Para control del temblor de la cámara sólo medio segundo
	}

	event EndState(Name nextstate)
	{
		//_DEBUG_ ("Fin de PlayerBumpCayendo");
	}

	event PlayerTick(float DeltaTime)
	{
		super.PlayerTick(DeltaTime);
		m_tiempoTonyazo += DeltaTime;
	}

	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Vector alPlaneta;
		local Vector pPosition;
		
		pPosition = PPawn(pawn).Location;
		alPlaneta = PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition;

		if(m_tiempoTonyazo < 1)
		{
			//Temblamos la cámara
			out_Location = pPosition - Normal (alPlaneta) * (m_minDistanciaCamaraCayendo+50*sin(m_tiempoTonyazo*25));
			out_Rotation=PPawn(pawn).Rotation;
			out_Rotation.Roll += rand(3000);
			out_Rotation.Roll -= rand(3000);
		}
		else
		{
			//Simplemente nos quedamos a las espaldas del pawn mientras rebota, hasta que llegue al suelo.
			out_Location = pPosition - Normal (alPlaneta) * m_minDistanciaCamaraCayendo;
			out_Rotation=PPawn(pawn).Rotation;
		}

	}

}//state PlayerBumpCayendo


/******************************************************************************************************************/
state PlayerPreparandoFlaying
{
	event BeginState(Name prevstate)
	{
		//_DEBUG_ ("Preparando para saltar");
		PPawn(pawn).GotoState('PawnPreparandoFlaying');
		m_initPosAlSaltar = true;
		//Si aqui guardamos la posicion y rotacion actuales de la camara,
		//Y sobreescribimos el GetPlayerViewPoint para que siempre devuelva eso
		//Podríamos hacer el efecto de que la cámara no se mueve, y ver despegar al robot
	}

	event EndState(Name nextstate)
	{
		//_DEBUG_ ("Fin de PlayerPreparandoFlaying");
		//Ya estamos volando, actualizamos booleano para control de HUD
		PGame(WorldInfo.Game).bEarthNotFlying =! PGame(WorldInfo.Game).bEarthNotFlying;
		
	}

	event PlayerTick(float DeltaTime)
	{
		super.PlayerTick(DeltaTime);
	}

	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Vector alPlaneta;
		local Vector pPosition;

		if (m_initPosAlSaltar)
		{
			super.GetPlayerViewPoint(out_Location,out_Rotation);
			m_PosInicialAlSaltar = out_Location;
			m_RotInicialAlSaltar = out_Rotation;
			m_initPosAlSaltar = false;
		}

		out_Location = m_PosInicialAlSaltar;
		out_Rotation = m_RotInicialAlSaltar;
	}



}//state PlayerPreparandoFlaying



/**
 * Eventos de Ratón RR
 * 
 * 
 * */

//Tratar los inputs del mouse
function HandleMouseInput(EMouseEvent MouseEvent, EInputEvent InputEvent)
{
	local PHUD pHUD;

	pHUD = PHUD(myHUD);

	if(pHUD != none)
	{
		//Detectar que tipo de input se ha realizado
		if(InputEvent == IE_Pressed)    //Pressed event
		{
			switch(MouseEvent)
			{
				case LeftMouseButton:
					pHUD.PendingLeftPressed = true;
					break;

				case RightMouseButton:
					pHUD.PendingRightPressed = true;
					break;

				case MiddleMouseButton:
					pHUD.PendingMiddlePressed = true;
					break;

				/*case ScrollWheelUp:
					pHUD.PendingScrollUp = true;
					break;

				case ScrollWheelDown:
					pHUD.PendingScrollDown = true;
					break;
				*/
				default:
					break;
			}
		}
		else if(InputEvent == IE_Released)  //Released event
		{
			switch(MouseEvent)
			{
				case LeftMouseButton:
				pHUD.PendingLeftReleased = true;
					break;

				case RightMouseButton:
					pHUD.PendingRightReleased = true;
					break;

				case MiddleMouseButton:
					pHUD.PendingMiddleReleased = true;
					break;

				default:
					break;
			}
		}
	}
}



exec function ZoomPlanetaAcerca()
{
	local bool bTierraAire;
	
	//PGame(WorldInfo.Game).bEarthNotFlying =! PGame(WorldInfo.Game).bEarthNotFlying;
	bTierraAire=PGame(WorldInfo.Game).bEarthNotFlying;
	if(!bTierraAire)
	{
		if(m_DistanciaAlCentro_desiredZoom <= m_ZoomMaxAcercar)
			return;

		m_DistanciaAlCentro_desiredZoom-=m_stepZoom;
		m_distZoomActual=abs(m_DistanciaAlCentro_desiredZoom-m_DistanciaAlCentro);
		//DBG PGame(WorldInfo.Game).Broadcast(self, "Acercando al planeta:"@m_DistanciaAlCentro);

	}
}

exec function ZoomPlanetaAleja()
{
	local bool bTierraAire;
	
	//PGame(WorldInfo.Game).bEarthNotFlying =! PGame(WorldInfo.Game).bEarthNotFlying;
	bTierraAire=PGame(WorldInfo.Game).bEarthNotFlying;
	if(!bTierraAire)
	{
		if(m_DistanciaAlCentro_desiredZoom >= m_ZoomMaxAlejar)
			return;

		m_DistanciaAlCentro_desiredZoom+=m_stepZoom;
		m_distZoomActual=abs(m_DistanciaAlCentro_desiredZoom-m_DistanciaAlCentro);
		//DBG PGame(WorldInfo.Game).Broadcast(self, "Alejando del planeta:"@m_DistanciaAlCentro);
	}

}

exec function vuela()
{
	local bool bTierraAire;
	
	//Si estamos en el suelo, pasamos al estado de preparar el salto, pero no actualizamos el booleano
	//de bEarthNotFlying hasta que realmente estemos en el aire. 

	
	bTierraAire=PGame(WorldInfo.Game).bEarthNotFlying;
	
	if(!bTierraAire) //Si estoy volando, es que quiero bajar al planeta
	{
		PGame(WorldInfo.Game).bEarthNotFlying =! PGame(WorldInfo.Game).bEarthNotFlying;
		GotoState('PlayerFallingSky');
	}
	else
	{
		GotoState('PlayerPreparandoFlaying'); //Para preparar el salto para arriba
	}
}

// Called when the left mouse button is pressed
exec function LeftMousePressed()
{
	//if(PGame(WorldInfo.Game).bEarthNotFlying)
	//super.StartFire();

	//else
		HandleMouseInput(LeftMouseButton, IE_Pressed);
}

// Called when the left mouse button is released
exec function LeftMouseReleased()
{
	if(PGame(WorldInfo.Game).bEarthNotFlying)
		super.StopFire();

 
	else{
	super.StopFire();
		HandleMouseInput(LeftMouseButton, IE_Released);
	}
}

// Called when the right mouse button is pressed
exec function RightMousePressed()
{
  HandleMouseInput(RightMouseButton, IE_Pressed);
}

// Called when the right mouse button is released
exec function RightMouseReleased()
{
  HandleMouseInput(RightMouseButton, IE_Released);
}

// Called when the middle mouse button is pressed
exec function MiddleMousePressed()
{
  HandleMouseInput(MiddleMouseButton, IE_Pressed);
}

// Called when the middle mouse button is released
exec function MiddleMouseReleased()
{
  HandleMouseInput(MiddleMouseButton, IE_Released);
}

// Called when the middle mouse wheel is scrolled up
exec function MiddleMouseScrollUp()
{
  HandleMouseInput(ScrollWheelUp, IE_Pressed);
}

// Called when the middle mouse wheel is scrolled down
exec function MiddleMouseScrollDown()
{
  HandleMouseInput(ScrollWheelDown, IE_Pressed);
}

exec function ice()
{
	
	m_donde_victor = pawn.Location;
	m_floor_victor = pawn.Floor;
	settimer(2,false,'pontorretahielo');
}

function pontorretahielo ()
{
	local pturretice ti;
	local rotator r;
	local Vector2D p1,p2;
	local vector wp1,wp2,wp;
	local vector newfloor;
/*
	local PHUD pHUD;
	pHUD = PHUD(myHUD);
	p1.X=100;p1.Y=100;
	p2.X=p1.x;p2.y=p1.y-10;
	pHUD.Canvas.DeProject(p1,wp1,wp);
	pHUD.Canvas.DeProject(p2,wp2,wp);
	newfloor = wp2-wp1;
*/
	if (m_torreta_victor == None)
	{
		r=Rotator(-m_floor_victor); //hacia el suelo
		r.Pitch+=65535/4; //90 grados parriba
		ti=spawn(class'PTurretIce', ,,m_donde_victor,r);
		ti.m_TiempoEnConstruccion = 0.1;
		ti.setNormalSuelo(m_floor_victor);
		m_torreta_victor = ti;
	}
	m_torreta_victor.SetCollision(false,false,true);
	m_torreta_victor.SetCollisionType(COLLIDE_NoCollision);
	m_torreta_victor.DisparoTorreta();
	m_torreta_victor.GotoState('Disparando');
}

exec function icer(int radio)
{
	m_torreta_victor.m_radioinicial = radio;
	ice();
}
defaultproperties
{
	
	cameraclass=class 'PGame.PCamera'
	transformedMesh=SkeletalMesh'VH_Cicada.Mesh.SK_VH_Cicada'
	transformedAnimTree=AnimTree'VH_Cicada.Anims.AT_VH_Cicada'
	transformedPhysicsAsset=PhysicsAsset'VH_Cicada.Mesh.SK_VH_Cicada_Physics'
	bNotifyFallingHitWall=true
    InputClass=class'PGame.PPlayerInput'
	m_DistanciaAlCentro=12000
	m_ZoomMaxAcercar=12000
	m_ZoomMaxAlejar=19000
	m_stepZoom=600
	m_velocidad_rotacion=1.0
	//bGodMode=true
	m_tiempoCaidaSinMoverCamara=1.0
	m_minDistanciaCamaraCayendo = 150
}

