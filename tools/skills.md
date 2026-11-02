# Skills & Tools

Inventaire complet des capacités de l'agent : outils (outils natifs, MCP, navigateur) et skills (bibliothèque de compétences chargées à la demande via l'outil `skill`).

> **Skill** = instructions spécialisées chargées dans le contexte à la demande (`skill(id)`), pas du code exécutable.
> **Tool** = fonction appelable par l'agent (dans Code Mode : via `execute` vers `tools.<namespace>.<nom>()`).
> **Liste figée au 2026-11-02.** À régénérer quand les serveurs MCP ou les skills installés changent.

---

## 1. Outils natifs (harness)

| Outil | Rôle |
|---|---|
| `read` | Lire un fichier (texte, image, PDF) avec numéros de ligne, ou lister un répertoire. |
| `edit` | Remplacer un extrait exact dans un fichier (édition ciblée). |
| `write` | Créer ou écraser entièrement un fichier. |
| `glob` | Trouver des fichiers par motif (ex. `**/*.ts`). |
| `grep` | Rechercher une regex/texte dans le contenu des fichiers (ripgrep). |
| `shell` | Exécuter des commandes shell (foreground/background, timeout). |
| `execute` | Exécuter du JavaScript en "Code Mode" pour chaîner les outils MCP et `fetch`. |
| `skill` | Charger les instructions d'un skill de la bibliothèque. |
| `subagent` | Déléguer à un agent enfant (`explore` ou `general`), en avant-plan ou arrière-plan. |
| `question` | Poser une question à l'utilisateur avec des options. |
| `webfetch` | Récupérer une URL (texte, markdown ou HTML). |
| `websearch` | Recherche web. |

---

## 2. Outils MCP par serveur

### 2.1 `browser` — navigateur Desktop (contrôle réel de Chromium, onglet par `tabID`)

**Onglets & navigation**
- `tabs.list` / `tabs.open` / `tabs.close` / `tabs.focus` : gérer les onglets et le focus dans le panneau Review.
- `navigate` : aller à une URL. `back`, `forward`, `reload`, `stop` : historique et chargement.
- `wait` : attendre le chargement ou l'apparition/disparition d'un texte.
- `frames` : lister les frames (y compris cross-origin).
- `preview` : afficher un fichier local à l'utilisateur dans le panneau Review.

**Interaction**
- `snapshot` : arbre d'accessibilité avec refs (base de toute action).
- `find` : rechercher du texte dans un snapshot frais.
- `click` : clic (simple/double/droit/milieu + modificateurs).
- `hover`, `drag` : survol, glisser-déposer.
- `fill`, `fill_form`, `check`, `select` : remplir champs, cases/radios, listes déroulantes.
- `press` : touche ou combinaison (ex. `Control+A`).
- `scroll` : défilement en pixels CSS.
- `dialog` : accepter/refuser `alert`/`confirm`/`prompt`.
- `screenshot` : capture viewport, page entière ou élément.

**Fichiers & réseau**
- `files.list` / `files.get` / `files.upload` / `files.drop` : téléchargements, upload de fichiers serveur, drag-drop de fichiers (max 5 Mio).
- `network.list` / `network.get` : requêtes capturées et détail (en-têtes/corps).
- `console` : messages console et erreurs non capturées.

**Diagnostic & performance**
- `evaluate` : évaluer du JS dans la page/frame (retour JSON-sérialisable).
- `lighthouse` : audit accessibilité/SEO/bonnes pratiques.
- `cpu.start` / `cpu.stop` / `cpu.analyze` : profilage CPU JS (max 30 s).
- `trace.start` / `trace.stop` / `trace.analyze` : trace Chromium (tâches longues, scripting/rendering/painting).
- `heap.snapshot` / `heap.summary` / `heap.compare` / `heap.query` / `heap.object` : analyse mémoire (fuites).

### 2.2 `playwright` — navigateur automatisé (tests/exploration)

- `browser_navigate`, `browser_navigate_back`, `browser_tabs`, `browser_close`.
- `browser_snapshot` (arbre d'accessibilité, préféré au screenshot), `browser_find`.
- `browser_click`, `browser_type`, `browser_fill_form`, `browser_select_option`, `browser_hover`, `browser_drag`, `browser_drop`, `browser_press_key`, `browser_file_upload`.
- `browser_wait_for`, `browser_handle_dialog`, `browser_resize`, `browser_emulate_media` (dark/light…).
- `browser_evaluate`, `browser_take_screenshot`.
- `browser_console_messages`, `browser_network_requests`, `browser_network_request`.
- `browser_run_code_unsafe` : exécuter du Playwright brut ( équivalent RCE).

### 2.3 `filesystem` — accès fichiers (répertoires autorisés uniquement)

- `list_allowed_directories` : répertoires accessibles.
- `list_directory`, `list_directory_with_sizes`, `directory_tree` : explorer.
- `read_file` (déprécié), `read_text_file`, `read_multiple_files`, `read_media_file` (image/audio/base64).
- `write_file`, `edit_file` (diff git-style), `create_directory`, `move_file` (déplacer/renommer).
- `search_files` : recherche récursive par glob.

### 2.4 `context7` — documentation à jour des bibliothèques

- `resolve-library-id` : obtenir l'ID d'une librairie (obligatoire avant `query-docs`).
- `query-docs` : interroger la doc et les exemples de code d'une librairie.

### 2.5 `semgrep` — analyse statique / sécurité

- `security_check` : scan sécurité rapide.
- `semgrep_scan` : scan sur du code fourni. `semgrep_scan_local` : scan sur fichiers locaux.
- `semgrep_scan_with_custom_rule` : scan avec une règle personnalisée.
- `semgrep_rule_schema` : schéma d'écriture de règle.
- `get_abstract_syntax_tree` : AST d'un fichier. `get_supported_languages` : langages supportés.
- `semgrep_findings` : récupérer les findings de la plateforme Semgrep AppSec.

### 2.6 `ssh-mcp` — administration serveur / réseau

- `ssh_server` : inventaire des serveurs (`servers.json`, secrets hors JSON).
- `ssh_session` : pool de connexions SSH persistantes.
- `ssh_exec` : exécuter des commandes (mode standard ou sudo).
- `ssh_job` : suivre/tuer des tâches d'arrière-plan.
- `ssh_sftp` : upload/download et opérations fichiers.
- `ssh_network` : équipements réseau (Cisco, MikroTik, FortiGate, Juniper).
- `ssh_tunnel` : port-forwarding TCP et proxy SOCKS5.

### 2.7 `opencode` — gestion d'OpenCode

- `session_rename`, `session_move` : renommer / déplacer une session.
- `worktree_create`, `worktree_list`, `worktree_remove` : worktrees git.
- `models` : rechercher un modèle disponible.
- `list_mcp_resources`, `read_mcp_resource` : ressources exposées par les serveurs MCP.

---

## 3. Skills

### 3.1 Processus & workflow
- `using-superpowers` — vérifie et applique les skills avant toute action.
- `brainstorming` — cadrer une idée avant tout travail créatif.
- `writing-plans` / `executing-plans` — rédiger puis exécuter un plan d'implémentation.
- `subagent-driven-development` / `dispatching-parallel-agents` — exécution via agents parallèles.
- `test-driven-development` — TDD (test avant code).
- `systematic-debugging` — méthode de debug avant tout correctif.
- `verification-before-completion` — preuves avant d'annoncer un travail terminé.
- `requesting-code-review` / `receiving-code-review` — demander et traiter une revue de code.
- `finishing-a-development-branch` — intégrer une branche terminée.
- `using-git-worktrees` — isolation du travail via worktrees.
- `ponytail` (+ `lite`/`full`/`ultra`) — mode développeur paresseux : la plus petite solution complète.
- `ponytail-audit` — audit qualité d'un dépôt (rapport classé, sans modification).
- `ponytail-review` — revue d'un changement (logique, sûreté, charge, tests, nécessité).
- `ponytail-debt` — liste les `shortcut:` différés.
- `ponytail-gain` / `ponytail-help` — gains mesurés / aide du mode.
- `discernment-nudge` — questions de contrôle après une réponse à fort impact.
- `let-fate-decide` — trancher par le hasard quand la demande est vague.
- `report` — signaler un bug d'OpenCode avec diagnostics.
- `opencode` — tout ce qui concerne OpenCode (config, agents, MCP, SDK…).

### 3.2 Sécurité & audit
- `audit-context-building` — comprendre un codebase avant d'y chercher des bugs.
- `fp-check` — vérifier qu'une faille présumée est un vrai positif.
- `variant-analysis` — chercher les autres occurrences d'un bug trouvé.
- `differential-review` — revue de sécurité d'un diff/PR.
- `spec-to-code-compliance` — conformité code  spécification.
- `hunt-regressions` / `prepare-regression` / `regression-hunt` — détecter et organiser une chasse aux régressions.
- `reproduce-bug` / `validate-bug` — reproduire et valider un bug.
- `reproduce-regression` / `replay-regression` — PoC live avant/après.
- `adjudicate-regression` / `report-regressions` — statuer et rapporter.
- `implement-patch` / `patching-bugs` / `prove-patch` / `post-patch-validation` — patch, preuve, validation.
- `fix-security-vulnerabilities-with-strix` — remédier aux failles trouvées par Strix.
- `vulnerability-triage-brocards` — trier un rapport de vulnérabilité (CVE, bug bounty).
- `supply-chain-risk-auditor` — risque des dépendances (advisories, abandon, scripts d'install).
- `sharp-edges` — APIs piégeuses et défauts sécurisés.
- `zeroize-audit` — effacement des secrets en mémoire.
- `constant-time-analysis` — fuites temporelles sur secrets.
- `yara-rule-authoring` — rédaction de règles YARA-X.
- `burpsuite-project-parser` — fouiller un projet Burp (.burp).
- `sarif-parsing` — traiter/dédupliquer des résultats SARIF.
- `codeql` / `semgrep` / `semgrep-rule-creator` — SAST et création de règles.
- `c-review` / `rust-review` — revue sécurité C/C++ et Rust.

### 3.3 Tests, fuzzing & preuve
- `address-sanitizer` — détecter corruptions mémoire sous ASan.
- `libfuzzer` / `cargo-fuzz` / `libafl` — fuzzers.
- `harness-writing` — écrire un harness de fuzzing.
- `coverage-analysis` — lire la couverture d'un fuzzing.
- `fuzzing-dictionary` / `fuzzing-obstacles` — dictionnaires et contournement des blocages.
- `mutation-testing` — tests de mutation (mewt/muton).
- `property-based-testing` — tests basés sur des propriétés (Hypothesis, fast-check…).
- `wycheproof` — vecteurs de test crypto connus.
- `threejs-visual-validation` — valider un rendu Three.js.
- `webapp-testing` — tester une app web locale avec Playwright.

### 3.4 Blockchain & smart contracts
- `code-maturity-assessor` — notation de maturité (Trail of Bits, 9 catégories).
- `entry-point-analyzer` — points d'entrée modifiant l'état.
- `cosmos-vulnerability-scanner` — Cosmos SDK / CosmWasm / IBC.
- `substrate-vulnerability-scanner` — pallets Substrate/Polkadot.
- `ton-vulnerability-scanner` — contrats FunC (TON).
- `dimensional-analysis` — bugs d'unités et de décimales (WAD/RAY…).

### 3.5 Analyse de code & graphe (Trailmark)
- `trailmark` — construire/interroger un graphe de code multi-langages.
- `trailmark-summary` / `trailmark-structural` — vue d'ensemble / analyse structurelle complète.
- `trailmark-finding-triage` — triage d'un finding par le graphe.
- `trailmark-review-gate` — gate structurel sur une PR/diff.
- `trailmark-variant-neighborhood` — candidats variantes d'une faille.
- `audit-augmentation` — projeter SARIF/weAudit sur le graphe.
- `graph-evolution` — diffs structurels entre deux snapshots.
- `slicing-code-context` — extraire un contexte de code borné pour un petit modèle.
- `dwarf-expert` — information de debug DWARF.
- `mermaid-to-proverif` / `crypto-protocol-diagram` — diagrammes de protocoles et modèles ProVerif.

### 3.6 Pentest (Strix)
- `penetration-testing-with-strix` — pentest autonome (web, API, code).
- `web-app-penetration-testing` — test black-box d'une app web live.
- `api-security-testing` — test REST/GraphQL/gRPC (OWASP API Top 10).
- `owasp-top-10-testing` — évaluation OWASP Top 10:2025.
- `application-security-testing` — AppSec sur tout le produit + plan de remédiation.
- `find-security-vulnerabilities-in-code` — revue white-box avec PoC.
- `ci-security-scanning-with-strix` — scan de sécurité en CI (GitHub/GitLab, SARIF).
- `managed-pentesting-with-strix` — pentest managé via app.strix.ai.

### 3.7 Documentation & bureautique
- `doc-coauthoring` — co-écrire une doc structurée.
- `writing-guidelines` — conformité aux règles de rédaction.
- `docx` — créer/lire/éditer des fichiers Word.
- `xlsx` — tableurs (xlsx, csv, tsv).
- `pptx` — présentations PowerPoint.
- `pdf` — lire, fusionner, découper, remplir, OCR de PDF.
- `internal-comms` — communications internes (statuts, newsletters, incidents…).
- `academy-guide` — cours et tutoriels recommandés sur academy.claude.com.
- `goal-prompt` — rédiger des prompts `/goal`.
- `open-sourcing` — préparer un dépôt open source (licence, secrets, CI…).
- `devcontainer-setup` — devcontainers avec Claude Code et tooling.
- `modern-python` — outillage Python moderne (uv, ruff, ty).
- `gh-cli` — workflows GitHub via `gh` authentifié.
- `claude-api` — référence de l'API Claude (modèles, prix, outils, caching).
- `mcp-builder` — construire des serveurs MCP de qualité.

### 3.8 Design & frontend
**Direction artistique / inspiration**
- `taste-skill` (design-taste-frontend) — direction artistique anti-slop, boucle look-and-fix.
- `frontend-design` — direction visuelle distinctive pour une UI neuve.
- `redesign-existing-projects` — moderniser un site existant.
- `ui-ux-pro-max` — base de données de styles, palettes, guidelines UX.
- `ui-styling` — shadcn/ui + Tailwind + canvas.
- `shadcn` — gérer des composants shadcn/ui.

**Genre packs**
- `quiet-luxury`, `editorial-minimal`, `japanese-minimal`, `brutalist-industrial`, `dark-tech`, `neo-brutalism`, `playful-color`, `retro-print`, `corporate-trust`, `cinematic-motion` — styles clés en main à empiler sur `design-taste`.

**Principes**
- `taste-accessibility` — WCAG 2.2 AA intégré à la génération.
- `taste-color` — palettes OKLCH, contrastes, tokens.
- `taste-typography` — échelles typographiques, rythme, pairings.
- `taste-ux-copy` — textes d'interface (CTA, erreurs, états vides).
- `taste-code-craft` — HTML sémantique, CSS à tokens.
- `taste-code-review` — ordre de revue du code généré.
- `taste-design-review` — audit visuel et d'usage par captures.
- `taste-design-system` — design systems à 3 niveaux de tokens.
- `taste-motion` — durées, easings, micro-interactions.
- `taste-landing-page` — structure et conversion d'une landing page.
- `taste-web-performance` — Core Web Vitals.
- `taste-gsap` — écriture GSAP propre.
- `design-audit` — checklist d'audit design.
- `design-system` — tokens, specs de composants, slides.
- `desktop-principles` / `mobile-principles` — UX desktop / mobile.
- `motion-principles` — bases du motion design.
- `web-design-guidelines` — conformité aux guidelines d'interface web.
- `banner-design` — bannières (réseaux, pub, print).
- `canvas-design` — affiches et visuels PNG/PDF.
- `brand` / `brand-guidelines` — voix de marque, identité (couleurs Anthropic).
- `taste-brand-identity` — logo, wordmark, favicon, brand sheet.
- `design` — identité de marque, logo, CIP, icônes, social photos, slides.

### 3.9 Animation & motion
- `motion-web` — sites motion-first (scroll, Framer Motion, GSAP, 3D léger).
- `motionsites-web-builder` — sites cinématiques de niveau primé.
- `cinematic-motion` (voir genre packs) — storytelling scrollé.
- `design-to-motion` — animer un design statique (MP4/GIF).
- `gsap-core`, `gsap-timeline`, `gsap-scrolltrigger`, `gsap-plugins`, `gsap-react`, `gsap-frameworks`, `gsap-utils`, `gsap-performance` — GSAP.
- `framer-motion` — AnimatePresence, layout animations, gestures.
- `react-view-transitions` — transitions natives React.
- `css-native` — animations CSS modernes (scroll-driven, View Transitions).
- `compose-motion` (Compose), `swiftui-motion` (SwiftUI).

### 3.10 Frontend stacks
- `react-best-practices` — patterns React/Next.js performants.
- `composition-patterns` — composition React (compound, context).
- `react-native-skills` — React Native / Expo.
- `migrate-radix-to-base` — Radix  Base UI.
- `web-artifacts-builder` — artefacts React/Tailwind/shadcn complexes.
- `landing-page-design` — système complet de landing page.
- `compose-graphics`, `compose-multiplatform` — Compose / KMP.
- `swiftui-graphics` — shaders Metal, Canvas, Liquid Glass.
- `particle-system` / `shader-glsl` / `canvas-generative` — particules, GLSL, art génératif.
- `algorithmic-art` — art génératif p5.js.

### 3.11 Three.js / WebGPU
- `webgpu-threejs-tsl` — WebGPU + TSL (shaders, node materials, compute).
- `threejs-bloom` — bloom HDR.
- `threejs-exposure-color-grading` — exposition et color grading.
- `threejs-image-pipeline` — graphe d'image final (MRT, historique temporel).
- `threejs-procedural-materials` — matériaux PBR procéduraux.
- `threejs-shadow-systems` — ombres directionnelles stables / cascades.
- `threejs-water-optics` — eau, vagues, optique.
- `threejs-debugging` — diagnostiquer un comportement inattendu.
- `3dviz-pro-max` — scènes 3D, explicateurs, puzzles spatiaux.

### 3.12 Slides, thèmes, présentation
- `slides` — présentations HTML avec Chart.js.
- `theme-factory` — thèmes prêts pour artefacts/slides.
- `slack-gif-creator` — GIF animés optimisés pour Slack.

### 3.13 Skills pour créer des skills
- `skill-creator` — créer, modifier, évaluer un skill (evals, déclenchement).
- `skill-improver` — boucle de revue/correction d'un skill.
- `code-improver` — boucle review/fix sur un code au choix.
- `pr-improver` — boucle de correction d'une PR jusqu'à revue propre.
- `second-opinion` — revue externe (Codex, Antigravity).
- `review-pr` — revue d'une branche contre sa base.
- `orchestration` — coordination d'une équipe de sous-agents.
- `writing-skills` — bonnes pratiques de rédaction de skills.
- `diagnosing-superpowers` — comprendre un échec de session superpowers.

### 3.14 Culture Index
- `interpreting-culture-index` — lire des profils Culture Index (individu, équipe, burnout, recrutement).

### 3.15 Divers
- `ssh-mcp` — skill associé au serveur MCP SSH (NetOps, SysAdmin, tunnels).
- `chrome-mcp-troubleshooting` — dépanner l'extension Claude in Chrome.
- `deploy-to-vercel` — déployer sur Vercel.
- `vercel-cli-with-tokens` — Vercel CLI via token.
- `vercel-optimize` — réduire coûts/performances sur Vercel.

---

## 4. Modes actifs

- **Ponytail (ultra)** : la plus petite solution complète ; remise en cause de la demande ; un test/self-check pour toute logique non triviale.
