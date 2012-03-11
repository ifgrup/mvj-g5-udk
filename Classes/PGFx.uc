class PGFx extends GFxMoviePlayer;

var PHUD pHUD;
//Declaramos las variables para Capturar elementos de la película Flash

//var GFxClikWidget


var GFxObject tdcMC;
var GFxObject tdiceMC;
var GFxObject ctdiceMC;
var GFxObject ctdcMC;
var GFxObject creditoMC;
var bool bMouseOverUIElement;
var bool bTowerActive;
var bool reload;

enum TTower
{
	ice,
	cannon,
	
	
};
var TTower TTowerActive;

//RR


var GFxObject panelInteraccionMC;
var GFxObject panelInventarioMC;
var GFxObject botonAyudaMC;
var GFxObject botonInventarioMC;
var GFxObject botonMapaMC;

var bool bPanelInteraccionVisible;

var bool bMouseOverInteractionPanel;
var bool bClosingInteractionPanel;

function Init(optional LocalPlayer LocalPlayer)
{
	//Inicializar la pelicula Scaleform
	super.Init(LocalPlayer);

	//Comenzar a reproducir la pelicula
	Start();
	//Inicializar todos los objetos sin avanzar la pelicula
	Advance(0);

	//Guardar la referencia de varios objetos para acceder a ellos en el futuro
	
tdcMC = GetVariableObject("_root.tdc");

 tdiceMC= GetVariableObject("_root.tdice");
 ctdiceMC= GetVariableObject("_root.ctdice");
 ctdcMC= GetVariableObject("_root.ctdc");
 creditoMC= GetVariableObject("_root.credito");

bTowerActive=true;
TurretReload();
//RR

panelInteraccionMC = GetVariableObject("_root.panelInteraccion");
	panelInventarioMC = GetVariableObject("_root.panelInventario");
	botonAyudaMC = GetVariableObject("_root.ayuda_boton");
	botonInventarioMC = GetVariableObject("_root.mochila_boton");
	botonMapaMC = GetVariableObject("_root.mapa_boton");


	//Al inicio asegurarse de que no sea visible
	if(panelInteraccionMC != none)
	{
		panelInteraccionMC.SetBool("_visible", false);
		bPanelInteraccionVisible = false;
	}
}
//RR
function SetOverUIElement(bool val)
{
	bMouseOverUIElement = val;
	`log("Flash");
}
function SetTowerActive(bool val)
{

bTowerActive=val;

}


function SetTTowerActive(TTower val)
{

TTowerActive=val;
`log("La torre activa es: " @TTowerActive);
}
function TurretReload(){
tdcMC.GotoAndPlay("reload");

}

function SetReload(bool val)
{
	reload=val;
}

function SetTurretIdle()
{
	tdcMC.GotoAndPlay("Idle");
}

function SetCredito(int c)
{
	creditoMC.SetText(c);
}


function AUIVuela(bool val)
{


tdcMC.SetBool("_visible", val);

 tdiceMC.SetBool("_visible", val);
 ctdiceMC.SetBool("_visible", val);
 ctdcMC.SetBool("_visible", val);



}

function PauseMenu(bool val)
{
	tdcMC.SetBool("enabled", val);
	tdiceMC.SetBool("enabled", val);
}



//RR

function SetOverInteractionPanel(bool val)
{
	bMouseOverInteractionPanel = val;
}

function ShowInteractionPanel(IntPoint posicion)
{
	local ASDisplayInfo DI;

	SetInteractionPanelVisible(true);

	//Pasar las coordenadas al display info
	DI.hasX = true;
	DI.X = posicion.X;
	DI.hasY = true;
	DI.Y = posicion.Y;
	//Poner el valor alpha a 100, por si ha cambiado durante el juego
	DI.hasAlpha = true;
	DI.Alpha = 100;
	panelInteraccionMC.SetDisplayInfo(DI);

	//Animacion al aparecer
	panelInteraccionMC.GotoAndPlay("open");

	bClosingInteractionPanel = false;
}

function HideInteractionPanel()
{
	//Cerrando panel de interaccion
	bClosingInteractionPanel = true;
	//Animacion al desaparecer
	panelInteraccionMC.GotoAndPlay("close");
}

//A esta funcion le llama ActionScript, cuando ha finalizado la animacion de cerrar
function PanelCloseAnimationFinished()
{
	SetInteractionPanelVisible(false);
	bClosingInteractionPanel = false;
	
	//Por si acaso poner las variables que controlan la UI a false
	SetOverUIElement(false);
	SetOverInteractionPanel(false);
}

function SetInteractionPanelVisible(bool val)
{
	panelInteraccionMC.SetBool("_visible", val);
	bPanelInteraccionVisible = val;
}

//A esta funcion se le llama desde ActionScript, al hacer click en el boton de coger item
function CogerItem()
{
	local PKActor LastClickedItem;
	local GFxObject slot, gfxIitem;
	local int i;
	local bool bItemGuardado;

	//Guardar la referencia al ultimo item clickado
	LastClickedItem = PKActor(pHUD.LastClickedItem);
	bItemGuardado = false;

	//Encontrar un slot vacio y guardar el item en la variable de ActionScript que representa el inventario
	for (i=0; i<14; i++)
	{
		slot = panelInventarioMC.GetObject("slot"$i);
		if(slot.GetObject("data")==none)
		{
			gfxIitem = panelInventarioMC.GetObject("itemData").GetElementObject(LastClickedItem.ItemIndex);
			slot.SetObject("data", gfxIitem);
			bItemGuardado = true;
			break;
		}
	}

	//Ocultar el panel de interaccion
	HideInteractionPanel();

	//Si el item se ha guardado en el inventario
	if(bItemGuardado)
	{
		//Destruir el item que acabamos de coger
		LastClickedItem.DestroyItem();
	}
}

//A esta evento se le llama desde la pelicula flash
event UpdateMousePosition(float x, float y)
{
	
	local PPlayerInput pPlayerInput;

	if(pHUD != none && pHUD.PlayerOwner != none)
	{
	
		pPlayerInput = PPlayerInput(pHUD.PlayerOwner.PlayerInput);

		if(pPlayerInput != none)
		{
			
			pPlayerInput.SetMousePosition(x,y);
		}
	}
}

DefaultProperties
{
	bDisplayWithHudOff=false
	TimingMode=TM_Game
	MovieInfo=SwfMovie'PGameMenuFlash.PHUD'
	bPauseGameWhileActive=false
}
