/**
 * Controlador del personaje.
 * Controla todas las funciones de input del jugador en el juego para interactuar con el Pawn.
 * */
class PPlayerController extends GamePlayerController;

/**
 * Propiedades por defecto.
 * Configuramos que la c�mara que controlar� al jugador sea la nuestra (PPlayerCamera) 
 * */




/**
 * Variables globales para el control de la posici�n y de la c�mara.
 * */
var vector OldFloor;
var vector ViewX, ViewY, ViewZ;
var vector OldLocation;
var float DeltaTimeAccumulator;

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
var Vector m_CentroPlaneta; //posicion del centro del Planeta. Puede que no deba ser 0,0,0
var float m_DistanciaAlCentro; //distancia que queremos mantener alrededor del planeta hasta su centro

//Variables para controlar la rotaci�n
var Quat m_CurrentQuadFlaying;
var Quat m_DesiredQuadFlaying;
var float m_velocidad_rotacion;
var Vector m_posicionPawn; //Para ir guardando la posicion del pawn mientras volamos, porque parece que no se actualiza???

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
		WorldInfo.Game.Broadcast(self,"Saliendo de PlayerWalking");
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
		local rotator ViewRotation, CamRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
		local vector CamOldX;
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
		if ( (PlayerInput.aTurn != 0) || (PlayerInput.aLookUp != 0) )
		{
		// adjust Yaw based on aTurn
			if ( PlayerInput.aTurn != 0 )
			{
				ViewX = Normal(ViewX + 10 * ViewY * Sin(0.0005*DeltaTime*PlayerInput.aTurn));
			}
 
			// adjust CAMERA Pitch based on aLookUp
			//Este movimiento es SOLO para la c�mara, no para el controlador, no queremos que se mueva el bicho sino la c�mara
			if ( PlayerInput.aLookUp != 0 )
			{
				CamViewX=ViewX;
				CamViewY=ViewY;
				CamViewZ=ViewZ;
				CamOldX = CamViewX;
				
				CamViewX = Normal(CamViewX + 10 * CamViewZ * Sin(0.0005*DeltaTime*PlayerInput.aLookUp));
				CamViewZ = Normal(CamViewX Cross CamViewY);
 
				// bound max pitch
				if ( (CamViewZ dot MyFloor) < 0.1   )
				{
					CamViewX = CamOldX;
				}
	
				//VMH:La Y no cambia al rotar no?....CamViewY = Normal(MyFloor cross CamViewX);
				CamRotation=OrthoRotation(CamViewX,CamViewY,CamViewZ);
			}

			// calculate new Y axis
			ViewY = Normal(MyFloor cross ViewX);
		}

		ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
		SetRotation(ViewRotation);
		if(Pawn != None)
		{
			Pawn.SetRotation(ViewRotation);
			//Pawn.CylinderComponent.SetRBRotation(ViewRotation);
		}		
		//Pawn.CollisionComponent.Rotation=ViewRotation;
		//Pawn.CollisionComponent.SetHidden(False);
		//Pawn.mesh.SetRotation(ViewRotation);


		//		 if ( PlayerInput.aLookUp != 0 )
		//            PlayerCamera.SetRotation(camRotation);
			  
 
		//SET PAWN ROTATION WITH RESPECT TO FLOOR NORMALS HERE
		// Does not work anymore.. will need some debugging
		//Pawn.mesh.SkeletalMesh.Rotation = Pawn.Rotation;
	}


	//Devuelve d�nde estar� mirando el jugador,la c�mara vamos ;)
    simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
    {

        local vector  CamDirX, CamDirY,CamDirZ;    
        local vector  HitLocation, HitNormal,CamStart,tmpCamStart,tmpCamEnd;
        local Rotator rProta;
        local float dist,fs;
		local float despx,despz;
		local float lPitch;

        super.GetPlayerViewPoint(out_Location, out_Rotation);
        if(Pawn != none)
        {
            Pawn.Mesh.SetOwnerNoSee(false);
            CamStart=Pawn.Location;
            rProta=PPawn(Pawn).Rotation; //Hacia donde mira el prota.La pasamos a coordenadas de mundo:
            //rProta.Pitch+=PlayerInput.aLookUp;
            GetAxes(rProta,CamDirX,CamDirY,CamDirz);
            //Tenemos el sist.coordenadas de hacia donde est� mirando el prota,en coordenadas de mundo.
            //Como queremos estar siempre detr�s, s�lo nos interesa desplazar la c�mara s�lo en X, dejando la Y a cero

            //CamDirX*=500*1/VSize(CamDirX); 


            //Calculamos desplazamiento up/down de la c�mara. 
            //PlayerInput.aLookup no es absoluto, sino que depende s�lo de la velocidad del movimiento del mouse.
            //Para controlar si la c�mara est� m�s arriba o abajo, vamos acumulando el valor,
            //modul�ndolo con sin 
            
            fs=Sin(0.001*mUltimoLookup);
            
            mOffsetCamaraUpDown+=fs;

            //Limite de altura. Por debajo, ser� el suelo y las colisiones con �l.
            /*
             * if (abs(mOffsetCamaraUpDown) > 90)
            {
                mOffsetCamaraUpDown-=fs;
				`log("Max offset Z");
            }
            */

			//`log("antes clamp " @mOffsetCamaraUpDown @fs @mUltimoLookup);
			//mOffsetCamaraUpDown=clamp(mOffsetCamaraUpDown,15.0,90);
			if(mOffsetCamaraUpDown<15.0)
				mOffsetCamaraUpDown=15.0;
			
			if(mOffsetCamaraUpDown>65.0)
				mOffsetCamaraUpDown=65.0;
			
            //A ese vector, hay que aplicarle la rotaci�n por mouse up/down. 
            //Tenemos PlayerInput.aLookup guardado en mUltimoLookup porque desde aqu� no es accesible (siempre dice ser 0???)
    		//Debemos intentar mantener la distancia de la c�mara al jugador.
            //En X debemos desplazar en -CamDirX, y en Z, +camDirZ.
			//Consideramos mOffsetCamaraUpDown como el �ngulo de inclinaci�n de la c�mara
			despX=300*cos(mOffsetCamaraUpDown*degtorad);
			despZ=300*sin(mOffsetCamaraUpDown*degtorad);
			//`Log("" @500*sin(mOffsetCamaraUpDown*degtorad));
			out_Location = (Pawn.Location -CamDirX*despX)+(camDirZ*despZ);
			out_Rotation=Pawn.Rotation;
			//Aplicamos el �ngulo de elevaci�n al pitch de la orientaci�n del pawn 
			
			lPitch=(65535/4)*mOffsetCamaraUpDown/90;
			out_Rotation.Pitch-= lPitch;

			//Hay que comprobar que no se ponga ning�n objeto entre la c�mara y el Pawn:
            //Lanzamos un 'rayo' desde la c�mara hasta el bicho, y si encontramos alg�n obst�culo por medio, ponemos la c�mara
            //donde est� el obst�culo, para evitar tener esa pared en medio. Si hubiera m�s de dos obst�culos, el segundo nos seguir�a
            //tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la c�mara, y el primer obst�culo es el que 
            //utilizamos ;)
        
            if (Trace(HitLocation, HitNormal, camStart,out_Location, false, vect(12,12,12),,TRACEFLAG_Blocking) != None)
            {
                //Hay contacto. Ponemos la c�mara en el obst�culo
                out_Location=HitLocation;

                //Y ahora, como hemos hecho que la c�mara se mueve m�s cerca del bicho, puede ser que la hayamos puesto
                //justo encima del bicho. En tal caso, ver�amos cosas raras, por lo que comprobamos si estamos dentro del bicho, y
                //en tal caso, ocultamos el bicho para poder seguir viendo con normalidad.
                tmpCamStart=CamStart;
                tmpCamEnd=HitLocation;
                //Ponemos Z's a cero, que es como proyectar al suelo la posici�n de la c�mara y del jugador
                tmpCamStart.Z=0;
                tmpCamEnd.Z=0;
                //Comprobamos si la distancia entre esas dos proyecciones, es menos que el radio de colisi�n + un cierto porcentaje
                //y tambi�n si la Z del punto de colisi�n, vamos, la nueva c�mara, est� dentro del cilindro de colisi�n
                dist=VSize(tmpCamEnd-tmpCamStart);
                //`Log(dist);
                if ( (dist < Pawn.GetCollisionRadius()*2.0) && 
                      (HitLocation.Z<Pawn.Location.Z+Pawn.CylinderComponent.CollisionHeight) &&
                      (HitLocation.Z>Pawn.Location.Z-Pawn.CylinderComponent.CollisionHeight))
                {
                    //Estamos dentro del bicho. Ocultamos su mesh
                    Pawn.Mesh.SetHidden(True);
                }
                else
                {
                    Pawn.Mesh.SetHidden(False);
                }
            }//Trace para ver si hay obst�culos
        }
    }//GetPlayerViewPoint



	/**
	 * Evento que se ejecuta cuando caes sobre algo al caminar normal (PlayerWalking).
	 * Dentro del estado spidering nunca pasar�, ya que est�s pegado a las superficies y no se puede caer.
	 * El saltar en este estado genera un evento HitWall dentro de PPawn en el estado PawnFalling. 
	 * */
	function bool NotifyLanded(vector HitNormal, Actor FloorActor)
	{
		`log("He caido sobre algo, NO despues de saltar");
		Pawn.SetPhysics(PHYS_None);
		Pawn.SetPhysics(PHYS_Spider);
		Pawn.SetBase(FloorActor, HitNormal);

		return bUpdating;
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
				Pawn.DoJump(bUpdating);
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
	 * Funci�n para controlar el movimiento del personaje.
	 * */
    function PlayerMove( float DeltaTime )
    {
        local vector NewAccel;
        local eDoubleClickDir DoubleClickMove;
        local rotator OldRotation, ViewRotation;
        local bool  bSaveJump;

	
		DeltaTimeAccumulator += 0.001f;
        GroundPitch = 0;
        ViewRotation = Rotation;
		
        // Update rotation.
        SetRotation(ViewRotation);
        OldRotation = Rotation;
       
        //Giramos al pawn para que est� siempre perpendicular al suelo
        UpdateRotation(DeltaTime);
 
        // Update acceleration.
        NewAccel = PlayerInput.aForward*Normal(ViewX - OldFloor * (OldFloor Dot ViewX)) + PlayerInput.aStrafe*ViewY;
 
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
		
    }

	/**
	 * Inicializaci�n del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		OldFloor = vect(0,0,1);
		`Log("__________________________BEGIN STATE PLAYERCONTROLLER.PLAYERSPIDERING_____________________");
		GetAxes(Rotation,ViewX,ViewY,ViewZ);

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
		WorldInfo.Game.Broadcast(self,"Saliendo de PlayerSpidering");
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
		Centro2Pawn=Normal(pPosition-m_CentroPlaneta);
		pPosition=m_CentroPlaneta+Centro2Pawn*m_DistanciaAlCentro;
		PPawn(Pawn).SetLocation(pPosition);
		vAlCentro=m_CentroPlaneta-Pawn.Location; //vector de direcci�n del prota.
		PPawn(Pawn).SetRotation(Rotator(vAlCentro));
		SetRotation(Rotator(vAlCentro));
		PPawn(Pawn).GotoState('PawnFlaying');
		SetPhysics(PHYS_None); 
		//QUAT inicial sobre el que iremos aplicando la rotaci�n muhahahaha
		m_CurrentQuadFlaying=QuatFromRotator(Rotator(vAlCentro));
		m_DesiredQuadFlaying= m_CurrentQuadFlaying;
		DrawDebugCone(m_CentroPlaneta,pPosition-m_CentroPlaneta,m_DistanciaAlCentro,0.01,0.01,200,MakeColor(255,0,0,1),true);
		
	}

	event EndState(Name NextState)
	{
		local Vector HitLocation,HitNormal;
		local Rotator rPawn;

		`Log("PlayerController yendo al estado "@NextState);
		
		if(NextState=='PlayerWalking')
		{
			//Debemos calcular la coordenada de suelo en la que poner al Pawn
			Trace(HitLocation,HitNormal,m_CentroPlaneta,m_posicionPawn,false);
			if (HitLocation!=vect(0,0,0))
			{
				`Log("____________________Hit al planeta");
				PPawn(Pawn).SetPhysics(PHYS_None); 
				SetPhysics(PHYS_None); 
				PPawn(Pawn).SetLocation(HitLocation);
				rPawn=Rotator(-HitNormal);
				rPawn.Pitch+=65535/4; //90� arriba, igual que con las torretas
				PPawn(Pawn).SetRotation(rPawn);
				SetLocation(HitLocation);
				SetRotation(rPawn);
				PPawn(Pawn).GotoState('');
				SetPhysics(PHYS_Spider); // "Glue" back to surface
				PPawn(Pawn).SetPhysics(PHYS_Spider);
				PGame(WorldInfo.Game).bEarthNotFlying =true;
			}
			else
			{
				`Log("NOHit al planeta");
			}

		}


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
		vDesdeCentro=m_CentroPlaneta- (X*m_DistanciaAlCentro);
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

		CalculaPosicionPorQuaternion(m_CurrentQuadFlaying,posCurrent);
		CalculaPosicionPorQuaternion(m_DesiredQuadFlaying,posDesired);
		dist=VSize(posCurrent-posDesired);
		if(dist>10)
			m_CurrentQuadFlaying=QuatSlerp(m_CurrentQuadFlaying,m_DesiredQuadFlaying,DeltaTime);
		
		

		super.PlayerTick(DeltaTime);
			
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

				case ScrollWheelUp:
					pHUD.PendingScrollUp = true;
					break;

				case ScrollWheelDown:
					pHUD.PendingScrollDown = true;
					break;

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





exec function vuela()
{
	local bool bTierraAire;
	
	PGame(WorldInfo.Game).bEarthNotFlying =! PGame(WorldInfo.Game).bEarthNotFlying;
	bTierraAire=PGame(WorldInfo.Game).bEarthNotFlying;
	if(bTierraAire)
		GotoState('PlayerWalking');
	else
		GotoState('PlayerFlaying');

}

// Called when the left mouse button is pressed
exec function LeftMousePressed()
{
	if(PGame(WorldInfo.Game).bEarthNotFlying)
		super.StartFire();
	else
		HandleMouseInput(LeftMouseButton, IE_Pressed);
}

// Called when the left mouse button is released
exec function LeftMouseReleased()
{
	if(PGame(WorldInfo.Game).bEarthNotFlying)
		super.StopFire();
	else
		HandleMouseInput(LeftMouseButton, IE_Released);
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
	//CameraClass = class'PGame.PPlayerCamera'
	bNotifyFallingHitWall=true
    m_CentroPlaneta=(X=528,Y=144,Z=8752)
	InputClass=class'PGame.PPlayerInput'
	m_DistanciaAlCentro=8000
	m_velocidad_rotacion=1.0

}

