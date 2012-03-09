class PMainMenu extends GFxMoviePlayer;

var GFxClikWidget btnStart;
var GFxObject MainMenuTitle;

function bool Start(optional bool startPaused=false)
{
	super.Start();
	Advance(0);
    MainMenuTitle=GetVariableObject("_root.textField");
	MainMenuTitle.SetText("Marikaaaaaa");

	return true;
}


event bool WidgetInitialized(name WN,name WP, GFxObject w)
{
	switch(WN)
	{
		case ('optionsBtn'):
			btnStart=GFxClikWidget(w);
			btnStart.AddEventListener('CLIK_click',OnStartMenuTUPUTAMADRE);
			break;
		default:
			break;

	}
	return true;
}

function OnStartMenuTUPUTAMADRE(GFxClikWidget.EventData ev)
{
MainMenuTitle.SetText("PUSAL");
	`Log("TUPUTA PUSAL");

	OpenGame();
}


function OpenGame()
{
    SetPause(false);
    close(true);
    consolecommand("Open PGamePlanet02");
}


DefaultProperties
{

	//MovieInfo=SwfMovie'UDNHud.UI_QuickStart'
	//MovieInfo=SwfMovie'FishtrosGameMenu.menu0'

//SwfMovie'SimpleTorus.menu00'
MovieInfo=SwfMovie'PGameMenuFlash.menu00'
 WidgetBindings.Add((WidgetName="optionsBtn",WidgetClass=class'GfxClikWidget'));


bDisplayWithHudOff=TRUE
    TimingMode=TM_Real
	bPauseGameWhileActive=TRUE
	bCaptureInput=true

}
