class PGameSonidos extends Actor
	placeable;

enum SONIDOS
{
    GIRU_ANDA,
    GIRO_SALTA,
	GIRU_DISPARA,
	GIRU_MUERE,
	GIRU_PUPITA,
	GIRU_VUELA,
	GIRU_VUELA_ESPACIO,
	GIRU_CAE_SUELO,
	GIRU_CONTRA_MINION,
	GIRU_CONTRA_TORRETA,
	MINION_CONGELADO,
	TORRETA_ICE_DISPARA,
	TORRETA_CANON_DISPARA,
	OGRO_ARRASTRANDO_PIE,
	OGRO_RAYO_IRA,
	ALARMA_CASA,
	TORRETA_DESTROZADA,
	TONYAZO_ARBOL,
	KAMI_TOPOTA,
	KAMI_MOCO
};

var Array<SoundCue> m_sonidos;

function SoundCue TocalaOtraVezSam(SONIDOS sonido)
{
	return m_sonidos[sonido];
	
}

DefaultProperties
{
	m_sonidos(GIRU_ANDA)=SoundCue'PGameMusicrr.Giruanespacio'
	m_sonidos(GIRO_SALTA)=SoundCue'PGameMusicrr.GirusaltaFcue'
	m_sonidos(GIRU_DISPARA)=SoundCue'PGameMusicrr.disparogiru_cue'
	m_sonidos(GIRU_MUERE)= SoundCue'PGameMusicrr.GiruMuere_Cue'// no lo encuentro
	m_sonidos(GIRU_PUPITA) = SoundCue'PGameMusicrr.GiruRecibe_Cue'
	m_sonidos(GIRU_VUELA)=SoundCue'PGameMusicrr.Giruvuela'
	m_sonidos(GIRU_VUELA_ESPACIO)=SoundCue'PGameMusicrr.Giruanespacio'
	m_sonidos(GIRU_CAE_SUELO)=SoundCue'PGameMusicrr.TonyazoSuelo_Cue'
	m_sonidos(GIRU_CONTRA_MINION)=SoundCue'PGameMusicrr.contra_minion_Cue'
	m_sonidos(GIRU_CONTRA_TORRETA)=SoundCue'PGameMusicrr.contra_minion_Cue'
	m_sonidos(MINION_CONGELADO)= SoundCue'PGameMusicrr.ice-cracking-01_Cue'
	m_sonidos(TORRETA_ICE_DISPARA)=SoundCue'PGameMusicrr.disparotorretahielo5_Cue'
	m_sonidos(TORRETA_CANON_DISPARA)=SoundCue'PGameMusicrr.DisparoCannon_Cue'
	m_sonidos(OGRO_ARRASTRANDO_PIE)=SoundCue'PGameMusicrr.OgroCamina_Cue'
	m_sonidos(OGRO_RAYO_IRA)=SoundCue'PGameMusicrr.OgroIra_Cue'
	m_sonidos(ALARMA_CASA)=SoundCue'PGameMusicrr.AlarmaScoutCasa_Cue'
	m_sonidos(TORRETA_DESTROZADA)=SoundCue'PGameMusicrr.TorretaRebentada_Cue'
	m_sonidos(TONYAZO_ARBOL)=SoundCue'PGameMusicrr.tonyazoarbol'
	m_sonidos(KAMI_TOPOTA)=SoundCue'PGameMusicrr.BanzaiTopota_Cue'
	m_sonidos(KAMI_MOCO)=SoundCue'PGameMusicrr.BanzaiMoco_Cue'
}