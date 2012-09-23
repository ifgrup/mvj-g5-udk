class PGFx extends GFxMoviePlayer;

var PHUD pHUD;
//Declaramos las variables para Capturar elementos de la película Flash

//var GFxClikWidget


var GFxObject tdcMC;
var GFxObject tdiceMC;
var GFxObject ctdiceMC;
var GFxObject ctdcMC;


//variables para capturar ratón y cursores de la pelicula flash

var GFxObject bcursor;// cursor de la brocha
var GFxObject cice;//cursor del cubito de hielo
var GFxObject cct;//cursor de la torreta cañon 

//

// variables para capturar los objetos de la película flash
//botones del HUD
var GFxObject hbt1MC,hbt1icotoMC,hbt1icotrMC; 
var GFxObject hbt2MC,hbt2icotoMC,hbt2icotrMC;
var GFxObject hbt3MC,hbt3icotoMC,hbt3icotrMC;
var GFxObject hbt4MC,hbt4icotoMC,hbt4icotrMC;
var GFxObject camarilloMC,cttorretrampaMC;
var GFxObject creditoMC;
var GFxObject hvidaMC;
var GFxObject pelicula;
var GFxObject raton;// _clip pelicula que controla el ratón
var GFxObject nottorretaMC;// símbolo de prohibido para el ratón 
var GFxObject pmiratierraMC;//  _clip pelicula que controla el ratón punto de mira en la tierra
var GFxObject hudMC;
var GFxObject marcadorMC;

enum Hbt
{
	hbt1,
	hbt2,
	hbt3,
	hbt4,
	ini,
	nob,
};
var Hbt HbtActive;


//Estado de botones
var bool hbt1active,hbt1over,hbt1reload,hbt1disabled;
var int hbt1precio;
var bool hbt2active,hbt2over,hbt2reload,hbt2disabled;
var int hbt2precio;
var bool hbt3active,hbt3over,hbt3reload,hbt3disabled;
var int hbt3precio;
var bool hbt4active,hbt4over,hbt4reload,hbt4disabled;
var int hbt4precio;

//
var bool bMouseOverUIElement;
var bool bTowerActive;
var bool reload;
var bool bMouseOverInteractionPanel;
var bool bClosingInteractionPanel;



//demo GameOver y Mensaje

var GFxObject gameoverMC;
var GFxObject loghudMC;
var GFxObject	tloghudMC;
var GFxClikWidget Btn_menu, Btn_salir;
var bool animLog;
var GFxObject textofinMC;
var GFxObject tutoMC;


function Init(optional LocalPlayer LocalPlayer)
{
	local ASDisplayInfo DI;
	//Inicializar la pelicula Scaleform
	super.Init(LocalPlayer);

	//Comenzar a reproducir la pelicula
	Start();
	//Inicializar todos los objetos sin avanzar la pelicula
	Advance(0);

	//Guardar la referencia de varios objetos para acceder a ellos en el futuro
	//Hud antiguo
/*
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
*/
	//Hud nuevo

/*
	tdcMC = GetVariableObject("_root.nhud.tdc");
	tdiceMC= GetVariableObject("_root.nhud.tdice.itice");
	ctdiceMC= GetVariableObject("_root.nhud.tdice.ctdice");
	ctdcMC= GetVariableObject("_root.nhud.tdc.ctdc");

	//capturamos de la pelicula flash los objetos y los asignamos a nuestras variables
	
	cice= GetVariableObject("_root.nhud.cice");
	cct= GetVariableObject("_root.nhud.cct");
	

	ctdiceMC.SetText("1000");
*/


	hbt1MC=GetVariableObject("_root.nhud.hbt1");
 	hbt1icotoMC=GetVariableObject("_root.nhud.hbt1.hbt1icoto");
 	hbt1icotrMC=GetVariableObject("_root.nhud.hbt1.hbt1icotr");
	hbt2MC=GetVariableObject("_root.nhud.hbt2");
 	hbt2icotoMC=GetVariableObject("_root.nhud.hbt2.hbt2icoto");
 	hbt2icotrMC=GetVariableObject("_root.nhud.hbt2.hbt2icotr");
	hbt3MC=GetVariableObject("_root.nhud.hbt3");
 	hbt3icotoMC=GetVariableObject("_root.nhud.hbt3.hbt3icoto");
 	hbt3icotrMC=GetVariableObject("_root.nhud.hbt3.hbt3icotr");
	hbt4MC=GetVariableObject("_root.nhud.hbt4");
 	hbt4icotoMC=GetVariableObject("_root.nhud.hbt4.hbt4icoto");
 	hbt4icotrMC=GetVariableObject("_root.nhud.hbt4.hbt4icotr");



	 camarilloMC=GetVariableObject("_root.nhud.camarillo");
	 cttorretrampaMC=GetVariableObject("_root.nhud.camarillo.cttorretrampa");
	 hvidaMC=GetVariableObject("_root.nhud.hvida");

	pmiratierraMC=GetVariableObject("_root.pmiratierra");
	pelicula=GetVariableObject("_root");
	raton= GetVariableObject("_root._clip");
	nottorretaMC= GetVariableObject("_root._clip.nottorreta");
	bcursor= GetVariableObject("_root.bcursor");
	creditoMC= GetVariableObject("_root.nhud.credito");
	hudMC=GetVariableObject("_root.nhud");
	marcadorMC=GetVariableObject("_root.nhud.marcador");
	//Hud nuevo

//demo


 gameoverMC=GetVariableObject("_root.gameover");
 textofinMC=GetVariableObject("_root.gameover.textofin");
 loghudMC=GetVariableObject("_root.loghud");
 tutoMC=GetVariableObject("_root.tuto");
	tloghudMC=GetVariableObject("_root.loghud.conlog.tloghud");

loghudMC.SetBool("_visible", false);
tutoMC.SetBool("_visible", false);
animLog=true;


//demo



	bTowerActive=true;
	HbtActive=ini;
	TurretReload();
	
	
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


function SetHbtActive(Hbt val)
{
	
	switch (val)
			{
				case hbt1:
					if(!hbt1disabled)
					{
					hbt1MC.GotoAndPlay("idle");
					hbt1active=true;
					    hbt1reload=true;
					hbt2active=false;
					hbt3active=false;
					hbt4active=false;
					HbtActive=val;
					}
					break;

				case hbt2:
					if(!hbt2disabled)
					{
					hbt2MC.GotoAndPlay("idle");
					hbt1active=false;
					hbt2active=true;
						hbt2reload=true;
					hbt3active=false;
					hbt4active=false;
					HbtActive=val;
					}
					break;

				case hbt3:
					if(!hbt3disabled)
					{
					hbt3MC.GotoAndPlay("idle");
					hbt1active=false;
					hbt2active=false;
					hbt3active=true;
					    hbt3reload=true;
					hbt4active=false;
					HbtActive=val;
					}
					break;
				case hbt4:
					if(!hbt4disabled)
					{
					hbt4MC.GotoAndPlay("idle");
					hbt1active=false;
					hbt2active=false;
					hbt3active=false;
					hbt4active=true;
						hbt4reload=true;
					HbtActive=val;
					}
					break;
			
				case ini:
					/*hbt1active=false;
					hbt2active=false;
					hbt3active=false;
					hbt4active=false;*/
					break;
			}



	cttorretrampaMC.SetText(PrecioHbtActive());
	camarilloMC.GotoAndPlay(string(HbtActive));



`log("La torre activa es: " @HbtActive);



}
function TurretReload()
{
	switch (HbtActive)
			{
				case hbt1:
					hbt1reload=false;
					hbt1MC.GotoAndPlay("reload");
					
					break;

				case hbt2:
					hbt2reload=false;
				hbt2MC.GotoAndPlay("reload");
					
					break;

				case hbt3:
					hbt3reload=false;
					hbt3MC.GotoAndPlay("reload");
					
					break;
				case hbt4:
					hbt4reload=false;
					hbt4MC.GotoAndPlay("reload");
					
					break;
			
				case ini:
					hbt1reload=false;
					hbt2reload=false;
					hbt3reload=false;
					hbt4reload=false;
					hbt1MC.GotoAndPlay("reload");
					
					hbt2MC.GotoAndPlay("reload");
					
					hbt3MC.GotoAndPlay("reload");
					
					hbt4MC.GotoAndPlay("reload");
					
					break;
			}

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
	/*switch (HbtActive)
			{
				case ice:
					tdiceMC.GotoAndPlay("Idle");
					break;

				case cannon:
					tdcMC.GotoAndPlay("Idle");
					
					break;

				case ninguna:
					
					break;

			
				default:
					break;
			}


	*/
}

function SetHbtDisabled(Hbt boton,bool val)
{
		switch (boton)
			{
				case hbt1:
					hbt1disabled=val;
					if(hbt1disabled)
					{
					hbt1MC.GotoAndPlay("Disabled");
					if(HbtActive==hbt1)HbtActive=nob;
					}else{
						if(hbt1reload)hbt1MC.GotoAndPlay("idle");
					
					}
					break;

				case hbt2:
				hbt2disabled=val;
					if(hbt2disabled)
					{
					hbt2MC.GotoAndPlay("Disabled");
					if(HbtActive==hbt2)HbtActive=nob;
					}else{
					if(hbt2reload)hbt2MC.GotoAndPlay("idle");
					}
					break;
					
				case hbt3:
					hbt3disabled=val;
					if(hbt3disabled)
					{
					hbt3MC.GotoAndPlay("Disabled");
					if(HbtActive==hbt3)HbtActive=nob;
					}else{
					
					if(hbt3reload)hbt3MC.GotoAndPlay("idle");
					}
					break;
				case hbt4:
					hbt4disabled=val;
					if(hbt4disabled)
					{
					hbt4MC.GotoAndPlay("Disabled");
					if(HbtActive==hbt4)HbtActive=nob;
					}else{
						
					if(hbt4reload)hbt4MC.GotoAndPlay("idle");
					}
					break;
			
				
			}



}
function SetHbtReload(int boton,bool val)
{
	switch (boton)
			{
					case 0:
					
					hbt1reload=val;
					break;

					case 1:
			
					hbt2reload=val;
					break;

					case 2:
					
					hbt3reload=val;
					break;
					case 3:
				
					hbt4reload=val;
					break;
			
			/*	case ini:
					
					hbt1reload=val;
					
					hbt2reload=val;
					
					hbt3reload=val;
					
					hbt4reload=val;
					break;*/
			}


}

function SetHbtOver(Hbt boton,bool val)
{
	
	
	switch (boton)
			{
				case hbt1:
					if(!hbt1active)
					{   
						if(val)
						{
						cttorretrampaMC.SetText(string(hbt1precio));
						camarilloMC.GotoAndPlay("hbt1");
						hbt1MC.GotoAndPlay("over");
						
						}else{
						hbt1MC.GotoAndPlay("idle");
						cttorretrampaMC.SetText(PrecioHbtActive());
						camarilloMC.GotoAndPlay(string(HbtActive));
						
						}
					}
					break;

					case hbt2:
					if(!hbt2active)
					{   
						if(val)
						{
						cttorretrampaMC.SetText(string(hbt2precio));
						camarilloMC.GotoAndPlay("hbt2");
						hbt2MC.GotoAndPlay("over");
						
						}else{
						hbt2MC.GotoAndPlay("idle");
						cttorretrampaMC.SetText(PrecioHbtActive());
						camarilloMC.GotoAndPlay(string(HbtActive));
						
						}
					
					}

					break;

					case hbt3:
					if(!hbt3active)
					{   
						if(val)
						{
						cttorretrampaMC.SetText(string(hbt3precio));
						camarilloMC.GotoAndPlay(string(boton));
						hbt3MC.GotoAndPlay("over");
						
						}else{
						hbt3MC.GotoAndPlay("idle");
						cttorretrampaMC.SetText(PrecioHbtActive());
						camarilloMC.GotoAndPlay(string(HbtActive));
						
						}
					
					}

					break;
					case hbt4:
					if(!hbt4active)
					{   
						if(val)
						{
						cttorretrampaMC.SetText(string(hbt4precio));
						camarilloMC.GotoAndPlay(string(boton));
						hbt4MC.GotoAndPlay("over");
						
						}else{
						hbt4MC.GotoAndPlay("idle");
						cttorretrampaMC.SetText(PrecioHbtActive());
						camarilloMC.GotoAndPlay(string(HbtActive));
						
						}
					
					}

					break;
				default:
					break;
			}



	//`log("botón over" @boton);
		//`log("botón over valor" @val);





}

function SetCredito(int c)
{
	creditoMC.SetText(c);
	
}

/*function SetPrecioTorretas(int ice,int fire, int ca,int plas)
{
	ctdiceMC.SetText(ice);
	ctdcMC.SetText(fire);


}*/
function AUIVuela(bool val)
{

	if(!val)
	{
		raton.GotoAndPlay("mirilla");
		HbtActive=0;
	
	}else{
	//raton.GotoAndPlay("ctcannon");

	}

	hbt1icotoMC.SetBool("_visible", val);
		//hbt1icotrMC.SetBool("_visible", val);
	hbt2icotoMC.SetBool("_visible", val);
	hbt2icotrMC.SetBool("_visible", !val);
	hbt3icotoMC.SetBool("_visible", val);
	hbt3icotrMC.SetBool("_visible", !val);
	hbt4icotoMC.SetBool("_visible", val);
	hbt4icotrMC.SetBool("_visible", !val);

	raton.SetBool("_visible", val);
	pmiratierraMC.SetBool("_visible", !val);



//tdcMC.SetBool("_visible", val);

 //tdiceMC.SetBool("_visible", val);
 //ctdiceMC.SetBool("_visible", val);
 //ctdcMC.SetBool("_visible", val);



}

function PauseMenu(bool val)
{
	//tdcMC.SetBool("enabled", val);
	//tdiceMC.SetBool("enabled", val);
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

function string PrecioHbtActive()
{
	local string precio;

	switch (HbtActive)
			{
				case hbt1:
					precio=string(hbt1precio);

					break;

				case hbt2:
					precio=string(hbt2precio);
					
					break;

				case hbt3:
					precio=string(hbt3precio);
					break;
				case hbt4:
					precio=string(hbt4precio);
					break;
			
				default:
					precio="0";
					break;
			}

			return precio;

}






//demo


event bool WidgetInitialized(name WN,name WP, GFxObject w)
{
	
	switch(WN)
	{
		case ('menu'):
			Btn_menu=GFxClikWidget(w);
			
			Btn_menu.SetString("label", "Menú");
			Btn_menu.AddEventListener('CLIK_press',OnPressMenuButton);
			break;

			case ('salir'):
			Btn_salir=GFxClikWidget(w);
			
			Btn_salir.SetString("label", "Salir");
			Btn_salir.AddEventListener('CLIK_press',OnPressExitButton);
			break;
			
		default:
			break;

	}
	return true;
}




function OnPressExitButton(GFxClikWidget.EventData ev)
{
	//UTPlayerController(GetPC()).QuitToMainMenu();	
	ConsoleCommand("exit");
}
function OnPressMenuButton(GFxClikWidget.EventData ev)
{
	//UTPlayerController(GetPC()).QuitToMainMenu();	
	ConsoleCommand("Open PGameMenuini");
}


 function GameOver()
{
	gameoverMC.SetBool("_visible", true);




}

function MensajitoPotPantalla(string texto)
{
	SetAnimLog(false);
	loghudMC.SetBool("_visible", true);
	loghudMC.GotoAndPlay("reload");
	tloghudMC.SetText(texto);
	tutoMC.SetBool("_visible", true);


}
function SetAnimLog(bool val)
{
	animLog=val;
}




DefaultProperties
{
	bDisplayWithHudOff=false
	TimingMode=TM_Game
	//antiguo
	//MovieInfo=SwfMovie'PGameMenuFlash.PHUD'
	//nuevo
	MovieInfo=SwfMovie'PGameMenuFlash.nhud'
	bPauseGameWhileActive=false
	hbt1precio=200
	hbt2precio=400
	hbt3precio=500
	hbt4precio=2000
	HbtActive=ini

	IconsPenemyCount=0
	//demo


	WidgetBindings.Add((WidgetName="menu",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="salir",WidgetClass=class'GfxClikWidget'));
}
