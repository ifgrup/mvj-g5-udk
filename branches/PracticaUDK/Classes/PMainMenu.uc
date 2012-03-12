class PMainMenu extends GFxMoviePlayer;

var GFxClikWidget btnStart,btnExit;
var GFxObject MainMenuTitle;

function bool Start(optional bool startPaused=false)
{
	super.Start();
	Advance(0);
    MainMenuTitle=GetVariableObject("_root.textField");
	MainMenuTitle.SetText("FishTros Game");

	return true;
}


event bool WidgetInitialized(name WN,name WP, GFxObject w)
{
	
	switch(WN)
	{
		case ('optionsBtn'):
			btnStart=GFxClikWidget(w);
			
		btnStart.SetString("label", "Jugar");
			btnStart.AddEventListener('CLIK_press',OnStartMenuTUPUTAMADRE);
			break;
		case ('exit'):
			btnExit=GFxClikWidget(w);
			
		btnExit.SetString("label", "Salir");
			btnExit.AddEventListener('CLIK_press',OnStartMenuSalir);
			break;


		default:
			break;

	}
	return true;
}

function OnStartMenuTUPUTAMADRE(GFxClikWidget.EventData ev)
{
//MainMenuTitle.SetText("PUSAL");
	//`Log("TUPUTA PUSAL");

	OpenGame();
}

function OnStartMenuSalir(GFxClikWidget.EventData ev)
{

consolecommand("exit");
}

function OpenGame()
{
    SetPause(false);
    close(true);
    consolecommand("Open PGamePlanet01");
}


DefaultProperties
{
	bDisplayWithHudOff=true
    TimingMode=TM_Real
	bPauseGameWhileActive=true
	bCaptureInput=true
	MovieInfo=SwfMovie'PGameMenuFlash.menu00'
	WidgetBindings.Add((WidgetName="optionsBtn",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="exit",WidgetClass=class'GfxClikWidget'));

}
