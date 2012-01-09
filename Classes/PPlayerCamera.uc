class PPlayerCamera extends Camera;

var Vector CamOffset;
var float  CameraZOffset;
var float  CameraScale, CurrentCameraScale;
var float  CameraScaleMin, CameraScaleMax;
var vector CameraTranslateScale;

//VMH Called per-frame to update the view target to it's new position, rotation, and fov
//Para recalcular el Point Of View de la camara
function UpdateViewTarget(out TViewTarget outVT, float DeltaTime)
{
	local vector      HitLocation, HitNormal;
	local CameraActor CamActor;
	local Pawn        TPawn;
	
	local vector CamStart, CamDirX, CamDirY, CamDirZ, CamDir,CurrentCamOffset;
	local float DesiredCameraZOffset;
	
	local float RadioColision;
	local Rotator rProta,lpRotation;

	local vector tmpCamStart,tmpCamEnd;
	local float dist;

	// Don't update outgoing viewtarget during an interpolation
	if( PendingViewTarget.Target != None && OutVT == ViewTarget && BlendParams.bLockOutgoing )
	{
		return;
	}
	
	// Default FOV on viewtarget
	OutVT.POV.FOV = DefaultFOV;
	
	// Viewing through a camera actor.
	CamActor = CameraActor(OutVT.Target);//OutVT.Target es el actor objetivo de la camara.Hacemos el casting a CameraActor
	if( CamActor != None )
	{
		//`Log("CamActor no es null");

		//Si hay, obtenemos el Point of View de esa camara
		CamActor.GetCameraView(DeltaTime, OutVT.POV);
		
		// Grab aspect ratio from the CameraActor.
		bConstrainAspectRatio = bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
		OutVT.AspectRatio     = CamActor.AspectRatio;
		
		// See if the CameraActor wants to override the PostProcess settings used.
		CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
		CamPostProcessSettings      = CamActor.CamOverridePostProcess;
	}
	else
	{ 
		//`Log("CamActor ES null, entramos por Pawn");

		//No es una camara sino un Pawn ???
		TPawn = Pawn(OutVT.Target);
		// Give Pawn Viewtarget a chance to dictate the camera position.
		// If Pawn doesn't override the camera view, then we proceed with our own defaults
		//VMH Si TPawn quiere recalcular la camara, CalcCamera debe retornar True. Por eso, si devuelve False, es que
		//    no quiere sobreescribir ese comportamiento
		if( TPawn == None || !TPawn.CalcCamera(DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV) )
		{
			//`Log("Pawn no sobreescribe CalcCamera");
			/**************************************
			* Calculate third-person perspective
			* Borrowed from UTPawn implementation
			**************************************/

			//Radio del cilindro de colision
			if (TPawn!= None)
			{
				RadioColision=TPawn.GetCollisionRadius();
				//`Log("Radio " $ RadioColision);
			}
			else
			{
				RadioColision=20.0;//Valor just in case...
			}

			//Obtenemos la posicion actual del pawn
			CamStart=TPawn.Location;
			CamStart.Z+=CameraZOffset; //Para elevarlo por encima de la cabeza del bicho
			rProta=OutVT.POV.Rotation; //La rotaci�n del prota. La pasamos a coordenadas de mundo:
			GetAxes(rProta,CamDirX,CamDirY,CamDirz);
			//Tenemos el vector director de hacia donde est� mirando el prota,en coordenadas de mundo. Lo escalamos:
			CamDirX*=RadioColision * CameraTranslateScale.X;
			CamDirY*=RadioColision * CameraTranslateScale.Y;
			CamDirZ*=RadioColision * CameraTranslateScale.Z;
			CamDir=CamDirX+CamDirY+CamDirZ; //Array con los componentes de la direcci�n de la c�mara

			//Ahora tenemos la posici�n del bicho, el vector de hacia d�nde est� mirando, y hemos escalado ese vector
			//para que est� a la distancia deseada desde el bicho hacia donde mira (CamDir).
			//Si a la posici�n del bicho, le restamos CamDir, tenemos un punto que es el inicio de una recta
			//que pase por el bicho y siga hacia donde est� mirando el bicho. Es decir, la tercera persona que deseamos
			OutVT.POV.Location=CamStart-CamDir;

			//Y le decimos a la c�mara, que su rotaci�n es igual a la rotaci�n del PlayerController que la maneja
			
			OutVT.POV.Rotation= PCOwner.Rotation; 

			//Ahora hay que controlar que al rotar y tal, no pongamos la c�mara entre una pared y el bicho
			//Lanzamos un 'rayo' desde la c�mara hasta el bicho, y si encontramos alg�n obst�culo por medio, ponemos la c�mara
			//donde est� el obst�culo, para evitar tener esa pared en medio. Si hubiera m�s de dos obst�culos, el segundo nos seguir�a
			//tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la c�mara, y el primer obst�culo es el que 
			//utilizamos ;)
			if (Trace(HitLocation, HitNormal, OutVT.POV.Location, CamStart, false, vect(12,12,12),,TRACEFLAG_Blocking) != None)
			{
				//Hay contacto. Ponemos la c�mara en el obst�culo
				OutVT.POV.Location=HitLocation;

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
				if ( (dist < RadioColision*2.0) &&
					  (HitLocation.Z<TPawn.Location.Z+TPawn.CylinderComponent.CollisionHeight) &&
					  (HitLocation.Z>TPawn.Location.Z-TPawn.CylinderComponent.CollisionHeight))
				{
					//Estamos dentro del bicho. Ocultamos su mesh
					TPawn.Mesh.SetHidden(True);
				}
				else
				{
					TPawn.Mesh.SetHidden(False);
				}
			}//Trace para ver si hay obst�culos
			
		}//else TPawn None

	}//else CamActor None

	//Apply camera modifiers at the end (view shakes for example)
	ApplyCameraModifiers(DeltaTime, OutVT.POV);
	

} //UpdateViewTarget


/******************

			OutVT.POV.Rotation = PCOwner.Rotation;   //VMH Pillamos la rotaci�n del PlayerController que posee esta c�mara                                                
			CamStart = TPawn.Location;
			CurrentCamOffset = CamOffset;

			//Calculamos la Z deseada de la camara.
			//Utilizamos la altura del cilindro de colisi�n y la Translation.Z?? del Mesh, m�s un 20%
			DesiredCameraZOffset = 1.6 * TPawn.GetCollisionHeight() + TPawn.Mesh.Translation.Z;
			
			//Ahora la de verdad. Hace un calculo que no entiendo por si ha pasado poco tiempo ????
			CameraZOffset = (DeltaTime < 0.2) ? DesiredCameraZOffset * 5 * DeltaTime + (1 - 5*DeltaTime) * CameraZOffset : DesiredCameraZOffset;

			//Aplica el offset calculado a la Z de la posici�n inicial de la camara, que en este caso, ser� justo encima de la cabeza
			//del jugador, ya que CamStart pilla la Location del TPawn
			CamStart.Z += CameraZOffset;

			//Obtengo la rotacion en coordenadas de Mundo
			GetAxes(OutVT.POV.Rotation, CamDirX, CamDirY, CamDirZ);
			CamDirX *= CurrentCameraScale;

			TPawn.FindSpot(Tpawn.GetCollisionExtent(),CamStart);
			if (CurrentCameraScale < CameraScale)
			{
				CurrentCameraScale = FMin(CameraScale, CurrentCameraScale + 5 * FMax(CameraScale - CurrentCameraScale, 0.3)*DeltaTime);
			}
			else if (CurrentCameraScale > CameraScale)
			{
				CurrentCameraScale = FMax(CameraScale, CurrentCameraScale - 5 * FMax(CameraScale - CurrentCameraScale, 0.3)*DeltaTime);
			}   
			
			if (CamDirX.Z > TPawn.GetCollisionHeight())
			{
				CamDirX *= square(cos(OutVT.POV.Rotation.Pitch * 0.0000958738)); // 0.0000958738 = 2*PI/65536
			}

			OutVT.POV.Location = CamStart - CamDirX*CurrentCamOffset.X + CurrentCamOffset.Y*CamDirY + CurrentCamOffset.Z*CamDirZ;

			if (Trace(HitLocation, HitNormal, OutVT.POV.Location, CamStart, false, vect(12,12,12)) != None)
			{
				OutVT.POV.Location = HitLocation;
			}
		}
	}
*********************/
	// Apply camera modifiers at the end (view shakes for example)
	//ApplyCameraModifiers(DeltaTime, OutVT.POV);
//}

defaultproperties
{
	CamOffset=(X=12.0,Y=0.0,Z=-17.0)
	CurrentCameraScale=1.0
	CameraScale=9.0
	CameraScaleMin=3.0
	CameraScaleMax=40.0
	//VMH: Ir probando...
    CameraZOffset=20.0
    CameraTranslateScale=(X=15.0,Y=1.0,Z=-2.0)
}
