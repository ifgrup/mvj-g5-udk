class PCamera extends Camera;


var float ThirdPersonCamOffsetX;
var float ThirdPersonCamOffsetY;
var float ThirdPersonCamOffsetZ;
var Rotator CurrentCamOrientation;
var Rotator DesiredCamOrientation;


var Vector CamOffset;
var float CameraZOffset;
var float CameraScale, CurrentCameraScale; /** multiplier to default camera distance */
var float CameraScaleMin, CameraScaleMax;

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
   local vector      HitLocation, HitNormal;
   local CameraActor   CamActor;
   local PPawn          TPawn;
      
   local vector CamStart, CamDirX, CamDirY, CamDirZ, CurrentCamOffset;
   local float DesiredCameraZOffset;
   local PPlayerController ppc;

   ppc=PPlayerController(PCOwner);
   TPawn =PPAwn(ppc.Pawn);

   // Don't update outgoing viewtarget during an interpolation 
   if( PendingViewTarget.Target != None && OutVT == ViewTarget && BlendParams.bLockOutgoing )
   {
      return;
   }

   // Default FOV on viewtarget
   OutVT.POV.FOV = DefaultFOV;

   // Viewing through a camera actor.--> Por ejemplo, cuando se activa un matinee.
   CamActor = CameraActor(OutVT.Target);
   if( CamActor != None )
   {

      CamActor.GetCameraView(DeltaTime, OutVT.POV);

      // Grab aspect ratio from the CameraActor.
      bConstrainAspectRatio   = bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
      OutVT.AspectRatio      = CamActor.AspectRatio;

      // See if the CameraActor wants to override the PostProcess settings used.
      CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
      CamPostProcessSettings = CamActor.CamOverridePostProcess;
   }
   else
   {
      //VMH TPawn = Pawn(OutVT.Target);
      // Give Pawn Viewtarget a chance to dictate the camera position.
      // If Pawn doesn't override the camera view, then we proceed with our own defaults
      if( TPawn == None || !TPawn.CalcCamera(DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV) )
      {   
         CamaraAndando( DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation);
      }
   }

   // Apply camera modifiers at the end (view shakes for example)
   ApplyCameraModifiers(DeltaTime, OutVT.POV);
}



function CamaraAndando( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot)
    {

        local vector  CamDirX, CamDirY,CamDirZ;    
        local vector  HitLocation, HitNormal,CamStart,tmpCamStart,tmpCamEnd;
        local Rotator rProta;
        local float dist,fs;
		local float despx,despz;
		local quat  qpitchZ,qCamZ;
		local vector qX,qY,qZ;
		local bool bCamaraUPDown;
		local PPlayerController ppc;

		
		ppc=PPlayerController(PCOwner);

        if(ppc.Pawn != none)
        {

            CamStart=ppc.Pawn.Location;
            rProta=ppc.Pawn.Rotation; //Hacia donde mira el prota.La pasamos a coordenadas de mundo:
			out_CamRot=rProta;
            GetAxes(rProta,CamDirX,CamDirY,CamDirz);
            //Tenemos el sist.coordenadas de hacia donde est� mirando el prota,en coordenadas de mundo.
            //Como queremos estar siempre detr�s, s�lo nos interesa desplazar la c�mara s�lo en X, dejando la Y a cero

            //Calculamos desplazamiento up/down de la c�mara. 
            //PlayerInput.aLookup no es absoluto, sino que depende s�lo de la velocidad del movimiento del mouse.
            //Para controlar si la c�mara est� m�s arriba o abajo, vamos acumulando el valor,
            //modul�ndolo con sin 
            
       		//Debemos intentar mantener la distancia de la c�mara al jugador.
            //En X debemos desplazar en -CamDirX, y en Z, +camDirZ.
			//Consideramos mOffsetCamaraUpDown como el �ngulo de inclinaci�n de la c�mara
			despX=350;//300*sin(mOffsetCamaraUpDown*degtorad);
			despZ=100; 
			//La rotaci�n la debemos modificar en up/down, rotando sobre el eje Y actual del Rotator
			//para ello, benditos quaternions:
			
            /**********************************************
             ********************************************** 
             * DE MOMENTO NO HACEMOS ROTACION UP/DOWN, YA VEREMOS SI LA USAMOS LUEGO
			//`log ("moffset " @mOffsetCamaraUpDown);
			qcamZ=QuatFromRotator(ppc.Pawn.Rotation);
			GetAxes(ppc.Pawn.Rotation,qX,qY,qZ);
			
			qPitchZ=QuatFromAxisAndAngle(qY,ppc.mOffsetCamaraUpDown*DegToRad);
			qcamZ=QuatProduct(qPitchZ,qcamZ);
			out_CamRot=QuatToRotator(qcamZ);
			despZ=600*sin(ppc.mOffsetCamaraUpDown*degtorad);
			************************************************/

			//La posici�n de la c�mara la tenemos calculada con sin/cos del �ngulo, considerando 300 como distancia a mantener
			out_CamLoc = ppc.Pawn.Location -(CamDirX*despX)+(camDirZ*despZ);
			
			//Hay que comprobar que no se ponga ning�n objeto entre la c�mara y el Pawn:
            //Lanzamos un 'rayo' desde la c�mara hasta el bicho, y si encontramos alg�n obst�culo por medio, ponemos la c�mara
            //donde est� el obst�culo, para evitar tener esa pared en medio. Si hubiera m�s de dos obst�culos, el segundo nos seguir�a
            //tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la c�mara, y el primer obst�culo es el que 
            //utilizamos ;)
        
            if (Trace(HitLocation, HitNormal, out_CamLoc,ppc.Pawn.Location, false, vect(12,12,12),,TRACEFLAG_Blocking) != None)
            {
                //Hay contacto. Ponemos la c�mara en el obst�culo
                out_CamLoc=HitLocation;

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
                if ( (dist < ppc.Pawn.GetCollisionRadius()*2.0) && 
                      (HitLocation.Z<ppc.Pawn.Location.Z+ppc.Pawn.CylinderComponent.CollisionHeight) &&
                      (HitLocation.Z>ppc.Pawn.Location.Z-ppc.Pawn.CylinderComponent.CollisionHeight))
                {
                    //Estamos dentro del bicho. Ocultamos su mesh
                    PPawn(ppc.Pawn).Mesh.SetHidden(True);
                }
                else
                {
                    PPawn(ppc.Pawn).Mesh.SetHidden(False);
                }
            }//Trace para ver si hay obst�culos
			else
			{
				//Solo se pone visible de nuevo si el trace da que hay colision pero estamos fuera.
				//Por tanto, aqui aseguramos que est� visible
				PPAwn(ppc.Pawn).mesh.SetHidden(false);
			}
        }//if Pawn!= None

 }//CamaraAndando


/***************
 function LoQueHabiaAntes()
{
/**************************************
          * Calculate third-person perspective
          * Borrowed from UTPawn implementation
          **************************************/
         OutVT.POV.Rotation = PCOwner.Rotation;                                                   
         CamStart = TPawn.Location;
         CurrentCamOffset = CamOffset;
         
         DesiredCameraZOffset = 1.2 * TPawn.GetCollisionHeight() + TPawn.Mesh.Translation.Z;
         CameraZOffset = (DeltaTime < 0.2) ? DesiredCameraZOffset * 5 * DeltaTime + (1 - 5*DeltaTime) * CameraZOffset : DesiredCameraZOffset;
         
         CamStart.Z += CameraZOffset;
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
*******************/

DefaultProperties
{
   CamOffset=(X=50.0,Y=0.0,Z=100.0)
   CurrentCameraScale=1.0
   CameraScale=9.0
   CameraScaleMin=3.0
   CameraScaleMax=40.0
}
