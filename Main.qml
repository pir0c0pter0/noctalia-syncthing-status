import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null
    property bool busy: false
    property bool pendingPoll: false
    property bool parsedCurrentRun: false
    property string lastStdout: ""
    property string lastStderr: ""
    property string _currentLang: ""
    property int translationVersion: 0

    readonly property var settings: pluginApi?.pluginSettings ?? ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

    readonly property bool enabled: settings.enabled ?? defaults.enabled ?? true
    readonly property string apiUrl: (settings.apiUrl ?? defaults.apiUrl ?? "").trim()
    readonly property string apiKey: (settings.apiKey ?? defaults.apiKey ?? "").trim()
    readonly property string configPath: (settings.configPath ?? defaults.configPath ?? "").trim()
    readonly property bool verifyTls: settings.verifyTls ?? defaults.verifyTls ?? false
    readonly property int pollIntervalMs: settings.pollIntervalMs ?? defaults.pollIntervalMs ?? 10000
    readonly property string language: settings.language ?? defaults.language ?? "auto"
    readonly property var folderIds: {
        const raw = settings.folderIds ?? defaults.folderIds ?? [];
        try {
            return Array.from(raw);
        } catch (e) {
            return [];
        }
    }

    readonly property string scriptPath: (pluginApi?.pluginDir ?? "") + "/syncthing-status.py"

    function makeEmptySnapshot() {
        return {
            state: "unconfigured",
            detail: "",
            checkedAt: "",
            sources: {
                configPath: "",
                urlSource: "none",
                apiKeySource: "none",
                resolvedUrl: ""
            },
            devices: {
                configured: 0,
                connected: 0,
                paused: 0
            },
            totals: {
                monitoredFolders: 0,
                pausedFolders: 0,
                syncingFolders: 0,
                erroredFolders: 0,
                needItems: 0,
                needBytes: 0
            },
            folders: [],
            availableFolders: [],
            recentErrors: []
        };
    }

    property var snapshot: makeEmptySnapshot()

    readonly property string state: snapshot?.state ?? "unconfigured"
    readonly property string detail: snapshot?.detail ?? ""
    readonly property int configuredDevices: snapshot?.devices?.configured ?? 0
    readonly property int connectedDevices: snapshot?.devices?.connected ?? 0
    readonly property int pausedDevices: snapshot?.devices?.paused ?? 0
    readonly property int monitoredFolders: snapshot?.totals?.monitoredFolders ?? 0
    readonly property int pausedFolders: snapshot?.totals?.pausedFolders ?? 0
    readonly property int syncingFolders: snapshot?.totals?.syncingFolders ?? 0
    readonly property int erroredFolders: snapshot?.totals?.erroredFolders ?? 0
    readonly property int needItems: snapshot?.totals?.needItems ?? 0
    readonly property double needBytes: snapshot?.totals?.needBytes ?? 0
    readonly property var folders: snapshot?.folders ?? []
    readonly property var availableFolders: snapshot?.availableFolders ?? []
    readonly property var recentErrors: snapshot?.recentErrors ?? []
    readonly property string resolvedUrl: snapshot?.sources?.resolvedUrl ?? ""
    readonly property string resolvedConfigPath: snapshot?.sources?.configPath ?? ""
    readonly property string urlSource: snapshot?.sources?.urlSource ?? "none"
    readonly property string apiKeySource: snapshot?.sources?.apiKeySource ?? "none"
    readonly property string checkedAt: snapshot?.checkedAt ?? ""

    readonly property bool hasProblem: state === "offline"
                                      || state === "unauthorized"
                                      || state === "error"
                                      || state === "disconnected"

    readonly property var _enStrings: ({
        "state": {
            "idle": "Synchronized",
            "syncing": "Syncing",
            "paused": "Paused",
            "disconnected": "Disconnected",
            "offline": "Offline",
            "unauthorized": "Unauthorized",
            "error": "Error",
            "unconfigured": "Not configured",
            "disabled": "Disabled"
        },
        "summary": {
            "disabled": "Plugin polling is disabled",
            "idle-devices": "%1/%2 devices connected",
            "idle-no-devices": "No remote devices configured",
            "syncing-items": "%1 items pending",
            "syncing-folders": "%1 folders active",
            "paused": "All monitored folders are paused",
            "disconnected": "No remote devices connected",
            "offline": "Syncthing GUI/API is unreachable",
            "unauthorized": "Syncthing rejected the API key",
            "error": "Syncthing reported folder or system errors",
            "unconfigured": "Set GUI URL/API key or point to config.xml"
        },
        "bar": {
            "enable": "Enable Syncthing Status",
            "disable": "Disable Syncthing Status",
            "refresh": "Refresh now",
            "settings": "Settings"
        },
        "panel": {
            "title": "Syncthing",
            "refresh": "Refresh",
            "devices": "Devices",
            "folders": "Folders",
            "pending": "Pending",
            "no-folders": "No monitored folders",
            "details": "Details",
            "recent-errors": "Recent errors",
            "last-check": "Last check",
            "url": "GUI URL",
            "config-path": "Config path",
            "api-source": "API key source",
            "folder-state": "%1  (%2 items)"
        },
        "settings": {
            "enabled": "Enable plugin",
            "enabled-desc": "Poll Syncthing periodically and expose status in the bar/panel",
            "url": "GUI URL",
            "url-desc": "Optional. Leave blank to autodetect from Syncthing config.xml",
            "api-key": "API key",
            "api-key-desc": "Optional. Leave blank to read the key from config.xml",
            "config-path": "Config path",
            "config-path-desc": "Optional path to Syncthing config.xml for autodetection",
            "verify-tls": "Verify TLS certificates",
            "verify-tls-desc": "Enable this only if your Syncthing HTTPS certificate is trusted",
            "poll-interval": "Poll interval",
            "poll-interval-desc": "How often the plugin refreshes Syncthing status",
            "folders": "Monitored folders",
            "folders-desc": "If none are selected the plugin monitors every configured folder",
            "no-folders": "No folders loaded yet. Save and refresh once Syncthing is reachable.",
            "save": "Save",
            "saved": "Saved",
            "refresh": "Refresh now",
            "language": "Language",
            "language-desc": "Plugin display language",
            "lang-auto": "Auto",
            "lang-en": "English",
            "lang-pt": "Portuguese",
            "status": "Current status",
            "about": "About",
            "developer": "Developed by Pir0c0pter0",
            "translation-mode": "Automatic translation follows your system language while Auto is selected."
        },
        "source": {
            "manual": "Manual",
            "config": "Config.xml",
            "none": "Unavailable"
        }
    })

    readonly property var _ptStrings: ({
        "state": {
            "idle": "Sincronizado",
            "syncing": "Sincronizando",
            "paused": "Pausado",
            "disconnected": "Desconectado",
            "offline": "Offline",
            "unauthorized": "Nao autorizado",
            "error": "Erro",
            "unconfigured": "Nao configurado",
            "disabled": "Desativado"
        },
        "summary": {
            "disabled": "Polling do plugin esta desativado",
            "idle-devices": "%1/%2 dispositivos conectados",
            "idle-no-devices": "Nenhum dispositivo remoto configurado",
            "syncing-items": "%1 itens pendentes",
            "syncing-folders": "%1 pastas ativas",
            "paused": "Todas as pastas monitoradas estao pausadas",
            "disconnected": "Nenhum dispositivo remoto conectado",
            "offline": "GUI/API do Syncthing esta inacessivel",
            "unauthorized": "Syncthing rejeitou a API key",
            "error": "Syncthing reportou erros de pasta ou sistema",
            "unconfigured": "Defina GUI URL/API key ou aponte para o config.xml"
        },
        "bar": {
            "enable": "Ativar Syncthing Status",
            "disable": "Desativar Syncthing Status",
            "refresh": "Atualizar agora",
            "settings": "Configuracoes"
        },
        "panel": {
            "title": "Syncthing",
            "refresh": "Atualizar",
            "devices": "Dispositivos",
            "folders": "Pastas",
            "pending": "Pendente",
            "no-folders": "Nenhuma pasta monitorada",
            "details": "Detalhes",
            "recent-errors": "Erros recentes",
            "last-check": "Ultima checagem",
            "url": "GUI URL",
            "config-path": "Caminho do config",
            "api-source": "Origem da API key",
            "folder-state": "%1  (%2 itens)"
        },
        "settings": {
            "enabled": "Ativar plugin",
            "enabled-desc": "Consulta o Syncthing periodicamente e expoe status no bar/painel",
            "url": "GUI URL",
            "url-desc": "Opcional. Deixe vazio para autodetectar pelo config.xml do Syncthing",
            "api-key": "API key",
            "api-key-desc": "Opcional. Deixe vazio para ler a chave do config.xml",
            "config-path": "Caminho do config",
            "config-path-desc": "Caminho opcional para o config.xml do Syncthing para autodeteccao",
            "verify-tls": "Verificar certificados TLS",
            "verify-tls-desc": "Ative apenas se o certificado HTTPS do Syncthing for confiavel",
            "poll-interval": "Intervalo de consulta",
            "poll-interval-desc": "Com que frequencia o plugin atualiza o status do Syncthing",
            "folders": "Pastas monitoradas",
            "folders-desc": "Se nenhuma for selecionada o plugin monitora todas as pastas configuradas",
            "no-folders": "Nenhuma pasta carregada ainda. Salve e atualize quando o Syncthing estiver acessivel.",
            "save": "Salvar",
            "saved": "Salvo",
            "refresh": "Atualizar agora",
            "language": "Idioma",
            "language-desc": "Idioma de exibicao do plugin",
            "lang-auto": "Auto",
            "lang-en": "Ingles",
            "lang-pt": "Portugues",
            "status": "Status atual",
            "about": "Sobre",
            "developer": "Desenvolvido por Pir0c0pter0",
            "translation-mode": "A traducao automatica segue o idioma do sistema enquanto Auto estiver selecionado."
        },
        "source": {
            "manual": "Manual",
            "config": "Config.xml",
            "none": "Indisponivel"
        }
    })

    property var _translations: _enStrings

    function _resolveLanguage() {
        if (language !== "auto") return language;
        const locale = Qt.locale().name;
        if (locale.startsWith("pt")) return "pt";
        return "en";
    }

    function _loadTranslations() {
        const lang = _resolveLanguage();
        if (lang === _currentLang) return;
        _translations = (lang === "pt") ? _ptStrings : _enStrings;
        _currentLang = lang;
        translationVersion++;
    }

    function reloadLanguage(langCode) {
        let resolved = langCode;
        if (langCode === "auto") {
            const locale = Qt.locale().name;
            resolved = locale.startsWith("pt") ? "pt" : "en";
        }
        if (resolved === _currentLang) return;
        _translations = (resolved === "pt") ? _ptStrings : _enStrings;
        _currentLang = resolved;
        translationVersion++;
    }

    function translate(key) {
        const parts = key.split(".");
        let obj = _translations;
        for (let i = 0; i < parts.length; i++) {
            if (obj && typeof obj === "object" && parts[i] in obj) {
                obj = obj[parts[i]];
            } else {
                return undefined;
            }
        }
        return typeof obj === "string" ? obj : undefined;
    }

    function t(key) {
        return translate(key);
    }

    function stateLabel(code) {
        return t("state." + code) ?? code;
    }

    function sourceLabel(code) {
        return t("source." + code) ?? code;
    }

    function statusSummary() {
        if (!enabled) return t("summary.disabled");
        if (state === "idle") {
            if (configuredDevices > 0) {
                return t("summary.idle-devices").arg(connectedDevices).arg(configuredDevices);
            }
            return t("summary.idle-no-devices");
        }
        if (state === "syncing") {
            if (needItems > 0) return t("summary.syncing-items").arg(needItems);
            return t("summary.syncing-folders").arg(Math.max(syncingFolders, 1));
        }
        return t("summary." + state) ?? detail;
    }

    function statusColor(code) {
        if (!enabled) return Color.mOutline;
        if (code === "idle") return Color.mPrimary;
        if (code === "syncing") return Color.mSecondary;
        if (code === "paused") return Color.mOutline;
        if (code === "disconnected") return Color.mSecondary;
        if (code === "offline" || code === "unauthorized" || code === "error") return Color.mError;
        return Color.mOutline;
    }

    function badgeText() {
        if (!enabled) return "";
        if (state === "syncing") {
            if (needItems > 99) return "99+";
            if (needItems > 0) return String(needItems);
            return String(Math.max(syncingFolders, 1));
        }
        if (state === "paused") return "P";
        if (hasProblem) return "!";
        return "";
    }

    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Number(bytes);
        let index = 0;
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024;
            index++;
        }
        const rounded = (value >= 10 || index === 0) ? Math.round(value) : value.toFixed(1);
        return rounded + " " + units[index];
    }

    function formatCheckedAt(isoValue) {
        if (!isoValue) return "-";
        const parsed = new Date(isoValue);
        if (isNaN(parsed.getTime())) return isoValue;
        return parsed.toLocaleString(Qt.locale().name);
    }

    function toggleFolder(folderId) {
        if (!pluginApi?.pluginSettings) return;
        const current = Array.from(folderIds);
        const index = current.indexOf(folderId);
        if (index >= 0) {
            current.splice(index, 1);
        } else {
            current.push(folderId);
        }
        pluginApi.pluginSettings.folderIds = current;
        pluginApi.saveSettings();
    }

    function setFolderSelection(ids) {
        if (!pluginApi?.pluginSettings) return;
        pluginApi.pluginSettings.folderIds = Array.from(ids);
        pluginApi.saveSettings();
    }

    function requestPoll(force) {
        if (!enabled && !force) return;
        if (!pluginApi) return;
        if (pollProcess.running) {
            pendingPoll = true;
            return;
        }
        parsedCurrentRun = false;
        lastStdout = "";
        lastStderr = "";
        pollProcess.running = true;
    }

    function applySnapshot(rawText) {
        const text = (rawText || "").trim();
        if (!text) return;
        try {
            const parsed = JSON.parse(text);
            snapshot = parsed;
            parsedCurrentRun = true;
        } catch (error) {
            console.warn("[syncthing-status] failed to parse helper JSON:", error);
        }
    }

    onLanguageChanged: _loadTranslations()
    onPluginApiChanged: { if (pluginApi) _loadTranslations(); }
    onEnabledChanged: {
        if (enabled) {
            pollTimer.restart();
            requestPoll(false);
        } else {
            pollTimer.stop();
        }
    }
    onApiUrlChanged: requestPoll(false)
    onApiKeyChanged: requestPoll(false)
    onConfigPathChanged: requestPoll(false)
    onVerifyTlsChanged: requestPoll(false)
    onFolderIdsChanged: requestPoll(false)
    onPollIntervalMsChanged: requestPoll(false)

    Component.onCompleted: {
        _loadTranslations();
        if (enabled) requestPoll(false);
    }

    readonly property Timer pollTimer: Timer {
        interval: root.pollIntervalMs
        repeat: true
        running: root.enabled
        onTriggered: root.requestPoll(false)
    }

    readonly property Process pollProcess: Process {
        command: {
            const args = [
                "python3", root.scriptPath,
                "--timeout", "5"
            ];
            if (root.apiUrl) {
                args.push("--url");
                args.push(root.apiUrl);
            }
            if (root.apiKey) {
                args.push("--api-key");
                args.push(root.apiKey);
            }
            if (root.configPath) {
                args.push("--config-path");
                args.push(root.configPath);
            }
            if (root.folderIds.length > 0) {
                args.push("--folders");
                args.push(root.folderIds.join(","));
            }
            if (root.verifyTls) {
                args.push("--verify-tls");
            }
            return args;
        }

        running: false

        onStarted: {
            root.busy = true;
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            if (!root.parsedCurrentRun) {
                const fallback = root.makeEmptySnapshot();
                fallback.state = "error";
                fallback.detail = root.lastStderr || ("Helper exited with code " + exitCode);
                root.snapshot = fallback;
            }
            if (root.pendingPoll) {
                root.pendingPoll = false;
                root.requestPoll(false);
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.lastStdout = text;
                root.applySnapshot(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.lastStderr = text.trim();
                if (root.lastStderr) {
                    console.warn("[syncthing-status]", root.lastStderr);
                }
            }
        }
    }

    IpcHandler {
        target: "plugin:noctalia-syncthing-status"

        function refresh() {
            root.requestPoll(true);
        }

        function toggle() {
            const newState = !root.enabled;
            if (pluginApi?.pluginSettings) {
                pluginApi.pluginSettings.enabled = newState;
                pluginApi.saveSettings();
            }
        }

        function status() {
            return {
                enabled: root.enabled,
                busy: root.busy,
                state: root.state,
                summary: root.statusSummary(),
                devices: root.snapshot.devices,
                totals: root.snapshot.totals
            };
        }
    }
}
