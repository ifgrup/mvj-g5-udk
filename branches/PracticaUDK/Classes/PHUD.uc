class PHUD extends HUD;

//La textura que representa el cursor en pantalla (para el caso en el que no se utilice Scaleform)
var const Texture2D CursorTexture; 
//Color del cursor (para el caso en el que no se utilice Scaleform)
var const Color CursorColor;

//Eventos pendientes del raton
var bool PendingLeftPressed;
var bool PendingLeftReleased;

var bool PendingRightPressed;
var bool PendingRightReleased;

var bool PendingMiddlePressed;
var bool PendingMiddleReleased;

var bool PendingScrollDown;
var bool PendingScrollUp;

//Origen del mouse en coordenadas del mundo
var Vector CachedMouseWorldOrigin;
//Direccion del mouse en coordenadas del mundo
var Vector CachedMouseWorldDirection;
//Ultimo item con el que se ha interactuado
var PMouseInteractionInterface LastMouseInteractionInterface;
//Ultimo item clickado
var PMouseInteractionInterface LastClickedItem;

//Usando Scaleform?
var bool UsingScaleform;
//Pelicula Scaleform
var PGFx pGFx;
var PGame game;




//rr new PauseMenu
var bool pauseMenu;
var PGFxUI_PauseMenu		PauseMenuMovie;
//var PMainMenu		PauseMenuMovie;
var bool	bEnableActorOverlays;
var SoundCue musica,musicamenu;

//PHUD_Area
var PHUD_Area area;

//Distanciua de la torreta para poder colocar otra
var Vector distanciatorreta;

var int Pixel_X_Mirilla;
var int Pixel_Y_Mirilla;
var int m_min_offset_mirilla_y, m_max_offset_mirilla_y; //OFFSET de la mirilla al subir/bajar cámara



//gestion de iconos en pantalla 



struct SRadarInfo
{
	var PEnemy UTPawn;
	var MaterialInstanceConstant MaterialInstanceConstant;
	var bool DeleteMe;
	var Vector2D Offset;
	var float Opacity;
};
var array<SRadarInfo> RadarInfo;

var const linearcolor RedLinearColor,BlueLinearColor,DMLinearColor;
var bool bgameover;





//

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	//PlaySound(musica);
	
	area=Spawn(class'PHUD_Area',,,,,,true);
	area.interruptor(false);
	//Si estamos utilizando Scaleform, crear la pelicula
	if(UsingScaleform)
	{
		pGFx = new () class'PGFx';
		if(pGFx != none)
		{
			pGFx.pHUD = self;
			pGFx.SetTimingMode(TM_Game);
			pGFx.Init(class'Engine'.static.GetEngine().GamePlayers[pGFx.LocalPlayerOwnerIndex]);
		}
	}

	pGFx.SetTurretIdle();
}

simulated event Destroyed()
{
	super.Destroyed();

	//Si existe la pelicula Scaleform, borrarla
	if(pGFx != none)
	{
		pGFx.Close(true);
		pGFx = none;
	}
}

//nos da la posición que marcamos con el ratón, 
simulated  function vector GetTargetLocation(optional actor RequestedBy, optional bool bRequestAlternateLoc) 

{
	local Vector HitLocation, HitNormal;
	//local PMouseInteractionInterface MouseInteractionInterface;
//super.GetTargetLocation(RequestedBy,bRequestAlternateLoc);

/*MouseInteractionInterface = */GetMouseActor(HitLocation, HitNormal);
//`Log("la hit location del GetTarget del HUD"@HitLocation);
return HitLocation;
}

function PreCalcValues()
{
	//local ASDisplayInfo DI;
//	local int margenBotones;

	super.PreCalcValues();

	//Si existe la pelicula Scaleform, reiniciar su viewport, modo de escala y alineacion
	//para que encaje en la resolucion de pantalla
	if(pGFx != none)
	{
		pGFx.SetViewport(0, 0, SizeX, SizeY);
		pGFx.SetViewScaleMode(SM_NoScale);
		pGFx.SetAlignment(Align_TopRight);


	}
}

event PostRender()
{
	local PPlayerInput pPlayerInput;
	local PPlayerController pPlayerController;
	local PMouseInteractionInterface MouseInteractionInterface;
	local Vector HitLocation, HitNormal;
	local Vector2D DistanceCheck;
//	local float DistanceToItem;
	//local PPlayerController s;
	local PTurretIce ti;
	local PTurretCannon tc;
	local Rotator rTorreta; //rotacion de la torreta al spawnearla
	local float dist;
	local bool bTierraAire,pct;
	
	Super.PostRender();
	//Casting
	pPlayerInput = PPlayerInput(PlayerOwner.PlayerInput); 

	//Conseguir la altura de los ojos del jugador
	//no necesario por tipo de  vista ortogonal -- vlr
	
	//Si no estamos utilizando Scaleform y tenemos CursorTexture valido, dibujaremos el cursor en el canvas
	if(!UsingScaleform && CursorTexture != None)
	{
		//Asegurar de que tenemos PlayerOwner valido
		if (PlayerOwner != None)
		{
			if (pPlayerInput != None)
			{
				//Poner como posicion del canvas la del mouse
				Canvas.SetPos(pPlayerInput.MousePosition.X, pPlayerInput.MousePosition.Y); 
				//Color del cursor
				Canvas.DrawColor = CursorColor;
				//Dibujar la textura
				Canvas.DrawTile(CursorTexture, CursorTexture.SizeX, CursorTexture.SizeY, 0.f, 0.f, CursorTexture.SizeX, CursorTexture.SizeY,, true);
			}
		}
	}

//renderizar iconos en  pantalla 
iconosapantalla();



	//Conseguir la actual interfaz de interaccion del mouse
	MouseInteractionInterface = GetMouseActor(HitLocation, HitNormal);

	//Si MouseInteractionInterface es nulo, significa que el mouse no esta encima de ningun item
	if(MouseInteractionInterface == none)
	{	
		area.SetLocation(HitLocation+HitNormal*100);
					area.SetRotation(rTorreta);
					pct=PuedocolocarTorreta(HitLocation,HitNormal);
	area.interruptor(pct);
	//area.interruptor(!PGame(WorldInfo.Game).bEarthNotFlying);


		//Si se presiona el boton izquierdo del mouse 
		if(PendingLeftPressed)
		{
			//controlamos que el jugador no este volando y le hacemos disparar
			if(PGame(WorldInfo.Game).bEarthNotFlying)
			{
			pPlayerController = PPlayerController(PlayerOwner);
		
			pPlayerController.StartFire();
			}
			/*
			if(!PGame(WorldInfo.Game).bEarthNotFlying)
			{
				`log("mierdote");
			}
			*/
			//bMouseOverUIElement me dice siestoy encima del propio clip de flash.En talcaso obviamente no podemos actuar encima suyo
			//reload dice si la torreta esta recargada. bTowerActive si esta habilitada por credito
		   // if(!pGFx.bMouseOverUIElement && pGFx.reload && pGFx.bTowerActive && pGFx.HbtActive!=2 && pct )
			if(!pGFx.bMouseOverUIElement && pct && !PGame(WorldInfo.Game).bEarthNotFlying )
		    {

				//`log("la pgfx ttower active " @pGFx.TTowerActive);
				pPlayerController = PPlayerController(PlayerOwner);

				//Creamos torreta solo si hemos clickado dentro del planeta, no en el skybox (control por distancia)
				dist=Vsize(pPlayerController.Pawn.Location-HitLocation);
				if(dist < pPlayerController.m_DistanciaAlCentro)
				{
					rTorreta=Rotator(-HitNormal); //hacia el suelo
					rTorreta.Pitch+=65535/4; //90 grados parriba
					
				`log ( "la torreta activa es:"	@pGFx.HbtActive);		
		
				switch (pGFx.HbtActive)
			{
				case hbt1:
					if(pGfx.hbt1reload)
					{
					PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-pGFx.hbt1precio);
						tc=spawn(class'PTurretCannon', ,,HitLocation,rTorreta,);
						tc.setNormalSuelo(HitNormal);
						pGFx.TurretReload();
					}
					break;

				case hbt2:
					if(pGfx.hbt2reload)
					{
					PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-pGFx.hbt2precio);
						ti=spawn(class'PTurretIce', ,,HitLocation,rTorreta,);
						ti.setNormalSuelo(HitNormal);
						pGFx.TurretReload();
					}
					
					break;

				case hbt3:
					if(pGfx.hbt3reload)
					{
					PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-pGFx.hbt3precio);
						ti=spawn(class'PTurretIce', ,,HitLocation,rTorreta,);
						ti.setNormalSuelo(HitNormal);
						pGFx.TurretReload();
					}
					
					break;
				case hbt4:
					if(pGfx.hbt4reload)
					{
					PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-pGFx.hbt4precio);
						tc=spawn(class'PTurretCannon', ,,HitLocation,rTorreta,);
						tc.setNormalSuelo(HitNormal);
						pGFx.TurretReload();
					}
					
					break;
			}









/*
					if(pGFx.HbtActive==1 && pGfx.hbt1reload)
					{
						//`log("Vamos a spawnear una torreta ice");
						pPlayerController.StartFire();
						//spawn(class'MU_AutoTurret', ,,HitLocation,rTorreta,);
						PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-1000);
						ti=spawn(class'PTurretIce', ,,HitLocation,rTorreta,);
						ti.setNormalSuelo(HitNormal);
						//pGFx.SetHbtReload(1,false);
					}
					else
					{
						tc=spawn(class'PTurretCannon', ,,HitLocation,rTorreta,);
						tc.setNormalSuelo(HitNormal);
						PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-200);
						//pGFx.SetHbtReload(0,false);
					
						//pGFx.SetHbtReload(pGFx.HbtActive,false);
					}*/
					//spawn(class'MU_AutoTurret', ,,HitLocation, rTorreta,);
				
				//	pGFx.SetTowerActive(false);
					//pGFX.SetReload(false);
					
					

				}
				else
				{
					`Log("Click fuera de planeta "@dist @hitlocation);
				}
				PendingLeftPressed = false;
			}
		    PendingLeftPressed = false;
			// rr demo Spawn towwer
			
	//		
//	s.ClientMessage("Posición del raton para spawn" );
		//	s = Spawn(class'PPlayerController', self,,HitLocation);
		//	
			//s.StaticMeshComponent.SetStaticMesh();
			//s.SetPhysics( PHYS_Falling );
		//	s.SetBase(none);

		//	s.bCollideWorld = true;
		//	s.bBounce = true;
//













			//rr demo



			//Si el mouse no esta sobre ningun elemento de la interface
			
			
			
			
			//dirigiremos al personaje a dicha localizacion
			




			/*
			if(!pGFx.bMouseOverUIElement)
			{
				titPlayerController.MovementHitLocation = GetMouseWorldLocation();
				titPlayerController.NuevoDestino();
				//Si esta abierto el panel de interaccion, lo cerramos
				if(titGFx.bPanelInteraccionVisible)
				{
					titGFx.HideInteractionPanel();
				}
			}*/
		}
	/*}else{//si estamos encima de 
	area.SetLocation(HitLocation+HitNormal*100);
	area.interruptor(false);*/
	}

	/****   Controlar mouse over y out  ****/
	//Ha habido anteriormente interaccion con el mouse?
	if(LastMouseInteractionInterface != none)
	{
		//Si la ultima interaccion no es la misma que la actual -> mouseout
		if(LastMouseInteractionInterface != MouseInteractionInterface)
		{
			//Llamar a la funcion mouseout
			LastMouseInteractionInterface.MouseOut(CachedMouseWorldOrigin, CachedMouseWorldDirection);
			//Asignar la nueva interfaz de interaccion del mouse
			LastMouseInteractionInterface = MouseInteractionInterface;

			//Si la nueva interaccion no es nula, (ha pasado de un objeto interactuable a otro)
			if(LastMouseInteractionInterface != none)
			{
				//llamar a la funcion mouseover
				LastMouseInteractionInterface.MouseOver(CachedMouseWorldOrigin, CachedMouseWorldDirection);
			}
		}
	}
	else if (MouseInteractionInterface != none)
	{
		//Asignar la nueva interfaz de interaccion
		LastMouseInteractionInterface = MouseInteractionInterface;
		//mouseover
		LastMouseInteractionInterface.MouseOver(CachedMouseWorldOrigin, CachedMouseWorldDirection);
	}
	/****   Fin controlar mouse over y out  ****/

	if(LastMouseInteractionInterface != none)
	{
		/****     Boton izquierdo   ****/
		if(PendingLeftPressed)
		{
			if(PendingLeftReleased)
			{
				//Left click, descartar
				PendingLeftPressed = false;
				PendingLeftReleased = false;
			}
			else
			{
				//Izquierdo presionado
				PendingLeftPressed = false;
				LastMouseInteractionInterface.MouseLeftPressed(CachedMouseWorldOrigin, CachedMouseWorldDirection, HitLocation, HitNormal);
				//Guardar la referencia del ultimo item clickado
				LastClickedItem = LastMouseInteractionInterface;

				//Calcular la distancia que hay del jugador hasta el item clickado
				DistanceCheck.X = KActorSpawnable(LastClickedItem).Location.X - PlayerOwner.Pawn.Location.X;
				DistanceCheck.Y = KActorSpawnable(LastClickedItem).Location.Y - PlayerOwner.Pawn.Location.Y;

			}
		}
		else if(PendingLeftReleased)
		{
			//Izquierdo release
			PendingLeftReleased = false;
			LastMouseInteractionInterface.MouseLeftReleased(CachedMouseWorldOrigin, CachedMouseWorldDirection);
		


		}

		/****   Fin boton izquierdo ****/

		/****     Boton derecho     ****/
		if(PendingRightPressed)
		{
			if(PendingRightReleased)
			{
				//Right click, descartar
						
				PendingRightPressed = false;
				PendingRightReleased = false;
			}
			else
			{
				PendingRightPressed = false;
				LastMouseInteractionInterface.MouseRightPressed(CachedMouseWorldOrigin, CachedMouseWorldDirection, HitLocation, HitNormal);
			}
		}
		else if(PendingRightReleased)
		{
			//Derecho release
			PendingRightReleased = false;
			LastMouseInteractionInterface.MouseRightReleased(CachedMouseWorldOrigin, CachedMouseWorldDirection);
		}
		/****   Fin boton derecho    ****/

		/****     Boton central     ****/
		if(PendingMiddlePressed)
		{
		
			if(PendingMiddleReleased)
			{
				//Descartar
				PendingMiddlePressed = false;
				PendingMiddleReleased = false;
			}
			else
			{
				//Boton central presionado
				PendingMiddlePressed = false;
				LastMouseInteractionInterface.MouseMiddlePressed(CachedMouseWorldOrigin, CachedMouseWorldDirection, HitLocation, HitNormal);
			}
		}
		else if(PendingMiddleReleased)
		{
			//Boton central release
			PendingMiddleReleased = false;
			LastMouseInteractionInterface.MouseMiddleReleased(CachedMouseWorldOrigin, CachedMouseWorldDirection);
		}
		/****   Fin boton central   ****/

		//Scroll hacia arriba
		if(PendingScrollUp)
		{
			PendingScrollUp = false;
			LastMouseInteractionInterface.MouseScrollUp(CachedMouseWorldOrigin, CachedMouseWorldDirection);

		}

		//Scroll hacia abajo
		if(PendingScrollDown)
		{
			PendingScrollDown = false;
			LastMouseInteractionInterface.MouseScrollDown(CachedMouseWorldOrigin, CachedMouseWorldDirection);

		}
	}
}

function PMouseInteractionInterface GetMouseActor(optional out Vector HitLocation, optional out Vector HitNormal)
{
	local PMouseInteractionInterface MouseInteractionInterface;
	local PPlayerInput pPlayerInput;
	local Vector2D MousePosition;
	local Actor HitActor;

	//Asegurarnos de que tenemos canvas y player owner validos
	if(Canvas == none || PlayerOwner == none)
		return none;

	//Casting
	pPlayerInput = PPlayerInput(PlayerOwner.PlayerInput);

	//Asegurarnos de que el player input es valido
	if(pPlayerInput == none)
		return none;

	//La posicion del mouse que esta guardada como intPoint se necesita como Vector2D
	MousePosition.X = pPlayerInput.MousePosition.X;
	MousePosition.Y = pPlayerInput.MousePosition.Y;
	//Hacer la deproyeccion de la posicion del mouse en pantalla
	//y guardar los valores del mundo del origen y la direccion
	Canvas.DeProject(MousePosition, CachedMouseWorldOrigin, CachedMouseWorldDirection);

	//Hacer Trace para saber sobre que esta el raton
	//Iteramos sobre todo lo que intersecciona la traza para devolver el objeto mas cercano que sea
	//del tipo TITMouseInterfaceInteractionInterface
	foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CachedMouseWorldOrigin + CachedMouseWorldDirection * 65536.f, CachedMouseWorldOrigin,vect(0,0,0),,TRACEFLAG_Bullet)
	{
		//Casting para ver si el actor implementa la interfaz de interaccion del mouse
		MouseInteractionInterface = PMouseInteractionInterface(HitActor);
		//MouseInteractionInterface = PTurretCannon(HitActor);
 
		if(MouseInteractionInterface != none)
		{
			return MouseInteractionInterface;
		}
	}

	return none;
}

//control para colocar torreta 

function bool PuedocolocarTorreta(optional  Vector HitLocation, optional Vector HitNormal)
{
	local PMouseInteractionInterface MouseInteractionInterface;
	local PPlayerBase labase;
	local PEnemy enemigo;
	local PPlayerInput pPlayerInput;
	local Vector2D MousePosition;
	local Actor HitActor;

	//Asegurarnos de que tenemos canvas y player owner validos
	if(Canvas == none || PlayerOwner == none)
		return false;

	//Casting
	pPlayerInput = PPlayerInput(PlayerOwner.PlayerInput);

	//Asegurarnos de que el player input es valido
	if(pPlayerInput == none)
		return false;

	//La posicion del mouse que esta guardada como intPoint se necesita como Vector2D
	MousePosition.X = pPlayerInput.MousePosition.X;
	MousePosition.Y = pPlayerInput.MousePosition.Y;
	//Hacer la deproyeccion de la posicion del mouse en pantalla
	//y guardar los valores del mundo del origen y la direccion
	Canvas.DeProject(MousePosition, CachedMouseWorldOrigin, CachedMouseWorldDirection);

	//Hacer Trace para saber sobre que esta el raton
	//Iteramos sobre todo lo que intersecciona la traza para devolver el objeto mas cercano que sea
	//del tipo TITMouseInterfaceInteractionInterface
	foreach TraceActors(class'Actor',HitActor, HitLocation, HitNormal, CachedMouseWorldOrigin + CachedMouseWorldDirection * 65536.f, CachedMouseWorldOrigin,distanciatorreta,,TRACEFLAG_Bullet)
	{
		//Casting para ver si el actor implementa la interfaz de interaccion del mouse
		MouseInteractionInterface = PMouseInteractionInterface(HitActor);
		labase=PPlayerBase(HitActor);
		enemigo=PEnemy(HitActor);
		//MouseInteractionInterface = PTurretCannon(HitActor);
 
		if(MouseInteractionInterface != none)
		{
			return false;
		}
		if(labase != none)
		{
			return false;
		}
		if(enemigo != none)
		{

			return false;
		}


	}

	return true;
}






/*
function Vector GetMouseWorldLocation()
{
	local PPlayerInput pPlayerInput;
	local Vector2D MousePosition;
	local Vector MouseWorldOrigin, MouseWorldDirection, HitLocation, HitNormal;

	//player owner y canvas validos?
	if(Canvas == none || PlayerOwner == none)
		return vect(0, 0, 0);

	pPlayerInput = PPlayerInput(PlayerOwner.PlayerInput);

	if(pPlayerInput == none)
		return vect(0, 0, 0);

	//Pasar la posicion del mouse de intPoint a Vector2D
	MousePosition.X = pPlayerInput.MousePosition.X;
	MousePosition.Y = pPlayerInput.MousePosition.Y;

	`log("Coordenadas mouse " @MousePosition.X @MousePosition.Y);
	//Deproyectar el mouse
	Canvas.DeProject(MousePosition, MouseWorldOrigin, MouseWorldDirection);

	//Hacer una traza para saber la posicion del mouse en el mundo
	Trace(HitLocation, HitNormal, MouseWorldOrigin + MouseWorldDirection * 65536.f, MouseWorldOrigin, true,,, TRACEFLAG_Bullet);
	`Log("Normal" @HitNormal);
	return HitLocation;
}
*/

function Vector GetMirillaWorldLocation()
{
	local PPlayerInput pPlayerInput;
	local Vector2D MousePosition;
	local Vector MouseWorldOrigin, MouseWorldDirection, HitLocation, HitNormal;
	local Vector HitLocationNoActor;
	local Actor HitActor;
	local ASDisplayInfo DI;

	//player owner y canvas validos?
	if(Canvas == none || PlayerOwner == none)
		return vect(0, 0, 0);

	pPlayerInput = PPlayerInput(PlayerOwner.PlayerInput);

	if(pPlayerInput == none)
		return vect(0, 0, 0);

	//Pasar la posicion del mouse de intPoint a Vector2D
	
	DI=pGFx.pmiratierraMC.GetDisplayInfo();

	MousePosition.X = DI.x;
	MousePosition.Y = DI.y;
	//Deproyectar el mouse
	Canvas.DeProject(MousePosition, MouseWorldOrigin, MouseWorldDirection);

	
	//Hacer una traza para saber la posicion del mouse en el mundo
	Trace(HitLocationNoActor, HitNormal, MouseWorldOrigin + MouseWorldDirection * 65536.f, MouseWorldOrigin, true,,, TRACEFLAG_Bullet);
	//return HitLocationNoActor;


	ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, MouseWorldOrigin + MouseWorldDirection * 65536.f, MouseWorldOrigin,,, TRACEFLAG_Bullet)
    {
    // Type cast to see if the HitActor implements that mouse interaction interface
		
		if (HitLocationNoActor !=HitLocation)
		{
			//`log("__________Traces Diferentes!!!" @HitLocationNoActor @HitLocation);
		}
		return HitLocation;
    
    }
	//`log("__________SIN Traces DisparoActor______");
	return HitLocationNoActor;
}



//rr new
/*function SetPauseMenu(bool val)
{

pauseMenu=val;
pGFx.PauseMenu(pauseMenu);

}*/

function TogglePauseMenu()
{
    if ( PauseMenuMovie != none && PauseMenuMovie.bMovieIsOpen )
	{
		
		if( !WorldInfo.IsPlayInMobilePreview() )
		{
		PauseMenuMovie.PlayCloseAnimation();
		}
		else
		{
			// On mobile previewer, close right away
		CompletePauseMenuClose();
		}
	}
	else
    {
	CloseOtherMenus();

        PlayerOwner.SetPause(True);
 
        if (PauseMenuMovie == None)
        {
	        PauseMenuMovie = new class'PGFxUI_PauseMenu';
	
           PauseMenuMovie.MovieInfo = SwfMovie'PGameMenuFlash.ppausemenu';
			
            PauseMenuMovie.bEnableGammaCorrection = FALSE;
			PauseMenuMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
            PauseMenuMovie.SetTimingMode(TM_Real);
			 
        }

		SetVisible(false);
        PauseMenuMovie.Start();
	   PauseMenuMovie.PlayOpenAnimation();
	 

		// Do not prevent 'escape' to unpause if running in mobile previewer
		if( !WorldInfo.IsPlayInMobilePreview() )
		{
			PauseMenuMovie.AddFocusIgnoreKey('Escape');
		}
    }
}


function CloseOtherMenus();

function SetVisible(bool bNewVisible)
{
	bEnableActorOverlays = bNewVisible;
	bShowHUD = bNewVisible;
}

function CompletePauseMenuClose()
{
    PlayerOwner.SetPause(False);
    PauseMenuMovie.Close(false);  // Keep the Pause Menu loaded in memory for reuse.
    SetVisible(true);
}

//Funcion definida en el DefaultPlayerInput.ini, asociada a a pulsacion de la tecla ESC
exec function ShowMenu()
{
	// if using GFx HUD, use GFx pause menu
	if(!bgameover)
	{
		TogglePauseMenu();
	}
	
}


//
simulated event Tick(float DeltaTime)
{

	super.Tick(DeltaTime);
	pGFx.SetCredito(PGame(WorldInfo.Game).creditos);
	
/*
	if(pGFx.reload &&(PGame(WorldInfo.Game).creditos>=200) )
	{
		pGFx.SetTurretIdle();
		pGFx.SetTowerActive(true);
	}
*/
	//comprueba que tengamos dinero para tener las torretas activas, sino las desactiva 
	ADbotonesporCredito();
	pGFx.AUIVuela(!PGame(WorldInfo.Game).bEarthNotFlying );

	
}


//cambio de mirilla
//Aplica offset en pixels x,y a la posición de la mirilla
exec function mirillatierrapos(float x, float y)
{
	local ASDisplayInfo DI;
	
	DI=pGFx.pmiratierraMC.GetDisplayInfo();
	DI.X=Pixel_X_Mirilla+x;
	DI.Y=Pixel_Y_Mirilla+y;

	pGFx.pmiratierraMC.SetDisplayInfo(DI);
	//`log("Nueva Posicion mirilla "@DI.X @DI.Y);
}


function ADbotonesporCredito()
{
	if((PGame(WorldInfo.Game).creditos <pGFx.hbt1precio))
		{
		pGFx.SetHbtDisabled(hbt1,true);
		
		}else{
		pGFx.SetHbtDisabled(hbt1,false);
		
		
		}

		if((PGame(WorldInfo.Game).creditos < pGFx.hbt2precio))
		{
		pGFx.SetHbtDisabled(hbt2,true);
		
		}else{
		pGFx.SetHbtDisabled(hbt2,false);
		
		}

		if( (PGame(WorldInfo.Game).creditos <pGFx.hbt3precio))
		{
		pGFx.SetHbtDisabled(hbt3,true);
		
		}else{
		pGFx.SetHbtDisabled(hbt3,false);
		
		}

		if( (PGame(WorldInfo.Game).creditos <pGFx.hbt4precio))
		{
		pGFx.SetHbtDisabled(hbt4,true);
		
		}else{
		pGFx.SetHbtDisabled(hbt4,false);

		
		}
}


function inibotoneshud()
{
	pGFx.SetHbtActive(ini);
	pGFx.TurretReload();
	

}


//Gestion de iconos en pantalla 


function AddPostRenderedActor(Actor A)
{
	// Remove post render call for UTPawns as we don't want the name bubbles showing
	if (UTPawn(A) != None)
	{
		return;
	}

	Super.AddPostRenderedActor(A);
}

function iconosapantalla() 
{
	local int i, Index;
	local Vector WorldHUDLocation, ScreenHUDLocation, ActualPointerLocation, CameraViewDirection, PawnDirection, CameraLocation;
	local Rotator CameraRotation;
	local PEnemy  UTPawn;
	local LinearColor TeamLinearColor;
	local float PointerSize;
	local float distcentro;
	local vector rx,ry,rz;
	local float altura_cil_colision;
	local vector cabeza_pawn_location;
	local rotator cabeza_pawn_rotation;

	if (PlayerOwner == None || PlayerOwner.Pawn == None)
	{
		return;
	}

	// Set up the render delta
	RenderDelta = WorldInfo.TimeSeconds - LastHUDRenderTime;

	// Set all radar infos to delete if not found 
	for (i = 0; i < RadarInfo.Length; ++i)
	{
		RadarInfo[i].DeleteMe = true;
	}
	
	// Update the radar infos and see if we need to add or remove any
	distcentro = VSize(PGame(Worldinfo.Game).m_CentroPlaneta - PlayerOwner.Pawn.Location);
	PlayerOwner.Pawn.Mesh.GetSocketWorldLocationAndRotation('Socket_Cabeza',cabeza_pawn_location,cabeza_pawn_rotation);
	//ForEach DynamicActors(class'PEnemy', UTPawn)
    ForEach VisibleCollidingActors ( class 'PEnemy', UTPawn, distcentro,cabeza_pawn_location,,vect(10,10,10))
	{
		/**
		if ( 
			VSize(UTPawn.Location - PlayerOwner.Pawn.Location)  >
			VSize(PGame(Worldinfo.Game).m_CentroPlaneta - PlayerOwner.Pawn.Location) )
			continue;
		**/

		if (UTPawn != PlayerOwner.Pawn)
		{
			Index = RadarInfo.Find('UTPawn', UTPawn);
			// This pawn was not found in our radar infos, so add it
			if (Index == INDEX_NONE && UTPawn.Health > 0)
			{
				i = RadarInfo.Length;
				RadarInfo.Length = RadarInfo.Length + 1;
				RadarInfo[i].UTPawn = UTPawn;
				RadarInfo[i].MaterialInstanceConstant = new () class'MaterialInstanceConstant';

				if (RadarInfo[i].MaterialInstanceConstant != None)
				{
					//RadarInfo[i].MaterialInstanceConstant.SetParent(Material'PGameContentTice.copo_Mat');
					//RadarInfo[i].MaterialInstanceConstant.SetParent(Material'EditorMaterials.MatineeGroups.MAT_Groups_Event_Mat');
						RadarInfo[i].MaterialInstanceConstant.SetParent(Material'GemOnscreenRadarContent.PointerMaterial');
					//RadarInfo[i].MaterialInstanceConstant.SetParent(DecalMaterial'PGameHUDT.towericedecaldemo');
					

					if (UTPawn.PlayerReplicationInfo != None && UTPawn.PlayerReplicationInfo.Team != None)
					{
						TeamLinearColor = (UTPawn.PlayerReplicationInfo.Team.TeamIndex == 0) ? Default.RedLinearColor : Default.BlueLinearColor;
						RadarInfo[i].MaterialInstanceConstant.SetVectorParameterValue('TeamColor', TeamLinearColor);
					}
					else
					{
						RadarInfo[i].MaterialInstanceConstant.SetVectorParameterValue('TeamColor', Default.DMLinearColor);
					}
				}

				RadarInfo[i].DeleteMe = false;
			}
			else if (UTPawn.Health > 0)
			{
				RadarInfo[Index].DeleteMe = false;
			}
		}
	}

	// Handle rendering of all of the radar infos
	PointerSize = Canvas.ClipX * 0.083f;
	PlayerOwner.GetPlayerViewPoint(CameraLocation, CameraRotation);
	CameraViewDirection = Vector(CameraRotation);

	for (i = 0; i < RadarInfo.Length; ++i)
	{
		if (!RadarInfo[i].DeleteMe)
		{
			if (RadarInfo[i].UTPawn != None && RadarInfo[i].MaterialInstanceConstant != None)
			{
				// Handle the opacity of the pointer. If the player cannot see this pawn,
				// then fade it out half way, otherwise if he can, fade it in
				if (WorldInfo.TimeSeconds - RadarInfo[i].UTPawn.LastRenderTime > 0.1f)
				{
					// Player has not seen this pawn in the last 0.1 seconds
					//RadarInfo[i].Opacity = Lerp(RadarInfo[i].Opacity, 0.4f, RenderDelta * 4.f);
				}
				else
				{
					// Player has seen this pawn in the last 0.1 seconds
					//RadarInfo[i].Opacity = Lerp(RadarInfo[i].Opacity, 1.f, RenderDelta * 4.f);
				}
				// Apply the opacity
				//RadarInfo[i].MaterialInstanceConstant.SetScalarParameterValue('Opacity', RadarInfo[i].Opacity);

				// Get the direction from the player's pawn to the pawn
				PawnDirection = Normal(RadarInfo[i].UTPawn.Location - PlayerOwner.Pawn.Location);

				// Check if the pawn is in front of me
				/*
				if (PawnDirection dot CameraViewDirection >= 0.f)
				{
				*/
					// Get the world HUD location, which is just above the pawn's head
					GetAxes(RadarInfo[i].UTPawn.Rotation,rx,ry,rz);
					altura_cil_colision = RadarInfo[i].UTPawn.GetCollisionHeight() ;
					altura_cil_colision = 50;
					WorldHUDLocation = RadarInfo[i].UTPawn.Location + (altura_cil_colision * rz);
					// Project the world HUD location into screen HUD location
					ScreenHUDLocation = Canvas.Project(WorldHUDLocation);

					// If the screen HUD location is more to the right, then swing it to the left
					if (ScreenHUDLocation.X > (Canvas.ClipX * 0.5f))
					{
						RadarInfo[i].Offset.X -= PointerSize * RenderDelta * 4.f;
					}
					else
					{
						// If the screen HUD location is more to the left, then swing it to the right
						RadarInfo[i].Offset.X += PointerSize * RenderDelta * 4.f;
					}
					RadarInfo[i].Offset.X = FClamp(RadarInfo[i].Offset.X, PointerSize * -0.5f, PointerSize * 0.5f);
				
					// Set the rotation of the material icon
					ActualPointerLocation.X = Clamp(ScreenHUDLocation.X, 8, Canvas.ClipX - 8) + RadarInfo[i].Offset.X;
					ActualPointerLocation.Y = Clamp(ScreenHUDLocation.Y - PointerSize + RadarInfo[i].Offset.Y, 8, Canvas.ClipY - 8 - PointerSize) + (PointerSize * 0.5f);
					RadarInfo[i].MaterialInstanceConstant.SetScalarParameterValue('Rotation', GetAngle(ActualPointerLocation, ScreenHUDLocation));

					// Draw the material pointer

					DibujaEstadoPEnemy(RadarInfo[i],ScreenHUDLocation,PointerSize);
					//Canvas.SetPos(ActualPointerLocation.X - (PointerSize * 0.5f), ActualPointerLocation.Y - (PointerSize * 0.5f));
				//	Canvas.SetPos(ScreenHUDLocation.X-100 , ScreenHUDLocation.Y-50);
				//	pGFx.demoMC(ScreenHUDLocation.X,ScreenHUDLocation.Y);
					//Canvas.DrawMaterialTile(RadarInfo[i].MaterialInstanceConstant, PointerSize, PointerSize);
					//Canvas.SetDrawColor(255,0,0,255);
					//Canvas.DrawRect(20,10);
				/*
				}
				*/
			}
		}
		else
		{
			// Null the variables previous stored so garbage collection can occur
			RadarInfo[i].UTPawn = None;
			RadarInfo[i].MaterialInstanceConstant = None;
			// Remove from the radar info array
			RadarInfo.Remove(i, 1);
			// Back step one, to maintain the for loop
			--i;
		}
	}

	// Setup the render delta
	LastHUDRenderTime = WorldInfo.TimeSeconds;
	
}



function float GetAngle(Vector PointB, Vector PointC)
{
	// Check if angle can easily be determined if it is up or down
	if (PointB.X == PointC.X)
	{
		return (PointB.Y < PointC.Y) ? Pi : 0.f;
	}

	// Check if angle can easily be determined if it is left or right
	if (PointB.Y == PointC.Y)
	{
		return (PointB.X < PointC.X) ? (Pi * 1.5f) : (Pi * 0.5f);
	}

	return (2.f * Pi) - atan2(PointB.X - PointC.X, PointB.Y - PointC.Y);
}




 function DibujaEstadoPEnemy(SRadarInfo ERadarInfo,Vector ScreenHUDLocation,float PointerSize)
{

	local int pvida;

	pvida=(ERadarInfo.UTPawn.life*100) /ERadarInfo.UTPawn.MaxLife;
	//`log("la vida de los Penemy en %"@pvida);
	Canvas.SetPos(ScreenHUDLocation.X-100 , ScreenHUDLocation.Y-50);
	Canvas.DrawMaterialTile(ERadarInfo.MaterialInstanceConstant, PointerSize, PointerSize);


	// Borde
	Canvas.SetPos(ScreenHUDLocation.X-100, ScreenHUDLocation.Y-50);
	Canvas.SetDrawColor(0,0,0, 200);
	Canvas.DrawBox(102,20);

	// Barra
	Canvas.SetPos(ScreenHUDLocation.X-98, ScreenHUDLocation.Y-48);
	Canvas.SetDrawColor(255,0,0,255);
	Canvas.DrawRect(pvida,16);


	
}



exec function msgpantalla(string texto)
{

pGFx.MensajitoPotPantalla(texto);
//pGFx.loghudMC.GotoAndPlay("ini");
}

//Coloca la película de GameOver en medio de la pantalla y ponemos la variable bgameover a true para que no pueda funcionar la tecla ESC que ejecuta el pauseMenu.
exec function fineee()
{
	local ASDisplayInfo DI;
	
	DI=pGFx.gameoverMC.GetDisplayInfo();
	DI.X=self.CenterX;
	DI.Y=self.CenterY;
	DI.Visible=true;
	DI.Alpha=80;
	pGFx.gameoverMC.SetDisplayInfo(DI);
	pGFx.gameoverMC.GotoAndPlayI(4);
	pGFx.raton.SetBool("_visible", true);
	bgameover=true;
	PlayerOwner.SetPause(True,gover);
	

}
delegate bool gover()
{
	return false;
}


//

defaultproperties
{
	CursorColor=(R=255,G=255,B=255,A=255)
	CursorTexture=Texture2D'EngineResources.Cursors.Arrow'
	UsingScaleform=true
	pauseMenu=false
	musica=SoundCue'PGameMusicrr.musica2'
	musicamenu=SoundCue'PGameMusicrr.intro2dgame_2_Cue'
	distanciatorreta=(X=350,Y=350,Z=350)
	Pixel_X_Mirilla = 642
	Pixel_Y_Mirilla = 362
	m_min_offset_mirilla_y = 55
	m_max_offset_mirilla_y = -90

	//parametros de  iconos de pantalla
	RedLinearColor=(R=3.0,G=0.0,B=0.05,A=0.8)
	BlueLinearColor=(R=0.5,G=0.8,B=10.0,A=0.8)
	DMLinearColor=(R=1.0,G=1.0,B=1.0,A=0.5)
	bgameover=false;

}

