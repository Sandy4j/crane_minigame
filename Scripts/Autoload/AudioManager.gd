extends Node

const AUDIO_REGISTRY: Dictionary = {
	# BGM
	"bgm_menu":    "res://Audio/BGM/Crane_Menu.ogg",
	"bgm_action":  "res://Audio/BGM/Crane_Action.ogg",

	# SFX
	"sfx_btn_grab": "res://Audio/SFX/btn grab.ogg",
	"sfx_btn_move": "res://Audio/SFX/btn move.ogg",
	"sfx_btn_hover": "res://Audio/SFX/btn hover.ogg",
	"sfx_btn_netral": "res://Audio/SFX/btn netral.ogg",
	
	"sfx_wire_ascend": "res://Audio/SFX/wire ascend.ogg",
	"sfx_wire_descend": "res://Audio/SFX/wire descend.ogg",
	"sfx_grab_box": "res://Audio/SFX/box grabbed.ogg",
	"sfx_train_move": "res://Audio/SFX/train move.ogg",
	
	"claw_open": "res://Audio/SFX/claw open.ogg",
	"box_platform_hit": "res://Audio/SFX/hitting platform.ogg",
	"box_drop": "res://Audio/SFX/box drop.ogg",
	"montage": "res://Audio/SFX/montage.ogg",
	"fanfare_success": "res://Audio/SFX/fanfare succedd.ogg",
	"fanfare_failed": "res://Audio/SFX/fanfare failed.ogg",
	
	
}

const BGM_TRACKS := ["bgm_menu", "bgm_action"]
const SFX_POOL_SIZE  := 6  # jumlah AudioStreamPlayer paralel untuk SFX
const BGM_VOLUME_MIN := -80.0  # mute

var bgm_volume :=   0.0

var _bgm_players: Array[AudioStreamPlayer] = []
var _active_track := 0

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index := 0
var _streams: Dictionary = {}
var _fade_tween: Tween

var _train_sfx_player: AudioStreamPlayer
var _wire_sfx_player: AudioStreamPlayer

func _ready() -> void:
	for key in BGM_TRACKS:
		var p := AudioStreamPlayer.new()
		p.bus = "BGM"
		p.volume_db = BGM_VOLUME_MIN
		add_child(p)
		_bgm_players.append(p)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_train_sfx_player = AudioStreamPlayer.new()
	_train_sfx_player.bus = "SFX"
	add_child(_train_sfx_player)

	_wire_sfx_player = AudioStreamPlayer.new()
	_wire_sfx_player.bus = "SFX"
	add_child(_wire_sfx_player)

func start_bgm() -> void:
	for i in _bgm_players.size():
		if _bgm_players[i].playing:
			continue
		var stream := _get_stream(BGM_TRACKS[i])
		if stream == null:
			continue
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamMP3:
			stream.loop = true
		_bgm_players[i].stream = stream
		_bgm_players[i].play()

	_bgm_players[_active_track].volume_db = bgm_volume

## Fade out ke track lama, fade in ke track baru
func switch_bgm(key: String, duration := 1.0) -> void:
	var target := BGM_TRACKS.find(key)
	if target == -1:
		push_warning("AudioManager: bgm key tidak dikenal -> '%s'" % key)
		return
	if target == _active_track:
		return

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var from_player := _bgm_players[_active_track]
	var to_player   := _bgm_players[target]

	var from_amp := db_to_linear(from_player.volume_db)
	var target_amp := db_to_linear(bgm_volume)

	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)

	# Fade Out
	_fade_tween.tween_method(
		func(amp: float): from_player.volume_db = linear_to_db(maxf(amp, 0.0001)),
		from_amp, 0.0, duration
	).set_trans(Tween.TRANS_LINEAR)

	# Fade In
	_fade_tween.tween_method(
		func(amp: float): to_player.volume_db = linear_to_db(maxf(amp, 0.0001)),
		0.0, target_amp, duration
	).set_trans(Tween.TRANS_LINEAR)

	# Cleanup volume track lama setelah tween selesai
	_fade_tween.tween_callback(
		func(): from_player.volume_db = BGM_VOLUME_MIN
	).set_delay(duration)

	_active_track = target

func set_bgm_volume(volume_db: float) -> void:
	bgm_volume = volume_db
	_bgm_players[_active_track].volume_db = volume_db

## Play SFX dengan mengambil AudioStream dari pool secara bergiliran
func play_sfx(key: String) -> void:
	var stream := _get_stream(key)
	if stream == null:
		return
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.play()

func play_train_move() -> void:
	var stream := _get_stream("sfx_train_move")
	if stream == null: return
	if _train_sfx_player.stream != stream:
		_train_sfx_player.stream = stream
	if not _train_sfx_player.playing:
		_train_sfx_player.play()

func stop_train_move() -> void:
	if _train_sfx_player.playing:
		_train_sfx_player.stop()

## play sfx khusus wire karena perlu loop saat naik/turun, dan trigger saat mencapai puncak
func play_wire_descend() -> void:
	var stream := _get_stream("sfx_wire_descend")
	if stream == null: return
	if _wire_sfx_player.stream != stream:
		_wire_sfx_player.stream = stream
	if not _wire_sfx_player.playing:
		_wire_sfx_player.play()

func play_wire_ascend() -> void:
	var stream := _get_stream("sfx_wire_ascend")
	if stream == null: return
	if _wire_sfx_player.stream != stream:
		_wire_sfx_player.stream = stream
	if not _wire_sfx_player.playing:
		_wire_sfx_player.play()

func trigger_wire_ascend_end() -> void:
	var stream := _get_stream("sfx_wire_ascend")
	if stream == null: return
	_wire_sfx_player.stream = stream
	_wire_sfx_player.play(1.0)

func stop_wire() -> void:
	if _wire_sfx_player.playing:
		_wire_sfx_player.stop()

## Load audio stream dari file
func _get_stream(key: String) -> AudioStream:
	if _streams.has(key):
		return _streams[key]
	if not AUDIO_REGISTRY.has(key):
		push_warning("AudioManager: key tidak ditemukan -> '%s'" % key)
		return null
	var stream := load(AUDIO_REGISTRY[key]) as AudioStream
	if stream == null:
		push_warning("AudioManager: gagal load -> '%s'" % AUDIO_REGISTRY[key])
		return null
	_streams[key] = stream
	return stream
