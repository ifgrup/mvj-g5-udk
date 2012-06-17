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
			despZ=100; 
			//La rotación la debemos modificar en up/down, rotando sobre el eje Y actual del Rotator
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

			//La posición de la cámara la tenemos calculada con sin/cos del ángulo, considerando 300 como distancia a mantener
			out_CamLoc = ppc.Pawn.Location -(CamDirX*despX)+(camDirZ*despZ);
			
			//Hay que comprobar que no se ponga ningún objeto entre la cámara y el Pawn:
            //Lanzamos un 'rayo' desde la cámara hasta el bicho, y si encontramos algún obstáculo por medio, ponemos la cámara
            //donde está el obstáculo, para evitar tener esa pared en medio. Si hubiera más de dos obstáculos, el segundo nos seguiría
            //tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la cámara, y el primer obstáculo es el que 
            //utilizamos ;)
        
            if (Trace(HitLocation, HitNormal, out_CamLoc,ppc.Pawn.Location, false, vect(12,12,12),,TRACEFLAG_Blocking) != None)
            {
                //Hay contacto. Ponemos la cámara en el obstáculo
                out_CamLoc=HitLocation;

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
            }//Trace para ver si hay obstáculos
			else
			{
				//Solo se pone visible de nuevo si el trace da que hay colision pero estamos fuera.
				//Por tanto, aqui aseguramos que esté visible
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
