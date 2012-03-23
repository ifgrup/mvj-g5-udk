class PEnemyBot extends GameAIController;

var Pawn thePlayer;
var vector OldFloor;
var vector ViewX, ViewY, ViewZ;
var vector OldLocation;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}


function Tick(float DeltaTime)
{
	local rotator ViewRotation, CamRotation;
	local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
	local vector CamOldX;
	local bool bSaltando;

       
	//Si estoy saltando, nada de transiciones de normales, sigo teniendo como normal la vertical del salto y punto
	if ( MyFloor != OldFloor )
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


	//Ahora giro de la cámara.
	//Al girar por aTurn,sólo nos afectará la rotación sobre el eje Z.
	//Por tanto, la Z quedará igual, la X es la que rotará, y la Y será el producto cartesiano de la nueva X por la Z que ya tenemos
/*	if ( (PlayerInput.aTurn != 0) || (PlayerInput.aLookUp != 0) )
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
	}*/

	ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
	SetRotation(ViewRotation);
	if(Pawn != None)
	{
		Pawn.SetRotation(ViewRotation);
	}		
}


event SeePlayer(Pawn SeenPlayer)
{
	if(thePlayer == none)
	{
		//Pawn.SetPhysics(PHYS_Spider);
		thePlayer = SeenPlayer;
		GotoState('Follow');
	}
}

state Follow
{
Begin:
	if(thePlayer != none)
	{
		//Pawn.SetPhysics(PHYS_Spider);
		MoveTo(thePlayer.Location);
		GotoState('Looking');
	}
}

state Looking
{
Begin:
	if(thePlayer != none)
	{
		MoveTo(thePlayer.Location);
		GotoState('Follow');
	}
}

DefaultProperties
{
}
