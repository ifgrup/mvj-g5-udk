class PGFx extends GFxMoviePlayer;

var PHUD pHUD;
//Declaramos las variables para Capturar elementos de la película Flash

//var GFxClikWidget


var GFxObject tdcMC;
var GFxObject tdiceMC;
var GFxObject ctdiceMC;
var GFxObject ctdcMC;
var GFxObject creditoMC;
var GFxObject pelicula;
//variables para capturar ratón y cursores de la pelicula flash
var GFxObject raton;// _clip pelicula que controla el ratón
var GFxObject bcursor;// cursor de la brocha
var GFxObject cice;//cursor del cubito de hielo
var GFxObject cct;//cursor de la torreta cañon 
var GFxObject pmiratierraMC;//  _clip pelicula que controla el ratón punto de mira en la tierra
//
var bool bMouseOverUIElement;
var bool bTowerActive;
var bool reload;

enum TTower
{
	ice,
	cannon,
	ninguna,
	
	
};
var TTower TTowerActive;

//RR






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
 //capturamos de la pelicula flash los objetos y los asignamos a nuestras variables
 pelicula=GetVariableObject("_root");
 raton= GetVariableObject("_root._clip");
 bcursor= GetVariableObject("_root.bcursor");
 cice= GetVariableObject("_root.cice");
 cct= GetVariableObject("_root.cct");
 pmiratierraMC=GetVariableObject("_root.pmiratierra");

bTowerActive=true;
TurretReload();
//RR


	
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

//Funcion que pone la torreta habilitada o deshabilitada
//se llama desde Flash cuando acaba la animación de recarga
//tambien cuando se acaba la pasta, con el parametro a false
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

if(!val)
{
	raton.GotoAndPlay("mirilla");
	
	TTowerActive=2;
}else{
//raton.GotoAndPlay("ctcannon");
}
//raton.SetBool("_visible", val);
 pmiratierraMC.SetBool("_visible", !val);
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
	TTowerActive=2;
}
