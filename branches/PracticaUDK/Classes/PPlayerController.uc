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
		local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
		local bool bSaltando;

		//ClientMessage("UPdate Estado spider" $ DeltaTime);
 
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

	//Devuelve dónde estará mirando el jugador,la cámara vamos ;)
    simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
    {

        local vector  CamDirX, CamDirY,CamDirZ;    
        local vector  HitLocation, HitNormal,CamStart,tmpCamStart,tmpCamEnd;
        local Rotator rProta;
        local float dist,fs;
		local float despx,despz;
		local quat  qpitchZ,qCamZ;
		local vector qX,qY,qZ;
		local bool bCamaraUPDown;

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

            //Calculamos desplazamiento up/down de la cámara. 
            //PlayerInput.aLookup no es absoluto, sino que depende sólo de la velocidad del movimiento del mouse.
            //Para controlar si la cámara está más arriba o abajo, vamos acumulando el valor,
            //modulándolo con sin 
            
            
			
    		//Debemos intentar mantener la distancia de la cámara al jugador.
            //En X debemos desplazar en -CamDirX, y en Z, +camDirZ.
			//Consideramos mOffsetCamaraUpDown como el ángulo de inclinación de la cámara
			despX=350;//300*sin(mOffsetCamaraUpDown*degtorad);
			
	
			
			//DrawDebugCone(pawn.Location,vector(out_rotation),100,0.1,0.1,50,MakeColor(255,0,0));
			//La rotación la debemos modificar en up/down, rotando sobre el eje Y actual del Rotator
			//para ello, benditos quaternions:
			bCamaraUPDown=DebeHacerseUPDownCamara();
			if (bCamaraUPDown)
			{
				fs=Sin(0.001*mUltimoLookup); //utilizamos mUltimoLookup porque aquí vale cero PlayerInput, parece que sólo puede leerse 
										  //en PlayerMove o ProcessMove ???
            
				mOffsetCamaraUpDown+=fs;

				//Control de inclinación up/down máximo de la cámara. Con Clamp me hacía cosas raras, así que if de toda la vida
				if(mOffsetCamaraUpDown<15.0)
					mOffsetCamaraUpDown=15.0;
			
				if(mOffsetCamaraUpDown>65.0)
					mOffsetCamaraUpDown=65.0;
			}
			else
			{
				//si hemos bajado rápido, puede que el salto de ángulo sea grande. Por eso vamos decrementando el ángulo
				//hasta que lleguemos a 15.0
				if (mOffsetCamaraUpDown >15.0)
					mOffsetCamaraUpDown-=0.05;
				else
					mOffsetCamaraUpDown=15.0;
			}
		    //`log ("moffset " @mOffsetCamaraUpDown);
			qcamZ=QuatFromRotator(pawn.Rotation);
			GetAxes(Pawn.Rotation,qX,qY,qZ);
			qPitchZ=QuatFromAxisAndAngle(qY,mOffsetCamaraUpDown*DegToRad);
			qcamZ=QuatProduct(qPitchZ,qcamZ);
			out_rotation=QuatToRotator(qcamZ);
			despZ=600*sin(mOffsetCamaraUpDown*degtorad);

			//La posición de la cámara la tenemos calculada con sin/cos del ángulo, considerando 300 como distancia a mantener
			out_Location = Pawn.Location -(CamDirX*despX)+(camDirZ*despZ);
			
			//DrawDebugCone(pawn.Location,vector(out_rotation),100,0.1,0.1,50,MakeColor(0,0,255));
	

			//Hay que comprobar que no se ponga ningún objeto entre la cámara y el Pawn:
            //Lanzamos un 'rayo' desde la cámara hasta el bicho, y si encontramos algún obstáculo por medio, ponemos la cámara
            //donde está el obstáculo, para evitar tener esa pared en medio. Si hubiera más de dos obstáculos, el segundo nos seguiría
            //tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la cámara, y el primer obstáculo es el que 
            //utilizamos ;)
        
            if (Trace(HitLocation, HitNormal, out_Location,Pawn.Location, false, vect(12,12,12),,TRACEFLAG_Blocking) != None)
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
 
		//Comprobamos si al aplicar el movimiento, chocaría contra un objeto, y en tal caso, para no 'spidearlo', pues
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
	 * Inicialización del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		`Log("__________________________BEGIN STATE PLAYERCONTROLLER.PLAYERSPIDERING_____________________");
		if (PreviousStateName!='PlayerFallingSky')
		{
			OldFloor = vect(0,0,1);
			GetAxes(Rotation,ViewX,ViewY,ViewZ);
		}
		else
		{
			OldFloor=PPawn(Pawn).Floor;
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

		//Colocamos al Pawn volando, prolongando su Z actual:
        `log("PC Flaying 2");

		pPosition=PPawn(Pawn).Location;
		Centro2Pawn=Normal(pPosition-PGame(WorldInfo.Game).GetCentroPlaneta());
		pPosition=PGame(WorldInfo.Game).GetCentroPlaneta()+Centro2Pawn*m_DistanciaAlCentro;
		PPawn(Pawn).SetLocation(pPosition);
		vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Pawn.Location; //vector de dirección del prota.
		PPawn(Pawn).SetRotation(Rotator(vAlCentro));
		SetRotation(Rotator(vAlCentro));
		PPawn(Pawn).GotoState('PawnFlaying');
		SetPhysics(PHYS_None); 
		//QUAT inicial sobre el que iremos aplicando la rotación muhahahaha
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
	ignores SeePlayer, HearNoise, Bump;
  
	/**
	 * Inicialización del estado.
	 * */
	event BeginState(Name PreviousStateName)
	{
		/*Simplemente, vamos cayendo, hasta que el Pawn nos avise de que estamos en el suelo */
		local Vector pPosition,vAlCentro;

        `log("PC Falling Sky");

		pPosition=PPawn(Pawn).Location;
		vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta() - pPosition; //vector de dirección del prota.
		pawn.Velocity=Normal(vAlCentro)*900;
		pawn.Acceleration=pawn.Velocity*500;

		//ponemos al pawn 300 unidades más abajo, porque pondremos la cámara 300 unidades más arriba para que se le vea caer
		PPawn(pawn).SetLocation(pPosition+Normal(vAlCentro)*300);
		PPawn(Pawn).GotoState('PawnFallingSky');
		m_vCaidaMax=false;

	}

	event EndState(Name NextState)
	{
		`Log("PlayerController yendo al estado "@NextState);
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
		
		out_Location=PPawn(pawn).Location-Normal(alPlaneta)*300; //Para que la cámara esté por encima del pawn y se vea
		out_Rotation=PPawn(pawn).Rotation; //No la cambiamos en toda la bajada

	}
    
	/*
	function PlayerMove(float aDeltaTime)
	{
		//vamos acercando el pawn al planeta
		local Vector pPosition;
		local Vector alPlaneta;
		

		super.PlayerMove(aDeltaTime);

		pPosition=PPawn(pawn).Location;
		alPlaneta=m_CentroPlaneta-pPosition;
		//Caida libre hasta el suelo
		//controlamos la velocidad máxima
		
		if(vsize(Pawn.Velocity)>700)
		{
			m_vCaidaMax=true;
		}

		if (m_vCaidaMax && vsize(Pawn.Velocity)>300)
		{   //Si hemos llegado a velocidad máxima, vamos decelerando
			PPawn(Pawn).Velocity*=0.95;
			`log("decelerando");

		}
        
		ProcessMove(aDeltaTime,PPawn(Pawn).Acceleration,DCLICK_None ,Rotator(vect(0,0,0)));
		//ProcessMove(aDeltaTime,normal(alPlaneta)*500,DCLICK_None ,Rotator(vect(0,0,0)));
		
		`log(""@vsize(pawn.velocity) @vsize(Acceleration));
		
	}
    */

}

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
	transformedMesh=SkeletalMesh'VH_Cicada.Mesh.SK_VH_Cicada'
	transformedAnimTree=AnimTree'VH_Cicada.Anims.AT_VH_Cicada'
	transformedPhysicsAsset=PhysicsAsset'VH_Cicada.Mesh.SK_VH_Cicada_Physics'
	bNotifyFallingHitWall=true
    InputClass=class'PGame.PPlayerInput'
	m_DistanciaAlCentro=12000
	m_ZoomMaxAcercar=0
	m_ZoomMaxAlejar=19000
	m_stepZoom=600
	m_velocidad_rotacion=1.0
	bGodMode=true
}

