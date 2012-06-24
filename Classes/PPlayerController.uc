/**
 * Controlador del personaje.
 * Controla todas las funciones de input del jugador en el juego para interactuar con el Pawn.
 * */
class PPlayerController extends GamePlayerController;

/**
 * Variables globales para el control de la posici�n y de la c�mara.
 * */
var vector OldFloor;
var vector ViewX, ViewY, ViewZ;
var vector OldLocation;

var float mOffsetCamaraUpDown; //Para ir acumulando la altura de la c�mara
var float mUltimoLookup; //para guardar el ultimo aLookUp de PlayerInput, no accesible desde el evento GetPlayerViewPoint

/**
 * Para calcular el Pitch de la c�mara al mover el rat�n.
 * */
var vector CamViewX, CamViewY, CamViewZ;

/**
 * �ltimo vector normal de "suelo" antes de saltar.
 * */
var vector mUltimoFloorAntesSalto;
var float m_DistanciaAlCentro; //distancia que queremos mantener alrededor del planeta hasta su centro
var float m_ZoomMaxAcercar;
var float m_ZoomMaxAlejar;
var float m_DistanciaAlCentro_desiredZoom; //Destino deseable de la distancia tras el zoom con la rueda del mouse
var float m_distZoomActual;// Distancia actual que debe recorrerse con la rueda. Se actualiza a cada nuevo evento
var int m_stepZoom ;//unidades en las que se acerca o aleja la distancia con la rueda del mouse
//Variables para controlar la rotaci�n
var Quat m_CurrentQuadFlaying;
var Quat m_DesiredQuadFlaying;
var float m_velocidad_rotacion;
var Vector m_posicionPawn; //Para ir guardando la posicion del pawn mientras volamos, porque parece que no se actualiza???
var bool m_vCaidaMax; //al caer al planeta, hemos llegadoa velocidad m�xima de caida

var UberPostProcessEffect PPE;


//Control de caida PlayerFallingSky
var float m_tiempoCayendo;
var float m_acercandoCamaraCayendo;
var float m_aceleracionCaidaLibre;
var vector m_PosInicialCamaraCayendo;
var bool m_inicioAcercamiento;
var float m_tiempoCaidaSinMoverCamara;
var bool m_cambioEstadoPropulsores;

/**
 *Gesti�n del rat�n RR
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
 * Funci�n para actualizar la rotaci�n del Pawn respecto a los inputs del jugador.
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
 * Estado b�sico por defecto del Pawn.
 * Nada mas entrar en este estado, le decimos que active el estado Spidering.
 * */
state PlayerWalking
{
	event BeginState(Name PreviousStateName)
	{
		ClientMessage("Vamos al estado Spidering");
		`Log("******************************Inicio de PlayerControler en PlayerWalking********************");
		GotoState('PlayerSpidering');
	}
	
	event EndState(Name NextStateName)
	{
		//DBG WorldInfo.Game.Broadcast(self,"Saliendo de PlayerWalking");
	}
}

/**
 * Estado de spidering.
 * Sobreescribimos la f�sica del jugador para que se quede enganchado a cualquier superficie
 * del mundo. Se desactiva la gravedad por defecto del Pawn.
 * */
state PlayerSpidering
{
	ignores SeePlayer, HearNoise, Bump;

    /**
     * Actualizamos la rotaci�n bas�ndonos en el Floor en el que estamos actualmente.
     * */
	function UpdateRotation(float DeltaTime)
	{
		local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
		local bool bSaltando;

		//ClientMessage("UPdate Estado spider" $ DeltaTime);
 
		//Mientras salta, Pawn.Base vale None
		//Si tiene que saltar, saltar� en la vertical que YA tiene al estar caminando sobre el planeta
		//por lo que no hay que cambiar ninguna rotaci�n
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
				OldFwdDir = CrossDir cross OldFloor; //El hacia delante que ten�a antes
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

		//Ahora giro de la c�mara.
		//Al girar por aTurn,s�lo nos afectar� la rotaci�n sobre el eje Z.
		//Por tanto, la Z quedar� igual, la X es la que rotar�, y la Y ser� el producto cartesiano de la nueva X por la Z que ya tenemos
		if ( (PlayerInput.aTurn != 0))
		{
		   // adjust Yaw based on aTurn
			if ( PlayerInput.aTurn != 0 )
			{
				ViewX = Normal(ViewX + 10 * ViewY * Sin(0.0005*DeltaTime*PlayerInput.aTurn));
			}
 			// calculate new Y axis
			ViewY = Normal(MyFloor cross ViewX);
 		}

		ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
		SetRotation(ViewRotation);
		if(Pawn != None)
		{
			Pawn.SetRotation(ViewRotation);
		}		
	}

	//Funcion que devuelve en el booleano parametro si se debe hacer rotacion up/down de la camara.
	//s�lo ser� as� si el cursor est� por encima del l�mite horizontal definido para ese movimiento
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
	 * Dentro del estado spidering nunca pasar�, ya que est�s pegado a las superficies y no se puede caer.
	 * El saltar en este estado genera un evento HitWall dentro de PPawn en el estado PawnFalling. 
	 * */
	
	
    function bool NotifyLanded(vector HitNormal, Actor FloorActor)
	{
		`log("He caido sobre algo, NO despues de saltar.Es inicio de juego.");
		if (PPawn(pawn)!=None)
		{
			Pawn.SetPhysics(PHYS_None);
			Pawn.SetPhysics(PHYS_Spider);
			Pawn.SetBase(FloorActor, HitNormal);
			return bUpdating;
		}

	}

	/**
	 * Comprobamos si cambiamos de Volumen de f�sicas.
	 * Ahora mismo s�lo comprobamos si estamos dentro de agua, para no engancharnos a nada y poder nadar 
	 * */
	event NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume )
		{
			GotoState(Pawn.WaterMovementState);
		}
	}
 
	/**
	 * Funci�n para procesar los movimientos generados en PlayerMove.
	 * Actualmente �nicamente controlamos:
	 * - Aceleraci�n del personaje.
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

			/** Comprobamos cada vez que nos movemos si la �ltima posici�n en la que dejamos un decal
			 * y la posici�n actual, es mayor a la mitad del tama�o del decal.
			 * As� nos aseguramos de que el pr�ximo decal que pintemos, no se superpondr� al �ltimo decal
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
		}
    }



	/**
	 * bAlgoDelante valdr� !=0 si hay algo delante con lo que colisiona, impidiendo el avance
	 * valdr� false si puede seguir palante sin problemas
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
		pFinTrace=PPawn(Pawn).Location+Normal(direccion)*20; //Del obst�culo hacia nosotros
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
			//Raro, como m�nimo tendr�a que colisionar con el propio pawn
			bAlgoDelante=0;
			return;
		}
		else
		{
			
			if (None!=aTrace1)
			{
				
				 if (aTrace1.Name!=name("StaticMeshActor_0") && aTrace1.Name!=name("StaticMeshActor_1"))
				 {
					`log("Nombre impacto trace "@aTrace1.Name);
					bAlgoDelante=1;
					return;
				 }
			}
			if (None!=aTrace2)
			{
				
				 if (aTrace2.Name!=name("StaticMeshActor_0") && aTrace2.Name!=name("StaticMeshActor_1") )
				 {
					`log("Nombre impacto trace2 "@aTrace2.Name);
					bAlgoDelante=1;
					return;
				 }

			}

			if (None!=aTrace3)
			{
				
				 if (aTrace3.Name!=name("StaticMeshActor_0") && aTrace3.Name!=name("StaticMeshActor_1") )
				 {
					`log("Nombre impacto trace3 "@aTrace3.Name);
					bAlgoDelante=1;
					return;
				 }

			}

		}
		bAlgoDelante=0;
		return;
	}
    

	/**
	 * Funci�n para controlar el movimiento del personaje.
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
       
        //Giramos al pawn para que est� siempre perpendicular al suelo
        UpdateRotation(DeltaTime);

        // Update acceleration.

        NewAccel = PlayerInput.aForward*Normal(ViewX - OldFloor * (OldFloor Dot ViewX)) + PlayerInput.aStrafe*ViewY;
 
		//Comprobamos si al aplicar el movimiento, chocar�a contra un objeto, y en tal caso, para no 'spidearlo', pues
		//no llamamos a ProcessMove, o ponemos el vector NewAccel a (0,0,0) para que no se mueva
       
        CheckDelantePawn(NewAccel,bAlgoDelante);
		if (bAlgoDelante!=0)
		{
			`log("tiene algo delante. No seguimos el movimiento");
			NewAccel=vect(0,0,0);
		}
       
		
		if (PPawn(pawn).GetStateName()=='PawnFalling' ) //&& PPAwn(pawn).bSaltoAcabado)
		{
			//`log("Estas saltando, no te muevas!");
			NewAccel=vect(0,0,0);
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
	 * Inicializaci�n del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		`Log("__________________________BEGIN STATE PLAYERCONTROLLER.PLAYERSPIDERING_____________________");
		if (PreviousStateName!='PlayerRecienCaido' )
		{
			OldFloor = vect(0,0,1);
			GetAxes(Rotation,ViewX,ViewY,ViewZ);
		}
		else
		{
			//�APA
			//Parece que hay veces en las que el BaseChanged del Pawn no se ejecuta o se ejecuta cuando le sale de los
			//cataplines, y se pone el PC en Spider antes de que el Pawn est� en el suelo.
			//Por tanto, el floor es 0,0,0, y el OldFloor que se rellena aqu� es 0,0,0, y eso provoca que
			//luego nunca se cambie, y el UpdateRotation no cambie nunca la rotaci�n. Maravilloso.
			//Lo controlamos poniendo el vector en 0,0,1. Se producir� un efecto raro de cojones, pero habr� rotaci�n
			//al tick siguiente y se pondr� bien en principio...
			if(PPawn(Pawn).Floor==vect(0,0,0))
			{
				`log("KAGADA");
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
		mOffsetCamaraUpDown=15.0; //angulo inicial de up/down de la c�mara
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
	 * Inicializaci�n del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		/*Debemos poner al Pawn en el cielo, hacerlo invisible, y poner las f�sicas en vuelo*/
		local Vector pPosition,vAlCentro;
		local vector Centro2Pawn; //del centro del planeta, a donde est� el pawn

		//Colocamos al Pawn volando, prolongando su Z actual:
        `log("PC Flaying 2");

		pPosition=PPawn(Pawn).Location;
		Centro2Pawn=Normal(pPosition-PGame(WorldInfo.Game).GetCentroPlaneta());
		pPosition=PGame(WorldInfo.Game).GetCentroPlaneta()+Centro2Pawn*m_DistanciaAlCentro;
		PPawn(Pawn).SetLocation(pPosition);
		vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Pawn.Location; //vector de direcci�n del prota.
		PPawn(Pawn).SetRotation(Rotator(vAlCentro));
		SetRotation(Rotator(vAlCentro));
		PPawn(Pawn).GotoState('PawnFlaying');
		SetPhysics(PHYS_None); 
		//QUAT inicial sobre el que iremos aplicando la rotaci�n muhahahaha
		m_CurrentQuadFlaying=QuatFromRotator(Rotator(vAlCentro));
		m_DesiredQuadFlaying= m_CurrentQuadFlaying;
		//DrawDebugCone(m_CentroPlaneta,pPosition-m_CentroPlaneta,m_DistanciaAlCentro,0.01,0.01,200,MakeColor(255,0,0,1),true);
		
		m_DistanciaAlCentro_desiredZoom=m_DistanciaAlCentro;
	}

	event EndState(Name NextState)
	{
		//No hacemos nada en principio.Para volver a bajar al planeta, vamos al estado PlayerFallingSky
		`Log("PlayerController estaba en PlayerFlaying, yendo al estado "@NextState);
	
	}



	function UpdateRotation(float DeltaTime)
	{
        //Queremos asegurar que no hace nada, as� que la dejamos en blanco y no ejecutamos nada de super 
		
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
	
		//m_QuadFlaying est� actualizada con el Quad que toca. Obtengo su rotator, y la
		//X me dar� la direcci�n al centro del planeta. Mantengo cte la distancia al centro en dicho X,
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
			qYaw=QuatFromAxisAndAngle(Z,-iLR); //Negado por la direcci�n de izda/dcha va al rev�s
			m_DesiredQuadFlaying=QuatProduct(qYaw,m_DesiredQuadFlaying);
		}
        
		//Aqui ya tengo actualizado el Quaternon deseado, al que quiero llegar.
		//En el tick lo interpolamos a partir del actual, y la posici�n la calculamos siempre a partir
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
        
		if(diff < 1) //para evitar hist�resis, just in case
		{
			return;
		}

		prop=(diff/m_distZoomActual)*90; //ir� de 90 a 0
		sprop=abs(sin(prop*DegToRad));
			
		decel=sprop*delta*1000*(m_distZoomActual/m_stepZoom); //Ponderamos en funcion de la distancia actual respecto al step
		
        if (m_DistanciaAlCentro < m_DistanciaAlCentro_desiredZoom)
        {
			m_DistanciaAlCentro+=decel;
			//`log("Alejando "@decel);
        }
		else
		{	
			m_DistanciaAlCentro-=decel;
			//`log("Acercando "@decel);
		}

	}

}//State PlayerFlaying



state PlayerFallingSky
{
	ignores SeePlayer, HearNoise;//, Bump;
  
	/**
	 * Inicializaci�n del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		/*Simplemente, vamos cayendo, hasta que el Pawn nos avise de que estamos en el suelo */
		local Vector pPosition,vAlCentro;
        local PPawn elPaun;

		
        `log("PC Falling Sky");
		elPaun=PPawn(pawn);

		
		pPosition=elPaun.Location;
		m_PosInicialCamaraCayendo=pPosition;

		vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition; //vector de direcci�n del prota.
		
		elPaun.Velocity=Normal(vAlCentro)*1000;//*10000;
		elPaun.Acceleration=pawn.Velocity*50000;

		//ponemos al pawn 300 unidades m�s abajo, porque pondremos la c�mara 300 unidades m�s arriba para que se le vea caer
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
	}

	event PlayerTick(float DeltaTime)
	{
		super.PlayerTick(DeltaTime);

		//Primero control de la c�mara
		m_tiempoCayendo+=DeltaTime;
		if (m_tiempoCayendo > m_tiempoCaidaSinMoverCamara)
		{
			//Guardamos la distancia actual de la camara hasta el pawn, para ir decrement�ndola
			if(!m_inicioAcercamiento)
			{
				m_inicioAcercamiento=true;
				m_acercandoCamaraCayendo=vsize(PPawn(Pawn).Location-m_PosInicialCamaraCayendo);
			}
			m_acercandoCamaraCayendo-=800*DeltaTime; //La vamos decrementando
			m_acercandoCamaraCayendo=FClamp(m_acercandoCamaraCayendo,300,30000);
			`log("La distancia es "@m_acercandoCamaraCayendo);

			//Update de la aceleraci�n
			m_aceleracionCaidaLibre*=1+DeltaTime/5;
		}

		//Propulsores apagados un segundo (Ca�da libre), y luego se encienden
		if (m_tiempoCayendo>1 && !m_cambioEstadoPropulsores)
		{
			ppawn(pawn).EstadoPropulsores(true); 
			m_cambioEstadoPropulsores=true;
		}

	}

	event EndState(Name NextState)
	{
		`Log("PlayerController yendo al estado "@NextState);
	}		

	function UpdateRotation(float DeltaTime)
	{
        //Queremos asegurar que no hace nada, as� que la dejamos en blanco y no ejecutamos nada de super 
	}

	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Vector alPlaneta;
		local Vector pPosition;
		
		pPosition=PPawn(pawn).Location;
		alPlaneta=PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition;
		
		//Primero estamos medio segundo sin mover la c�mara, viendo la ca�da libre
		if (m_tiempoCayendo < m_tiempoCaidaSinMoverCamara)
		{
			out_Location=m_PosInicialCamaraCayendo;
		}
		else
		{
			//Cuando pasa medio segundo, acercamos la c�mara r�pidamente hasta una distancia m�nima del pawn, 
			//en la que nos mantendremos hasta que el pawn se esto�e contra el suelo
			/////out_Location=PPawn(pawn).Location-Normal(alPlaneta)*300; //Para que la c�mara est� por encima del pawn y se vea
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

		super.PlayerMove(aDeltaTime);

		pPosition=PPawn(pawn).Location;
		alPlaneta=PGame(WorldInfo.Game).GetCentroPlaneta()-pPosition;
		//Caida libre hasta el suelo
		//controlamos la velocidad m�xima
	
		step=Normal(alPlaneta)*aDeltaTime*800*m_aceleracionCaidaLibre;
		PPawn(pawn).SetLocation(pPosition+step);

		ProcessMove(aDeltaTime,PPawn(Pawn).Acceleration,DCLICK_None ,Rotator(vect(0,0,0)));
		
	}
}

/************************************************************************************************************************/
state PlayerRecienCaido
{
	//Todo vac�o, no queremos que haga nada
	event BeginState(Name prevstate)
	{
		`log("asdkasda");
	}

	event EndState(Name nextstate)
	{
		`log("__asdkasda");
	}

}

/**
 * Eventos de Rat�n RR
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
	
	PGame(WorldInfo.Game).bEarthNotFlying =! PGame(WorldInfo.Game).bEarthNotFlying;
	bTierraAire=PGame(WorldInfo.Game).bEarthNotFlying;
	
	if(bTierraAire)
		GotoState('PlayerFallingSky');
	else
		GotoState('PlayerFlaying');


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
}

