# SideloadHub

Hub local pour **mettre à jour tes apps sideloadées** sans recâbler l'iPhone à chaque fois.

## Architecture

```
[PC Windows]  LAN-HUB.bat  →  serveur HTTP :8765  →  IPAs + API
       ↑                                              ↓
       └────────────  app SideloadHub iPhone  ────────┘
```

## Sur le PC (Windows)

### Démarrage rapide

1. (Optionnel) Token GitHub pour sync auto :
   ```powershell
   $env:GITHUB_TOKEN = "ghp_..."
   ```
2. Double-clique **`LAN-HUB.bat`**
3. Note l'IP affichée (ex: `192.168.1.42:8765`)

Le serveur :
- Télécharge les derniers IPA depuis GitHub Actions (PSNTrophyTracker, NetworkRadar…)
- Expose une page web + API JSON
- Sert les fichiers sur le réseau local

### Ajouter une app

Édite `server/config/apps.json` et relance le hub.

### Scripts

| Fichier | Rôle |
|---------|------|
| `LAN-HUB.bat` | Sync + serveur LAN |
| `SYNC-HUB.bat` | Sync GitHub uniquement |

## Sur l'iPhone

1. Installe **SideloadHub.ipa** (première fois via Sideloadly)
2. Ouvre l'app → entre l'IP du PC
3. Télécharge les mises à jour en 1 tap
4. **Partager → AltStore** (si AltServer tourne sur le PC)

### Suivi expiration (7 jours)

Après chaque install, appuie sur **« J'ai installé »** pour reset le compte à rebours.

## API

- `GET /api/v1/health`
- `GET /api/v1/catalog`
- `GET /api/v1/apps/{id}/download`

## Build IPA app iOS

GitHub Actions → **Build iOS IPA (Sideload)** → artifact `SideloadHub-ipa`

## Limites iOS

Apple n'autorise pas l'installation silencieuse d'IPA par une app tierce. SideloadHub **télécharge et prépare** l'install — la dernière étape passe par **AltStore** (WiFi) ou **Sideloadly**.
