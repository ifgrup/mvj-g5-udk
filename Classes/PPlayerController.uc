/**
 * Controlador del personaje.
 * Controla todas las funciones de input del jugador en el juego para interactuar con el Pawn.
 * */
class PPlayerController extends GamePlayerController;

/**
 * Propiedades por defecto.
 * Configuramos que la cámara que controlará al jugador sea la nuestra (PPlayerCamera) 
 * */
defaultproperties
{
	//CameraClass = class'PGame.PPlayerCamera'
	bNotifyFallingHitWall=true
	
}

/**
 * Variables globales para el control de la posición y de la cámara.
 * */
var vector OldFloor;
var vector ViewX, ViewY, ViewZ;
var vector OldLocation;
var float DeltaTimeAccumulator;

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


/**
 * Función para actualizar la rotación del Pawn respecto a los inputs del jugador.
 * */
function UpdateRotation( float DeltaTime )
{
	local Rotator DeltaRot, newRotation, ViewRotation;
 
	ClientMessage("U1 " $ DeltaTime);
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
		`log("Adjusting roll to " $ NewRotation.Roll);
	}
	else
	{
		NewRotation.Roll = 0;
		`log("tus muelas " $ NewRotation.Roll);
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
		`log("Vamos al estado Spidering");
		ClientMessage("S1");
		GotoState('PlayerSpidering');
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
		local rotator ViewRotation, CamRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
		local vector CamOldX;
		local bool bSaltando;

		//ClientMessage("UPdate Estado spider" $ DeltaTime);
 
		//Mientras salta, Pawn.Base vale None
		//Si tiene que saltar, saltará en la vertical que YA tiene al estar caminando sobre el planeta
		//por lo que no hay que cambiar ninguna rotación
		if ( (Pawn.Base == None) || (Pawn.Floor == vect(0,0,0)) )
		{
			ClientMessage("Base "$Pawn.Base);
			ClientMessage("Floor "$Pawn.Floor);

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
		if ( (PlayerInput.aTurn != 0) || (PlayerInput.aLookUp != 0) )
		{
		// adjust Yaw based on aTurn
			if ( PlayerInput.aTurn != 0 )
			{
				ViewX = Normal(ViewX + 10 * ViewY * Sin(0.0005*DeltaTime*PlayerInput.aTurn));
			}
 
			// adjust CAMERA Pitch based on aLookUp
			//Este movimiento es SOLO para la cámara, no para el controlador, no queremos que se mueva el bicho sino la cámara
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


	//Devuelve dónde estará mirando el jugador,la cámara vamos ;)
	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{

		local vector  CamDirX, CamDirY,CamDirZ, CamDir,OffsetDirZ;	
		local vector  HitLocation, HitNormal,CamStart,tmpCamStart,tmpCamEnd;
		local Rotator rProta;
		local float dist,fs;

		super.GetPlayerViewPoint(out_Location, out_Rotation);
		if(Pawn != none)
		{
			Pawn.Mesh.SetOwnerNoSee(false);
			CamStart=Pawn.Location;
			rProta=PPawn(Pawn).Rotation; //Hacia donde mira el prota.La pasamos a coordenadas de mundo:
			//rProta.Pitch+=PlayerInput.aLookUp;
			GetAxes(rProta,CamDirX,CamDirY,CamDirz);
			//Tenemos el sist.coordenadas de hacia donde está mirando el prota,en coordenadas de mundo.
			//Como queremos estar siempre detrás, sólo nos interesa desplazar la cámara sólo en X, dejando la Y a cero

			CamDirX*=100*1/VSize(CamDirX); 
			
			//Calculamos desplazamiento up/down de la cámara. 
			//PlayerInput.aLookup no es absoluto, sino que depende sólo de la velocidad del movimiento del mouse.
			//Para controlar si la cámara está más arriba o abajo, vamos acumulando el valor,
			//modulándolo con sin 
			
			fs=Sin(0.0005*mUltimoLookup);
            mOffsetCamaraUpDown+=fs;

            //Limite de altura. Por debajo, será el suelo y las colisiones con él.
			if (abs(mOffsetCamaraUpDown) > 100)
			{
				mOffsetCamaraUpDown-=fs;
			}

			//A ese vector, hay que aplicarle la rotación por mouse up/down. Tenemos PlayerInput.aLookup en mUltimoLookup
			//mOffsetCamaraUpDown hay que aplicarlo a la altura del bicho, por tanto a su eje Z, que tenemos en camDirZ
			out_Location = (Pawn.Location -CamDirX)+(camDirZ*mOffsetCamaraUpDown);
			out_Rotation=Pawn.Rotation;

			//Hay que comprobar que no se ponga ningún objeto entre la cámara y el Pawn:
            //Lanzamos un 'rayo' desde la cámara hasta el bicho, y si encontramos algún obstáculo por medio, ponemos la cámara
			//donde está el obstáculo, para evitar tener esa pared en medio. Si hubiera más de dos obstáculos, el segundo nos seguiría
			//tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la cámara, y el primer obstáculo es el que 
			//utilizamos ;)
		
			if (Trace(HitLocation, HitNormal, out_Location, CamStart, false, vect(12,12,12),,TRACEFLAG_Blocking) != None)
			{
				//Hay contacto. Ponemos la cámara en el obstáculo
				out_Location=HitLocation;

				//Y ahora, como hemos hecho que la cámara se mueve más cerca del bicho, puede ser que la hayamos puesto
				//justo encima del bicho. En tal caso, veríamos cosas raras, por lo que comprobamos si estamos dentro del bicho, y
				//en tal caso, ocultamos el bicho para poder seguir viendo con normalidad.
				tmpCamStart=CamStart;
				tmpCamEnd=HitLocation;
				//Ponemos Z's a cero, que es como proyectar al suelo la posición de la cámara y del jugador
				tmpCamStart.Z=0;
				tmpCamEnd.Z=0;
				//Comprobamos si la distancia entre esas dos proyecciones, es menos que el radio de colisión + un cierto porcentaje
				//y también si la Z del punto de colisión, vamos, la nueva cámara, está dentro del cilindro de colisión
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
			}//Trace para ver si hay obstáculos
		}
	}//GetPlayerViewPoint






	/**
	 * Evento que se ejecuta cuando caes sobre algo al caminar normal (PlayerWalking).
	 * Dentro del estado spidering nunca pasará, ya que estás pegado a las superficies y no se puede caer.
	 * El saltar en este estado genera un evento HitWall dentro de PPawn en el estado PawnFalling. 
	 * */
	function bool NotifyLanded(vector HitNormal, Actor FloorActor)
	{
		`log("He caido sobre algo, NO despues de saltar");
		Pawn.SetPhysics(PHYS_Spider);
		Pawn.SetBase(FloorActor, HitNormal);

		return bUpdating;
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
				Pawn.DoJump(bUpdating);
			}

			/** Comprobamos cada vez que nos movemos si la última posición en la que dejamos un decal
			 * y la posición actual, es mayor a la mitad del tamaño del decal.
			 * Así nos aseguramos de que el próximo decal que pintemos, no se superpondrá al último decal
			 * pintado.
			 * */
			if(VSize(OldLocation - Pawn.Location) > (PGame(WorldInfo.Game).fDecalSize / 2))
			{
				OldLocation = Pawn.Location;
				WorldInfo.MyDecalManager.SpawnDecal
				(
					DecalMaterial'HU_Deck.Decals.M_Decal_GooLeak',	// UMaterialInstance used for this decal.
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

	/**
	 * Función para controlar el movimiento del personaje.
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
       
        //Giramos al pawn para que esté siempre perpendicular al suelo
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
	 * Inicialización del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		OldFloor = vect(0,0,1);

		GetAxes(Rotation,ViewX,ViewY,ViewZ);

		DoubleClickDir = DCLICK_None;
		Pawn.ShouldCrouch(false);
		bPressedJump = false;
 
		if (Pawn.Physics != PHYS_Falling)
		{
			Pawn.SetPhysics(PHYS_Spider);
		}
 
		GroundPitch = 0;
	}

	/**
	 * Fin del estado.
	 * */
    event EndState(Name NextStateName)
    {
        `log("unspider with roll" $ Rotation.Roll);
		`log("Nuevo estado " $NextStateName);
		SetPhysics(PHYS_Spider);
    }
}
