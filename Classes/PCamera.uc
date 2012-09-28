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
var float m_anguloUpDown;
var float m_maxLookup; //Valor máximo de PlayerImput.Lookup para que el sin vaya de -Pi/2 a Pi/2
var float m_min_anguloUD,m_max_anguloUD; //maximos angulos de camara Up Down
var float m_desp_camara_izda;
var float m_factor_alejar_camara; //valor por el que se multiplica el sin para alejar la cámara en el up/down
var float m_despX_camara; //desp inicial en CamDirX a espaldas del robot

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
		local float despx;
		local quat  qpitchY,qCamY;
		local vector qX,qY,qZ;
		local PPlayerController ppc;
		local Rotator rot4cam;
		local float deltaAnguloUD;
		local float lookupFiltrado,factor,maxLookup;
		
		ppc=PPlayerController(PCOwner);

        if(ppc.Pawn != none)
        {

            CamStart=ppc.Pawn.Location;
			rot4cam=ppc.m_Rotation_4cam;
			out_CamRot=rot4cam;
            GetAxes(rot4cam,CamDirX,CamDirY,CamDirz);
            //Tenemos el sist.coordenadas de hacia donde está mirando el prota,en coordenadas de mundo.
            //Como queremos estar siempre detrás, sólo nos interesa desplazar la cámara sólo en X, dejando la Y a cero

            //Calculamos desplazamiento up/down de la cámara. 
            //PlayerInput.aLookup no es absoluto, sino que depende sólo de la velocidad del movimiento del mouse.
            //Para controlar si la cámara está más arriba o abajo, vamos acumulando el valor,
            //modulándolo con sin 
            
       		//Debemos intentar mantener la distancia de la cámara al jugador.
            //En X debemos desplazar en -CamDirX, y en Z, +camDirZ.
			//Consideramos mOffsetCamaraUpDown como el ángulo de inclinación de la cámara
			//La rotación la debemos modificar en up/down, rotando sobre el eje Y actual del Rotator
			//para ello, benditos quaternions:

	
			if (ppc.mUltimoLookup != 0)
			{
				//Si el lookup es tal que el Sin cambiaría de signo, o sea, que
				//0.003*lookup pasara de Pi/2 o -Pi/2,calculamos el factor del lookup respecto
				//al lookup equivalente de +-Pi/2, hacemos el sin sobre ese, y al resultado, aplicamos
				//el factor obtenido. 
				if (abs(ppc.mUltimoLookup) > maxLookup)
				{
					factor = abs(ppc.mUltimoLookup) / m_maxLookup;
					if (ppc.mUltimoLookup > 0)
					{
						lookupFiltrado = m_maxLookup;
					}
					else
					{
						lookupFiltrado = - m_maxLookup;
					}
				}
				else
				{
					factor = 1;
					lookupFiltrado = ppc.mUltimoLookup;
				}
				
				deltaAnguloUD = factor * sin(0.003*lookupFiltrado);
				m_anguloUpDown = m_anguloUpDown - deltaAnguloUD;
				m_anguloUpDown = fclamp (m_anguloUpDown, m_min_anguloUD ,m_max_anguloUD);
				//`log("Angulo "@m_anguloUpDown);
			}	

			//Aplicamos quaternions para rotar la cámara sobre Y con el ángulo calculado
        	qcamY=QuatFromRotator(rot4cam);
			GetAxes(rot4cam,qX,qY,qZ);
			qPitchY=QuatFromAxisAndAngle(qy,m_anguloUpDown*DegToRad);
			qcamY=QuatProduct(qPitchY,qcamY);
			//Una vez hecha la rotación para mover la cámara, actualizamos CamDirX y CamDirZ
			//out_CamRot = RInterpTo(rot4cam,QuatToRotator(qcamZ),fDeltaTime*10,1000,true);
			out_CamRot = QuatToRotator(qcamY) ;
			GetAxes(out_CamRot,CamDirX,CamDirY,CamDirz);




			//La posición de la cámara la obtenemos :
			//- Restando el desplazamiento predefinido en m_despX_camara, por el vector CamDirX. Es decir, nos ponemos detrás del robot
			//  a distancia m_despX_camara
			//- Sumando CamDirY * m_desp_camara_izda, es decir, m_desp_camara_izda unidades en el vector CamDirY, es decir, a la izda de la cámara
			//- Al subir el ángulo, vamos aumentando la distancia de la cámara al Pawn en X, es decir, vamos aumentando m_despX_camara
			//  el ángulo va de m_min_anguloUD a m_max_anguloUD. 
			//  Para los negativos, posiblemente no haga nada porrque el control de Trace de cámara con el suelo lo acercará
			//  Ponderamos de 0,1, y con un sin obtenemos el valor a aplicar, y multiplicamos por un factor.
			
			//despX = m_despX_camara + sin(0.2 * ((m_anguloUpDown-m_min_anguloUD) * 5* Pi/2 / (m_max_anguloUD-m_min_anguloUD) ))* m_factor_alejar_camara;
			despX = m_despX_camara + sin((m_anguloUpDown-m_min_anguloUD) * Pi/2 / (m_max_anguloUD-m_min_anguloUD) ) * m_factor_alejar_camara;
			//despX = m_despX_camara + (exp((m_anguloUpDown-m_min_anguloUD) / (m_max_anguloUD-m_min_anguloUD) ) )* m_factor_alejar_camara;
			
			out_CamLoc = (ppc.Pawn.Location ) -(CamDirX*despX) + (CamDirY*m_desp_camara_izda); //*abs(m_anguloUpDown)/40);

			//Hay que comprobar que no se ponga ningún objeto entre la cámara y el Pawn:
            //Lanzamos un 'rayo' desde la cámara hasta el bicho, y si encontramos algún obstáculo por medio, ponemos la cámara
            //donde está el obstáculo, para evitar tener esa pared en medio. Si hubiera más de dos obstáculos, el segundo nos seguiría
            //tapando. Por eso, el rayo hay que lanzarlo mejor desde el bicho a la cámara, y el primer obstáculo es el que 
            //utilizamos ;)

            if (Trace(HitLocation, HitNormal, out_CamLoc,ppc.Pawn.Location, true, vect(12,12,12),,TRACEFLAG_Bullet) != None)
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
                    //Estamos dentro del bicho. Ocultamos su mesh y apagamos los propulsores
                    PPawn(ppc.Pawn).Mesh.SetHidden(True);
					PPawn(ppc.Pawn).EstadoPropulsores(false);
                }
                else
                {
                    PPawn(ppc.Pawn).Mesh.SetHidden(False);
					PPawn(ppc.Pawn).EstadoPropulsores(true);
                }
            }//Trace para ver si hay obstáculos
			else
			{
				//Solo se pone visible de nuevo si el trace da que hay colision pero estamos fuera.
				//Por tanto, aqui aseguramos que esté visible
				PPAwn(ppc.Pawn).mesh.SetHidden(false);
				PPawn(ppc.Pawn).EstadoPropulsores(true);
			}
        }//if Pawn!= None

		ActualizaMirilla();
 }//CamaraAndando

 function ActualizaMirilla() 
 {
	local PPlayerController pc;
	local PHud elhud;
	local float ratio;
	local float deltamirilla;

	pc = PPlayerController(PCOwner);
	elhud = PHud(pc.myHUD);
	
	if(elhud==None)
	{
		return; //Durante el load es nulo, lo protegemos... 
	}
	ratio = (m_anguloUpDown-m_min_anguloUD)/(m_max_anguloUD - m_min_anguloUD);

	deltamirilla = elhud.m_min_offset_mirilla_y + ratio * (elhud.m_max_offset_mirilla_y - elhud.m_min_offset_mirilla_y);

	elhud.mirillatierrapos(0,deltamirilla);
	//`log("A HUD con  angulo " @m_anguloUpDown @deltamirilla);
		
 }

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
   m_maxLookup = 523 //3.1415926535897932/(2*0.003) 
   m_min_anguloUD = -20
   m_max_anguloUD = 35  
   m_desp_camara_izda = 53
   m_factor_alejar_camara = 120
   m_despX_camara = 115
}
