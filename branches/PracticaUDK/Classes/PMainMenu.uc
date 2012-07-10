class PMainMenu extends GFxMoviePlayer;

var GFxClikWidget btnStart,btnExit,btncjugar,btncreditos;
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
		case ('creditos'):
			btncreditos=GFxClikWidget(w);
			
		btncreditos.SetString("label", "Créditos");
			btncreditos.AddEventListener('CLIK_press',OnStartMenuSalir);
			break;
		case ('cjugar'):
			btncjugar=GFxClikWidget(w);
			
		btncjugar.SetString("label", "Como Jugar");
			btncjugar.AddEventListener('CLIK_press',OnStartMenuSalir);
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
    consolecommand("Open Test");
}


DefaultProperties
{
	bDisplayWithHudOff=true
    TimingMode=TM_Real
	bPauseGameWhileActive=false
	bCaptureInput=true
	MovieInfo=SwfMovie'PGameMenuFlash.pmainmenuini'
	WidgetBindings.Add((WidgetName="optionsBtn",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="creditos",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="cjugar",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="exit",WidgetClass=class'GfxClikWidget'));

}
