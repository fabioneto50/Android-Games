extends RefCounted
class_name GridFlowAccountManager

const ACCOUNTS_PATH := "user://gridflow_accounts.json"
const SESSION_PATH := "user://gridflow_session.json"

var current_user: String = ""

func create_account(identifier: String, password: String) -> Dictionary:
    var normalized := _normalize_identifier(identifier)
    if normalized.length() < 3:
        return {"ok": false, "message": "O utilizador ou e-mail deve ter pelo menos 3 caracteres."}
    if password.length() < 4:
        return {"ok": false, "message": "A palavra-passe deve ter pelo menos 4 caracteres."}

    var accounts := _load_accounts()
    if accounts.has(normalized):
        return {"ok": false, "message": "Já existe uma conta com esse utilizador ou e-mail."}

    var salt := _new_salt()
    accounts[normalized] = {
        "salt": salt,
        "password_hash": _hash_password(password, salt),
        "created_at": Time.get_unix_time_from_system()
    }
    if not _write_json(ACCOUNTS_PATH, accounts):
        return {"ok": false, "message": "Não foi possível guardar a conta neste dispositivo."}

    current_user = normalized
    _save_session()
    return {"ok": true, "message": "Conta criada com sucesso."}

func login(identifier: String, password: String) -> Dictionary:
    var normalized := _normalize_identifier(identifier)
    var accounts := _load_accounts()
    if not accounts.has(normalized):
        return {"ok": false, "message": "Conta não encontrada."}

    var entry: Dictionary = accounts[normalized]
    var salt := String(entry.get("salt", ""))
    var expected := String(entry.get("password_hash", ""))
    if _hash_password(password, salt) != expected:
        return {"ok": false, "message": "Palavra-passe incorreta."}

    current_user = normalized
    _save_session()
    return {"ok": true, "message": "Sessão iniciada."}

func logout() -> void:
    current_user = ""
    if FileAccess.file_exists(SESSION_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))

func get_last_identifier() -> String:
    if not FileAccess.file_exists(SESSION_PATH):
        return ""
    var data := _read_json(SESSION_PATH)
    return String(data.get("last_user", ""))

func has_save() -> bool:
    if current_user.is_empty():
        return false
    return FileAccess.file_exists(_save_path())

func save_game(data: Dictionary) -> bool:
    if current_user.is_empty():
        return false
    var wrapper := {
        "user": current_user,
        "saved_at": Time.get_unix_time_from_system(),
        "game": data
    }
    return _write_json(_save_path(), wrapper)

func load_game() -> Dictionary:
    if current_user.is_empty() or not FileAccess.file_exists(_save_path()):
        return {}
    var wrapper := _read_json(_save_path())
    var game: Variant = wrapper.get("game", {})
    return game as Dictionary if game is Dictionary else {}

func delete_save() -> void:
    if current_user.is_empty():
        return
    var path := _save_path()
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _normalize_identifier(identifier: String) -> String:
    return identifier.strip_edges().to_lower()

func _save_path() -> String:
    return "user://gridflow_save_%s.json" % _identifier_key(current_user)

func _identifier_key(value: String) -> String:
    var context := HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    context.update(value.to_utf8_buffer())
    return context.finish().hex_encode().substr(0, 24)

func _new_salt() -> String:
    var crypto := Crypto.new()
    return crypto.generate_random_bytes(16).hex_encode()

func _hash_password(password: String, salt: String) -> String:
    var context := HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    context.update((salt + "|" + password).to_utf8_buffer())
    return context.finish().hex_encode()

func _load_accounts() -> Dictionary:
    if not FileAccess.file_exists(ACCOUNTS_PATH):
        return {}
    return _read_json(ACCOUNTS_PATH)

func _save_session() -> void:
    _write_json(SESSION_PATH, {"last_user": current_user})

func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed as Dictionary if parsed is Dictionary else {}

func _write_json(path: String, data: Dictionary) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.close()
    return true
