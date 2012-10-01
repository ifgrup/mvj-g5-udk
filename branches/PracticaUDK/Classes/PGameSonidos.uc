class PGameSonidos extends Actor
	placeable;

enum SONIDOS
{
    GIRU_ANDA,
    GIRO_SALTA,
	GIRU_DISPARA,
	GIRU_MUERE,
	GIRU_VUELA,
	GIRU_CAE_SUELO,
	
	MINION_CONGELADO,
	TORRETA_ICE_DISPARA,
	TORRETA_CANON_DISPARA,

	OGRO_RUGIENDO_IRA,
	OGRO_ARRASTRANDO_PIE,
	OGRO_RAYO_IRA,

	ALARMA_CASA,
	TORRETA_DESTROZADA
};

var Array<SoundCue> m_sonidos;

function TocalaOtraVezSam(SONIDOS sonido)
{
	PlaySound(m_sonidos[sonido]);
	
}

DefaultProperties
{
	m_sonidos(0)=SoundCue'PGameSounds.CUES.PSonido_disparotorretahielo2'
	m_sonidos(1)=SoundCue'PGameSounds.CUES.PSonido_GiruSaltaF'
	m_sonidos(2)=SoundCue'PGameSounds.CUES.PSonido_disparoGiru'
	m_sonidos(3)= // no lo encuentro
	m_sonidos(4)=SoundCue'PGameSounds.CUES.PSonidos_GiruSaltaF3'
	m_sonidos(5)=SoundCue'PGameSounds.CUES.PSonidos_TonyazoSuelo'
	m_sonidos(6)= // error al importar
	m_sonidos(7)=SoundCue'PGameSounds.CUES.PSonidos_disparotorretahielo5'
	m_sonidos(8)=SoundCue'PGameSounds.CUES.PSonidos_DisparoCannon'
	m_sonidos(9)= // Se tiene que grabar
	m_sonidos(10)= // Se tiene que grabar
	m_sonidos(11)=SoundCue'PGameSounds.CUES.PSonidos_Rayaco'
	m_sonidos(12)=SoundCue'PGameSounds.CUES.PSonidos_AlarmaScoutCasa'
	m_sonidos(13)=SoundCue'PGameSounds.CUES.PSonidos_TorretaRebentada'
}