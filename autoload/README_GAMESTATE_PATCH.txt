PATCH: valores base con fire_rate bajo
En tu archivo `res://autoload/GameState.gd`, dentro de `_reset_stats()`,
sustituye el diccionario `player_stats` por:

player_stats = {
    "health": 100,
    "armor": 0,
    "speed": 8.0,
    "fire_rate": 2.0,  # antes 5.0 -> más difícil de inicio
    "damage": 1
}
