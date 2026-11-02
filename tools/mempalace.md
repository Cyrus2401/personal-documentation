# MemPalace — Système de Mémoire IA & Hub Multi-Agents

**MemPalace** est un moteur de mémoire persistante locale et de coordination inter-agents pour les intelligences artificielles de développement (Antigravity, OpenCode, Claude Code, Codex, etc.). Il s'appuie sur une base vectorielle locale (ChromaDB / SQLite) et ne requiert aucune clé API externe.

---

## 1. Emplacements et Fichiers Clés

- **Dépôt source local** : `/var/www/html/Cyrus_Jr/MCP/mempalace`
- **Installation CLI (`uv tool`)** :
  - `mempalace` : `/home/chessou/.local/bin/mempalace`
  - `mempalace-mcp` : `/home/chessou/.local/bin/mempalace-mcp` (serveur MCP complet avec 47 outils)
  - `mempalace-light-mcp` : `/home/chessou/.local/bin/mempalace-light-mcp` (version ultra-légère, 3 outils consolidés)
- **Stockage du palais par défaut** : `~/.mempalace/`

---

## 2. Intégration Antigravity

MemPalace est intégré dans Antigravity via son plugin dédié, son enregistrement MCP global et ses skills :

### A. Plugin Antigravity
- **Emplacement du plugin** : `~/.gemini/config/plugins/mempalace/`
- **Installation / Mise à jour** :
  ```bash
  bash /var/www/html/Cyrus_Jr/MCP/mempalace/hooks/antigravity/install.sh
  ```
- **Hooks d'invocation** :
  - `PreInvocation` (turn 1) : Récupération du contexte L0/L1 via `mempalace wake-up`
  - `PostTurn` : Sauvegarde automatique des décisions et checkpoint via `mempalace_memories_filed_away`

### B. Configuration MCP Antigravity
Fichier `~/.gemini/config/mcp_config.json` :
```json
{
  "mcpServers": {
    "mempalace": {
      "command": "/home/chessou/.local/bin/mempalace-mcp",
      "args": []
    }
  }
}
```

### C. Skills Antigravity
Copiés dans `~/.gemini/config/skills/` :
- `mempalace` : Commandes d'administration, minage, statut, configuration.
- `mempalace-recall` : Protocole de rappel avant réponse (search-before-answer).
- `mempalace-task` : Coordination de tâches asynchrones entre agents via le logstream.

---

## 3. Intégration OpenCode

MemPalace est connecté à OpenCode en tant que serveur MCP local et bibliothèque de compétences :

### A. Configuration MCP OpenCode
Fichier `~/.config/opencode/opencode.json` :
```json
{
  "mcp": {
    "servers": {
      "mempalace": {
        "type": "local",
        "command": [
          "/home/chessou/.local/bin/mempalace-mcp"
        ]
      }
    }
  }
}
```

### B. Skills OpenCode
Copiés dans `~/.config/opencode/skills/` :
- `~/.config/opencode/skills/mempalace`
- `~/.config/opencode/skills/mempalace-recall`
- `~/.config/opencode/skills/mempalace-task`

---

## 4. Commandes CLI Utiles

### Initialiser & Miner un projet
```bash
# Détecter l'arborescence des pièces (rooms)
mempalace init /chemin/vers/projet

# Miner les fichiers de code et de documentation
mempalace mine /chemin/vers/projet

# Miner des conversations ou historiques
mempalace mine /chemin/vers/conversations --mode convos --wing nom_projet

# Balayage de sécurité après édition
mempalace sweep /chemin/vers/projet
```

### Rechercher & Vérifier
```bash
# Recherche sémantique et textuelle
mempalace search "comment fonctionne l'authentification"

# Contexte de réveil (L0 + L1)
mempalace wake-up
mempalace wake-up --wing mon_projet

# Statut global du palais
mempalace status

# Audit de la qualité d'organisation
mempalace audit
```

### Hub Multi-Agents (Serveur Partagé)
```bash
# Lancer le hub pour partager le palais entre plusieurs agents (Antigravity, OpenCode, Claude Code)
mempalace serve --host 127.0.0.1 --port 8765
```

---

## 5. Principaux Outils MCP Disponibles (47 outils)

| Famille | Exemples d'outils | Rôle |
|---|---|---|
| **Palais & Recherche** | `mempalace_search`, `mempalace_status`, `mempalace_get_taxonomy` | Rechercher des souvenirs, vérifier l'état du palais |
| **Tiroirs (Drawers)** | `mempalace_add_drawer`, `mempalace_get_drawer`, `mempalace_update_drawer` | Stocker ou consulter des unités de mémoire textuelles |
| **Graphe de Connaissances** | `mempalace_kg_query`, `mempalace_kg_add`, `mempalace_kg_timeline` | Relations temporelles et faits entre entités |
| **Journal d'Agent (Diary)** | `mempalace_diary_write`, `mempalace_diary_read` | Historique de sessions et résumés en dialecte AAAK |
| **Logstream & Tâches** | `event_append`, `event_wait`, `mempalace_task_create` | Échange d'événements et coordination inter-agents |
