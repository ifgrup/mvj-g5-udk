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

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

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
`Log("la hit location del GetTarget del HUD"@HitLocation);
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
		pGFx.SetAlignment(Align_TopLeft);

		//Alinear los elementos de la pelicula flash por si acaso
//		margenBotones = 20;
/*
		//Inventario
		DI = titGFx.panelInventarioMC.GetDisplayInfo();
		DI.X = SizeX/2;
		DI.Y = SizeY;
		titGFx.panelInventarioMC.SetDisplayInfo(DI);

		//Boton para abrir el inventario
		DI = titGFx.botonInventarioMC.GetDisplayInfo();
		DI.X = 0;
		DI.Y = SizeY;
		titGFx.botonInventarioMC.SetDisplayInfo(DI);

		//Boton de ayuda
		DI = titGFx.botonAyudaMC.GetDisplayInfo();
		DI.X = SizeX - margenBotones;
		DI.Y = margenBotones;
		titGFx.botonAyudaMC.SetDisplayInfo(DI);

		//Boton del mapa
		DI = titGFx.botonMapaMC.GetDisplayInfo();
		DI.X = SizeX - margenBotones;
		DI.Y = SizeY - margenBotones;
		titGFx.botonMapaMC.SetDisplayInfo(DI);

*/
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
	local PAutoTurret tc,ti;
	local Rotator rTorreta; //rotacion de la torreta al spawnearla
	local float dist;
	local bool bTierraAire;
	
	Super.PostRender();
	//Casting
	pPlayerInput = PPlayerInput(PlayerOwner.PlayerInput); 

	//Conseguir la altura de los ojos del jugador
	//no necesario por tipo de  vista ortogonal -- vlr
	/*
	titPlayerController = TITPlayerController(PlayerOwner);
	titPlayerController.PawnEyeLocation = Pawn(PlayerOwner.ViewTarget).Location + Pawn(PlayerOwner.ViewTarget).EyeHeight * vect(0,0,1);
	*/
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






	//Conseguir la actual interfaz de interaccion del mouse
	MouseInteractionInterface = GetMouseActor(HitLocation, HitNormal);

	//Si MouseInteractionInterface es nulo, significa que el mouse no esta encima de nningun item
	if(MouseInteractionInterface == none)
	{		
		//Si se presiona el boton izquierdo del mouse 
		if(PendingLeftPressed)
		{
			//controlamos que el jugador no este volando y le hacemos disparar
			if(PGame(WorldInfo.Game).bEarthNotFlying)
			{
			pPlayerController = PPlayerController(PlayerOwner);
		
			pPlayerController.StartFire();
			}
			

			//bMouseOverUIElement me dice siestoy encima del propio clip de flash.En talcaso obviamente no podemos actuar encima suyo
			//reload dice si la torreta esta recargada. bTowerActive si esta habilitada por credito
		    if(!pGFx.bMouseOverUIElement && pGFx.reload && pGFx.bTowerActive && pGFx.TTowerActive!=2 )
		    {
				`log("la pgfx ttower active " @pGFx.TTowerActive);
				pPlayerController = PPlayerController(PlayerOwner);

				//Creamos torreta solo si hemos clickado dentro del planeta, no en el skybox (control por distancia)
				dist=Vsize(pPlayerController.Pawn.Location-HitLocation);
				if(dist < pPlayerController.m_DistanciaAlCentro)
				{
					rTorreta=Rotator(-HitNormal); //hacia el suelo
					rTorreta.Pitch+=65535/4; //90 grados parriba
					if(pGFx.TTowerActive==0)
					{
						`log("Vamos a spawnear una torreta ice");
						pPlayerController.StartFire();
						spawn(class'MU_AutoTurret', ,,HitLocation,rTorreta,);
						PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-1000);
						ti=spawn(class'PTurretIce', ,,HitLocation,rTorreta,);
					ti.setNormalSuelo(HitNormal);
					}else{
					tc=spawn(class'PTurretCannon', ,,HitLocation,rTorreta,);
					tc.setNormalSuelo(HitNormal);
					PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos-200);
					}
					//spawn(class'MU_AutoTurret', ,,HitLocation, rTorreta,);
				
					pGFx.SetTowerActive(false);
					pGFX.SetReload(false);
					pGFx.TurretReload();
					

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
//				DistanceToItem = Sqrt((DistanceCheck.X*DistanceCheck.X) + (DistanceCheck.Y*DistanceCheck.Y));

				//Si el panel de interaccion esta visible, cerrarlo
			/*
				if(titGFx.bPanelInteraccionVisible)
				{
					titGFx.HideInteractionPanel();
				}
				//Si el jugador esta cerca del item podra interactuar con el
				else if(DistanceToItem<150)
				{
					//Visualizar el panel de interaccion, en el lugar donde se encuentra el mouse
					titGFx.ShowInteractionPanel(titPlayerInput.MousePosition);
				}*/
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
	foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CachedMouseWorldOrigin + CachedMouseWorldDirection * 65536.f, CachedMouseWorldOrigin,,,TRACEFLAG_Bullet)
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
	TogglePauseMenu();
	
}


//
simulated event Tick(float DeltaTime)
{

	super.Tick(DeltaTime);
pGFx.SetCredito(PGame(WorldInfo.Game).creditos);
if(pGFx.reload &&(PGame(WorldInfo.Game).creditos>=200) )
{
pGFx.SetTurretIdle();
pGFx.SetTowerActive(true);
}

pGFx.AUIVuela(!PGame(WorldInfo.Game).bEarthNotFlying );


	/*
	local ASDisplayInfo DI;
	local int PanelShowSpeed;

	PanelShowSpeed = 40;

	super.Tick(DeltaTime);

	//Ocultar el panel de interaccion poco a poco cuando se quita el raton (si el panel no se esta cerrando)
	//Mientras se va ocultando si se vuelve a pasar el raton, vuelve a ser opaco
	if(titGFx.bPanelInteraccionVisible && !titGFx.bClosingInteractionPanel)
	{				
		DI=titGFx.panelInteraccionMC.GetDisplayInfo();

		if(!titGFx.bMouseOverInteractionPanel)
		{
			DI.Alpha -= DeltaTime*PanelShowSpeed;
			//Cuando la opacidad este a la mitad, ocultar el panel
			if(DI.Alpha<50)
			{
				//DI.Alpha = 0;
				//titGFx.SetInteractionPanelVisible(false);
				titGFx.HideInteractionPanel();
			}
		}
		else
		{
			DI.Alpha += DeltaTime*PanelShowSpeed;
			if(DI.Alpha>100)
			{
				DI.Alpha = 100;
			}
		}

		titGFx.panelInteraccionMC.SetDisplayInfo(DI);
	}
*/
}


defaultproperties
{
	CursorColor=(R=255,G=255,B=255,A=255)
	CursorTexture=Texture2D'EngineResources.Cursors.Arrow'
	UsingScaleform=true
	pauseMenu=false
}

