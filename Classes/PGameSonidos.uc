class PGameSonidos extends Actor
	placeable;

enum SONIDOS
{
    GIRU_ANDA,
    GIRO_SALTA,
	GIRU_DISPARA,
	GIRU_MUERE,
	GIRU_VUELA,
	GIRU_VUELA_ESPACIO,
	GIRU_CAE_SUELO,
	MINION_CONGELADO,
	TORRETA_ICE_DISPARA,
	TORRETA_CANON_DISPARA,
	OGRO_RUGIENDO_IRA,
	OGRO_ARRASTRANDO_PIE,
	OGRO_RAYO_IRA,
	ALARMA_CASA,
	TORRETA_DESTROZADA,
	TONYAZO_ARBOL
};

var Array<SoundCue> m_sonidos;

function SoundCue TocalaOtraVezSam(SONIDOS sonido)
{
	return m_sonidos[sonido];
	
}

DefaultProperties
{
	m_sonidos(0)=SoundCue'PGameMusicrr.Giruanespacio'
	m_sonidos(1)=SoundCue'PGameMusicrr.GirusaltaFcue'
	m_sonidos(2)=SoundCue'PGameMusicrr.disparogiru_cue'
	//m_sonidos(3)= // no lo encuentro
	m_sonidos(4)=SoundCue'PGameMusicrr.Giruvuela'
	m_sonidos(5)=SoundCue'PGameMusicrr.Giruanespacio'
	m_sonidos(6)=SoundCue'PGameMusicrr.TonyazoSuelo_Cue'
	m_sonidos(7)= SoundCue'PGameMusicrr.ice-cracking-01_Cue'
	m_sonidos(8)=SoundCue'PGameMusicrr.disparotorretahielo5_Cue'
	m_sonidos(9)=SoundCue'PGameMusicrr.DisparoCannon_Cue'
	//m_sonidos(10)= // Se tiene que grabar
	//m_sonidos(11)= // Se tiene que grabar
	m_sonidos(12)=SoundCue'PGameMusicrr.Thunder_Cue'
	m_sonidos(13)=SoundCue'PGameMusicrr.AlarmaScoutCasa_Cue'
	m_sonidos(14)=SoundCue'PGameMusicrr.TorretaRebentada_Cue'
	m_sonidos(15)=SoundCue'PGameMusicrr.tonyazoarbol'
}