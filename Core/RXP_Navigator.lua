local ADDON_NAME = ...

local Navigator = CreateFrame("Frame")
_G.RXPNavigator = Navigator
local PI2 = math.pi * 2
local UPDATE_INTERVAL = 0.05
local MAP_UPDATE_INTERVAL = 0.10
local ADDON_VERSION = "1.4.0-beta2"

local THEMES = {
    navigator = { name = "Navigator Grün", line = {0.18, 0.96, 0.36}, arrow = {0.30, 1.00, 0.46}, center = {0.15, 0.96, 0.36}, accent = {0.93, 0.72, 0.16} },
    emerald = { name = "Smaragd", line = {0.00, 0.80, 0.55}, arrow = {0.35, 1.00, 0.72}, center = {0.00, 0.84, 0.54}, accent = {0.93, 0.72, 0.16} },
    cyan = { name = "Arkanblau", line = {0.10, 0.76, 1.00}, arrow = {0.46, 0.92, 1.00}, center = {0.12, 0.74, 1.00}, accent = {0.93, 0.72, 0.16} },
    gold = { name = "Gold", line = {1.00, 0.72, 0.14}, arrow = {1.00, 0.86, 0.40}, center = {1.00, 0.71, 0.15}, accent = {0.93, 0.72, 0.16} },
    red = { name = "Glutrot", line = {0.96, 0.26, 0.22}, arrow = {1.00, 0.48, 0.42}, center = {0.96, 0.26, 0.22}, accent = {0.93, 0.72, 0.16} },
    violet = { name = "Violett", line = {0.86, 0.20, 0.72}, arrow = {1.00, 0.60, 0.90}, center = {0.86, 0.20, 0.72}, accent = {0.93, 0.72, 0.16} },
}

local CORPSE_LINE = {0.72, 0.025, 0.025}
local CORPSE_LINE_BRIGHT = {0.96, 0.10, 0.08}
local CORPSE_OUTLINE = {0.16, 0.005, 0.005}
local CORPSE_SKULL_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"

local LOCALES = {
    enUS = {
        subtitle = "Standalone navigation for RXPGuides – minimap, world map, target markers and upcoming goals.",
        colorTheme = "Color theme", display = "Display", line = "Line", upcoming = "Upcoming goals",
        enabled = "Enable navigator", minimap = "Show on minimap", worldmap = "Show on world/zone map", distance = "Show distance on minimap",
        marker = "Show target marker with golden border", tooltip = "Mouseover tooltip on world-map targets", animation = "Animated direction arrows", hudArrow = "Show direction arrow with distance and ETA", hudSettings="Navigation Arrow", hudMode="Arrow mode", hud2D="2D", hud3D="3D", hudDesign="Design", hudModern="Modern", hudClassic="Classic", hudLock="Lock position", hudSize="Arrow Size", hudArrowStyle="Arrow Style", hudStyleClassic="Classic Clear", hudStyleCompass="Compass Bronze", hudStyleCrystal="Crystal Glow", hudDistance="Show distance", hudETA="Show ETA", hudResetPos="Reset Arrow Position", hudColor="Arrow Color", hudDragHint="Drag the navigation arrow while unlocked",
        thin = "Thin", normal = "Normal", strong = "Strong", maxMinimap = "Max. minimap length", animSpeed = "Animation speed", targetSize = "Target marker size",
        futureDesc = "Show additional RestedXP destinations after the current target.", future0 = "Off", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "Defaults", resetDone = "Settings reset", resetConfirm = "Reset all RestedXP-Navigator settings to their defaults? Your current configuration will be lost.", resetConfirmYes = "Reset", resetConfirmNo = "Cancel", step = "RXP Step", target = "RXP Target", current = "Current", next = "Next",
        commands = "Commands", loaded = "loaded", language = "Language: automatic",
        theme_navigator = "Navigator Green", theme_emerald = "Emerald", theme_cyan = "Arcane Blue", theme_gold = "Gold", theme_red = "Ember Red", theme_violet = "Violet",
    },
    deDE = {
        subtitle = "Standalone-Navigation für RXPGuides – Minimap, Weltkarte, Zielmarker und Folgeziele.",
        colorTheme = "Farb-Theme", display = "Anzeige", line = "Linie", upcoming = "Folgeziele",
        enabled = "Navigator aktiv", minimap = "Auf Minimap anzeigen", worldmap = "Auf Welt-/Zonenkarte anzeigen", distance = "Distanz auf der Minimap anzeigen",
        marker = "Zielpunkt mit goldenem Rand anzeigen", tooltip = "Mouseover-Tooltip an Weltkarten-Zielen", animation = "Animierte Richtungspfeile", hudArrow = "Richtungspfeil mit Distanz und ETA anzeigen", hudSettings="Navigationspfeil", hudMode="Pfeilmodus", hud2D="2D", hud3D="3D", hudDesign="Design", hudModern="Modern", hudClassic="Klassisch", hudLock="Position sperren", hudSize="Pfeilgröße", hudArrowStyle="Pfeilstil", hudStyleClassic="Klassisch klar", hudStyleCompass="Kompass Bronze", hudStyleCrystal="Kristallglanz", hudDistance="Distanz anzeigen", hudETA="ETA anzeigen", hudResetPos="Pfeilposition zurücksetzen", hudColor="Pfeilfarbe", hudDragHint="Navigationspfeil entsperren und zum Verschieben ziehen",
        thin = "Dünn", normal = "Normal", strong = "Kräftig", maxMinimap = "Max. Minimap-Länge", animSpeed = "Animationsgeschwindigkeit", targetSize = "Zielpunkt-Größe",
        futureDesc = "Zusätzliche RestedXP-Ziele nach dem aktuellen Ziel anzeigen.", future0 = "Aus", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "Standardwerte", resetDone = "Einstellungen zurückgesetzt", resetConfirm = "Alle RestedXP-Navigator-Einstellungen auf die Standardwerte zurücksetzen? Deine aktuelle Konfiguration geht dabei verloren.", resetConfirmYes = "Zurücksetzen", resetConfirmNo = "Abbrechen", step = "RXP Schritt", target = "RXP Ziel", current = "Aktuell", next = "Danach",
        commands = "Befehle", loaded = "geladen", language = "Sprache: automatisch",
        theme_navigator = "Navigator Grün", theme_emerald = "Smaragd", theme_cyan = "Arkanblau", theme_gold = "Gold", theme_red = "Glutrot", theme_violet = "Violett",
    },
    frFR = {
        subtitle = "Navigation autonome pour RXPGuides – minicarte, carte du monde, marqueurs et objectifs suivants.",
        colorTheme = "Thème de couleur", display = "Affichage", line = "Ligne", upcoming = "Objectifs suivants",
        enabled = "Activer le navigateur", minimap = "Afficher sur la minicarte", worldmap = "Afficher sur la carte du monde/de zone", distance = "Afficher la distance sur la minicarte",
        marker = "Afficher le marqueur avec bordure dorée", tooltip = "Infobulle au survol des objectifs", animation = "Flèches directionnelles animées", hudArrow = "Afficher la flèche de direction avec distance et ETA", hudSettings="Flèche de navigation", hudMode="Mode de flèche", hud2D="2D", hud3D="3D", hudDesign="Design", hudModern="Moderne", hudClassic="Classique", hudLock="Verrouiller la position", hudSize="Taille de la flèche", hudDistance="Afficher la distance", hudETA="Afficher l’ETA", hudResetPos="Réinitialiser la position de la flèche", hudColor="Couleur de la flèche", hudDragHint="Déverrouillez puis faites glisser la flèche de navigation",
        thin = "Fine", normal = "Normale", strong = "Épaisse", maxMinimap = "Longueur max. minicarte", animSpeed = "Vitesse d’animation", targetSize = "Taille du marqueur",
        futureDesc = "Afficher des destinations RestedXP après l’objectif actuel.", future0 = "Désactivé", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "Valeurs par défaut", resetDone = "Paramètres réinitialisés", step = "Étape RXP", target = "Objectif RXP", current = "Actuel", next = "Suivant",
        theme_navigator = "Vert Navigateur", theme_emerald = "Émeraude", theme_cyan = "Bleu arcanique", theme_gold = "Or", theme_red = "Rouge braise", theme_violet = "Violet",
    },
    esES = {
        subtitle = "Navegación independiente para RXPGuides – minimapa, mapa mundial, marcadores y objetivos siguientes.",
        colorTheme = "Tema de color", display = "Visualización", line = "Línea", upcoming = "Objetivos siguientes",
        enabled = "Activar navegador", minimap = "Mostrar en minimapa", worldmap = "Mostrar en mapa mundial/de zona", distance = "Mostrar distancia en minimapa",
        marker = "Mostrar marcador con borde dorado", tooltip = "Descripción al pasar el ratón por objetivos", animation = "Flechas de dirección animadas", hudArrow = "Mostrar flecha de dirección con distancia y ETA", hudSettings="Flecha de navegación", hudMode="Modo de flecha", hud2D="2D", hud3D="3D", hudDesign="Diseño", hudModern="Moderno", hudClassic="Clásico", hudLock="Bloquear posición", hudSize="Tamaño de la flecha", hudDistance="Mostrar distancia", hudETA="Mostrar ETA", hudResetPos="Restablecer posición de la flecha", hudColor="Color de la flecha", hudDragHint="Desbloquea y arrastra la flecha de navegación",
        thin = "Fina", normal = "Normal", strong = "Gruesa", maxMinimap = "Longitud máx. del minimapa", animSpeed = "Velocidad de animación", targetSize = "Tamaño del marcador",
        futureDesc = "Mostrar destinos adicionales de RestedXP después del objetivo actual.", future0 = "Desactivado", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "Valores predeterminados", resetDone = "Ajustes restablecidos", step = "Paso RXP", target = "Objetivo RXP", current = "Actual", next = "Siguiente",
        theme_navigator = "Verde Navegador", theme_emerald = "Esmeralda", theme_cyan = "Azul arcano", theme_gold = "Oro", theme_red = "Rojo brasa", theme_violet = "Violeta",
    },
    itIT = {
        subtitle = "Navigazione standalone per RXPGuides – minimappa, mappa del mondo, indicatori e obiettivi successivi.",
        colorTheme = "Tema colore", display = "Visualizzazione", line = "Linea", upcoming = "Obiettivi successivi",
        enabled = "Attiva navigatore", minimap = "Mostra sulla minimappa", worldmap = "Mostra sulla mappa del mondo/zona", distance = "Mostra distanza sulla minimappa",
        marker = "Mostra indicatore con bordo dorato", tooltip = "Tooltip al passaggio sugli obiettivi", animation = "Frecce direzionali animate", hudArrow = "Mostra freccia direzionale con distanza ed ETA", hudSettings="Freccia di navigazione", hudMode="Modalità freccia", hud2D="2D", hud3D="3D", hudDesign="Design", hudModern="Moderno", hudClassic="Classico", hudLock="Blocca posizione", hudSize="Dimensione freccia", hudDistance="Mostra distanza", hudETA="Mostra ETA", hudResetPos="Reimposta posizione freccia", hudColor="Colore freccia", hudDragHint="Sblocca e trascina la freccia di navigazione",
        thin = "Sottile", normal = "Normale", strong = "Spessa", maxMinimap = "Lunghezza max minimappa", animSpeed = "Velocità animazione", targetSize = "Dimensione indicatore",
        futureDesc = "Mostra destinazioni RestedXP aggiuntive dopo l’obiettivo attuale.", future0 = "Disattivato", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "Predefiniti", resetDone = "Impostazioni ripristinate", step = "Passo RXP", target = "Obiettivo RXP", current = "Attuale", next = "Successivo",
        theme_navigator = "Verde Navigatore", theme_emerald = "Smeraldo", theme_cyan = "Blu arcano", theme_gold = "Oro", theme_red = "Rosso brace", theme_violet = "Viola",
    },
    ptBR = {
        subtitle = "Navegação independente para RXPGuides – minimapa, mapa-múndi, marcadores e próximos objetivos.",
        colorTheme = "Tema de cor", display = "Exibição", line = "Linha", upcoming = "Próximos objetivos",
        enabled = "Ativar navegador", minimap = "Mostrar no minimapa", worldmap = "Mostrar no mapa-múndi/zona", distance = "Mostrar distância no minimapa",
        marker = "Mostrar marcador com borda dourada", tooltip = "Tooltip ao passar sobre os objetivos", animation = "Setas de direção animadas", hudArrow = "Mostrar seta de direção com distância e ETA", hudSettings="Seta de navegação", hudMode="Modo da seta", hud2D="2D", hud3D="3D", hudDesign="Design", hudModern="Moderno", hudClassic="Clássico", hudLock="Bloquear posição", hudSize="Tamanho da seta", hudDistance="Mostrar distância", hudETA="Mostrar ETA", hudResetPos="Redefinir posição da seta", hudColor="Cor da seta", hudDragHint="Desbloqueie e arraste a seta de navegação",
        thin = "Fina", normal = "Normal", strong = "Forte", maxMinimap = "Comprimento máx. do minimapa", animSpeed = "Velocidade da animação", targetSize = "Tamanho do marcador",
        futureDesc = "Mostrar destinos adicionais do RestedXP após o objetivo atual.", future0 = "Desligado", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "Padrões", resetDone = "Configurações restauradas", step = "Etapa RXP", target = "Objetivo RXP", current = "Atual", next = "Próximo",
        theme_navigator = "Verde Navegador", theme_emerald = "Esmeralda", theme_cyan = "Azul arcano", theme_gold = "Ouro", theme_red = "Vermelho brasa", theme_violet = "Violeta",
    },
    ruRU = {
        subtitle = "Автономная навигация для RXPGuides — мини-карта, карта мира, маркеры целей и следующие цели.",
        colorTheme = "Цветовая тема", display = "Отображение", line = "Линия", upcoming = "Следующие цели",
        enabled = "Включить навигатор", minimap = "Показывать на мини-карте", worldmap = "Показывать на карте мира/зоны", distance = "Показывать расстояние на мини-карте",
        marker = "Показывать маркер цели с золотой рамкой", tooltip = "Подсказка при наведении на цель на карте", animation = "Анимированные стрелки направления", hudArrow = "Показывать навигационную стрелку с расстоянием и ETA", hudSettings="Навигационная стрелка", hudMode="Режим стрелки", hud2D="2D", hud3D="3D", hudDesign="Дизайн", hudModern="Современный", hudClassic="Классический", hudLock="Заблокировать позицию", hudSize="Размер стрелки", hudDistance="Показывать расстояние", hudETA="Показывать ETA", hudResetPos="Сбросить позицию стрелки", hudColor="Цвет стрелки", hudDragHint="Разблокируйте и перетащите навигационную стрелку",
        thin = "Тонкая", normal = "Обычная", strong = "Толстая", maxMinimap = "Макс. длина на мини-карте", animSpeed = "Скорость анимации", targetSize = "Размер маркера цели",
        futureDesc = "Показывать дополнительные цели RestedXP после текущей.", future0 = "Выкл.", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "По умолчанию", resetDone = "Настройки сброшены", step = "Шаг RXP", target = "Цель RXP", current = "Текущая", next = "Далее",
        theme_navigator = "Зелёный навигатор", theme_emerald = "Изумруд", theme_cyan = "Магический синий", theme_gold = "Золото", theme_red = "Огненно-красный", theme_violet = "Фиолетовый",
    },
    koKR = {
        subtitle = "RXPGuides용 독립 내비게이션 — 미니맵, 월드맵, 목표 마커 및 다음 목표.",
        colorTheme = "색상 테마", display = "표시", line = "경로선", upcoming = "다음 목표",
        enabled = "내비게이터 사용", minimap = "미니맵에 표시", worldmap = "월드/지역 지도에 표시", distance = "미니맵에 거리 표시",
        marker = "금색 테두리 목표 마커 표시", tooltip = "월드맵 목표 마우스오버 툴팁", animation = "애니메이션 방향 화살표", hudArrow = "거리 및 ETA가 포함된 내비게이션 화살표 표시", hudSettings="내비게이션 화살표", hudMode="화살표 모드", hud2D="2D", hud3D="3D", hudDesign="디자인", hudModern="모던", hudClassic="클래식", hudLock="위치 잠금", hudSize="화살표 크기", hudDistance="거리 표시", hudETA="ETA 표시", hudResetPos="화살표 위치 초기화", hudColor="화살표 색상", hudDragHint="잠금을 해제한 뒤 내비게이션 화살표를 드래그하세요",
        thin = "얇게", normal = "보통", strong = "굵게", maxMinimap = "미니맵 최대 길이", animSpeed = "애니메이션 속도", targetSize = "목표 마커 크기",
        futureDesc = "현재 목표 이후의 추가 RestedXP 목적지를 표시합니다.", future0 = "끔", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "기본값", resetDone = "설정이 초기화되었습니다", step = "RXP 단계", target = "RXP 목표", current = "현재", next = "다음",
        theme_navigator = "내비게이터 그린", theme_emerald = "에메랄드", theme_cyan = "비전 블루", theme_gold = "골드", theme_red = "엠버 레드", theme_violet = "바이올렛",
    },
    zhCN = {
        subtitle = "RXPGuides 独立导航 — 小地图、世界地图、目标标记和后续目标。",
        colorTheme = "颜色主题", display = "显示", line = "路线", upcoming = "后续目标",
        enabled = "启用导航", minimap = "在小地图显示", worldmap = "在世界/区域地图显示", distance = "在小地图显示距离",
        marker = "显示带金色边框的目标标记", tooltip = "世界地图目标鼠标提示", animation = "动态方向箭头", hudArrow = "显示带距离和 ETA 的导航箭头", hudSettings="导航箭头", hudMode="箭头模式", hud2D="2D", hud3D="3D", hudDesign="设计", hudModern="现代", hudClassic="经典", hudLock="锁定位置", hudSize="箭头大小", hudDistance="显示距离", hudETA="显示 ETA", hudResetPos="重置箭头位置", hudColor="箭头颜色", hudDragHint="解锁后拖动导航箭头",
        thin = "细", normal = "普通", strong = "粗", maxMinimap = "小地图最大长度", animSpeed = "动画速度", targetSize = "目标标记大小",
        futureDesc = "显示当前目标之后的额外 RestedXP 目的地。", future0 = "关闭", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "默认值", resetDone = "设置已重置", step = "RXP 步骤", target = "RXP 目标", current = "当前", next = "下一步",
        theme_navigator = "导航绿", theme_emerald = "翡翠", theme_cyan = "奥术蓝", theme_gold = "金色", theme_red = "余烬红", theme_violet = "紫罗兰",
    },
    zhTW = {
        subtitle = "RXPGuides 獨立導航 — 小地圖、世界地圖、目標標記與後續目標。",
        colorTheme = "顏色主題", display = "顯示", line = "路線", upcoming = "後續目標",
        enabled = "啟用導航", minimap = "顯示於小地圖", worldmap = "顯示於世界/區域地圖", distance = "在小地圖顯示距離",
        marker = "顯示帶金色邊框的目標標記", tooltip = "世界地圖目標滑鼠提示", animation = "動態方向箭頭", hudArrow = "顯示含距離與 ETA 的導航箭頭", hudSettings="導航箭頭", hudMode="箭頭模式", hud2D="2D", hud3D="3D", hudDesign="設計", hudModern="現代", hudClassic="經典", hudLock="鎖定位置", hudSize="箭頭大小", hudDistance="顯示距離", hudETA="顯示 ETA", hudResetPos="重設箭頭位置", hudColor="箭頭顏色", hudDragHint="解鎖後拖曳導航箭頭",
        thin = "細", normal = "一般", strong = "粗", maxMinimap = "小地圖最大長度", animSpeed = "動畫速度", targetSize = "目標標記大小",
        futureDesc = "顯示目前目標之後的額外 RestedXP 目的地。", future0 = "關閉", future1 = "+1", future2 = "+2", future3 = "+3", future4 = "+4", future5 = "+5", future6 = "+6",
        reset = "預設值", resetDone = "設定已重設", step = "RXP 步驟", target = "RXP 目標", current = "目前", next = "下一步",
        theme_navigator = "導航綠", theme_emerald = "翡翠", theme_cyan = "秘法藍", theme_gold = "金色", theme_red = "餘燼紅", theme_violet = "紫羅蘭",
    },
}

local EXTRA_LOCALES = {
    enUS = { generalSection="General", minimapSection="Minimap", worldmapSection="World Map", advancedSection="Advanced", ghostNav="Corpse-run navigation while dead", upcomingAmount="Upcoming goals", groupedHere="Goals at this location", alsoHere="Also at this location", corpse="Corpse", corpseRun="Corpse Run", returnCorpse="Return to your corpse", corpseSettings="Corpse Run", corpseSkullOpacity="Skull opacity", corpseHudSkullSize="HUD skull size", corpseRouteSkullSize="Route skull size", corpseAnimSpeed="Skull animation speed", hudTextSize="Text Size" },
    deDE = { generalSection="Allgemein", minimapSection="Minimap", worldmapSection="Weltkarte", advancedSection="Erweitert", ghostNav="Leichen-Navigation im Geistmodus", upcomingAmount="Folgeziele", groupedHere="Ziele an diesem Ort", alsoHere="Ebenfalls an diesem Ort", corpse="Leiche", corpseRun="Leichenlauf", returnCorpse="Kehre zu deiner Leiche zurück", corpseSettings="Leichenlauf", corpseSkullOpacity="Schädel-Deckkraft", corpseHudSkullSize="HUD-Schädelgröße", corpseRouteSkullSize="Routen-Schädelgröße", corpseAnimSpeed="Schädel-Animationsgeschwindigkeit", hudTextSize="Textgröße" },
    frFR = { generalSection="Général", minimapSection="Minicarte", worldmapSection="Carte du monde", advancedSection="Avancé", ghostNav="Navigation vers le cadavre en fantôme", upcomingAmount="Objectifs suivants", groupedHere="Objectifs à cet emplacement", alsoHere="Également à cet emplacement", corpse="Cadavre", corpseRun="Retour au cadavre", returnCorpse="Retournez à votre cadavre", corpseSettings="Retour au cadavre", corpseSkullOpacity="Opacité du crâne", corpseHudSkullSize="Taille du crâne HUD", corpseRouteSkullSize="Taille des crânes de route", corpseAnimSpeed="Vitesse des crânes", hudTextSize="Taille du texte" },
    esES = { generalSection="General", minimapSection="Minimapa", worldmapSection="Mapa mundial", advancedSection="Avanzado", ghostNav="Navegación al cadáver como fantasma", upcomingAmount="Objetivos siguientes", groupedHere="Objetivos en esta ubicación", alsoHere="También en esta ubicación", corpse="Cadáver", corpseRun="Regreso al cadáver", returnCorpse="Regresa a tu cadáver", corpseSettings="Regreso al cadáver", corpseSkullOpacity="Opacidad de calavera", corpseHudSkullSize="Tamaño calavera HUD", corpseRouteSkullSize="Tamaño calaveras de ruta", corpseAnimSpeed="Velocidad de calaveras", hudTextSize="Tamaño del texto" },
    itIT = { generalSection="Generale", minimapSection="Minimappa", worldmapSection="Mappa del mondo", advancedSection="Avanzate", ghostNav="Navigazione al cadavere da fantasma", upcomingAmount="Obiettivi successivi", groupedHere="Obiettivi in questa posizione", alsoHere="Anche in questa posizione", corpse="Cadavere", corpseRun="Ritorno al cadavere", returnCorpse="Torna al tuo cadavere", corpseSettings="Ritorno al cadavere", corpseSkullOpacity="Opacità teschio", corpseHudSkullSize="Dimensione teschio HUD", corpseRouteSkullSize="Dimensione teschi percorso", corpseAnimSpeed="Velocità teschi", hudTextSize="Dimensione testo" },
    ptBR = { generalSection="Geral", minimapSection="Minimapa", worldmapSection="Mapa-múndi", advancedSection="Avançado", ghostNav="Navegação até o corpo como fantasma", upcomingAmount="Próximos objetivos", groupedHere="Objetivos neste local", alsoHere="Também neste local", corpse="Corpo", corpseRun="Corrida ao corpo", returnCorpse="Volte ao seu corpo", corpseSettings="Corrida ao corpo", corpseSkullOpacity="Opacidade da caveira", corpseHudSkullSize="Tamanho da caveira HUD", corpseRouteSkullSize="Tamanho das caveiras da rota", corpseAnimSpeed="Velocidade das caveiras", hudTextSize="Tamanho do texto" },
    ruRU = { generalSection="Общие", minimapSection="Мини-карта", worldmapSection="Карта мира", advancedSection="Дополнительно", ghostNav="Навигация к телу в облике духа", upcomingAmount="Следующие цели", groupedHere="Цели в этой точке", alsoHere="Также в этой точке", corpse="Тело", corpseRun="Путь к телу", returnCorpse="Вернитесь к своему телу", corpseSettings="Путь к телу", corpseSkullOpacity="Прозрачность черепа", corpseHudSkullSize="Размер черепа HUD", corpseRouteSkullSize="Размер черепов маршрута", corpseAnimSpeed="Скорость черепов", hudTextSize="Размер текста" },
    koKR = { generalSection="일반", minimapSection="미니맵", worldmapSection="월드맵", advancedSection="고급", ghostNav="유령 상태에서 시체까지 안내", upcomingAmount="다음 목표", groupedHere="이 위치의 목표", alsoHere="이 위치의 추가 목표", corpse="시체", corpseRun="시체로 이동", returnCorpse="시체로 돌아가세요", corpseSettings="시체로 이동", corpseSkullOpacity="해골 투명도", corpseHudSkullSize="HUD 해골 크기", corpseRouteSkullSize="경로 해골 크기", corpseAnimSpeed="해골 애니메이션 속도", hudTextSize="텍스트 크기" },
    zhCN = { generalSection="常规", minimapSection="小地图", worldmapSection="世界地图", advancedSection="高级", ghostNav="灵魂状态导航至尸体", upcomingAmount="后续目标", groupedHere="此位置的目标", alsoHere="此位置的其他目标", corpse="尸体", corpseRun="跑尸", returnCorpse="返回你的尸体", corpseSettings="跑尸", corpseSkullOpacity="骷髅透明度", corpseHudSkullSize="HUD 骷髅大小", corpseRouteSkullSize="路线骷髅大小", corpseAnimSpeed="骷髅动画速度", hudTextSize="文字大小" },
    zhTW = { generalSection="一般", minimapSection="小地圖", worldmapSection="世界地圖", advancedSection="進階", ghostNav="靈魂狀態導航至屍體", upcomingAmount="後續目標", groupedHere="此位置的目標", alsoHere="此位置的其他目標", corpse="屍體", corpseRun="跑屍", returnCorpse="返回你的屍體", corpseSettings="跑屍", corpseSkullOpacity="骷髏透明度", corpseHudSkullSize="HUD 骷髏大小", corpseRouteSkullSize="路線骷髏大小", corpseAnimSpeed="骷髏動畫速度", hudTextSize="文字大小" },
}
for code, values in pairs(EXTRA_LOCALES) do
    if LOCALES[code] then
        for key, value in pairs(values) do LOCALES[code][key] = value end
    end
end

LOCALES.esMX = LOCALES.esES
LOCALES.enGB = LOCALES.enUS

local FEATURE_LOCALES = {
    enUS = {
        offscreenIndicator="Off-screen target indicator", currentHighlight="Highlight current target", routeDistances="Show distance between route steps", tooltipType="Type", tooltipProgress="Progress", tooltipObjective="Objective",
        stepTypeIcons="Show step-type icon in target tooltip", questProgress="Show quest progress in target tooltip", zoneHints="Zone transition hints", transportHints="Travel/transport hints",
        spiritHealer="Show Spirit Healer hint while dead", corpseNearby="Corpse nearby",
        minimapMarkerSize="Minimap marker size", worldMarkerSize="World-map marker size", minimapAnimSpeed="Minimap arrow speed", worldAnimSpeed="World-map arrow speed",
        mapDiagnostics="Map diagnostics", bugReport="Bug report", nextZone="Next zone", travel="Travel", travelTo="Travel to", travelZeppelin="Zeppelin", travelShip="Ship", travelStart="Start", travelThen="Then", spiritHealerLabel="Spirit Healer", routePreview="Route preview", rxpActiveCircle="Show RestedXP active target circle", searchAreas="Search areas", patrolPaths="Patrol paths", farmRoutes="Farm routes", objectMarkers="Quest object markers", searchAreaOpacity="Search area opacity", patrolOpacity="Patrol opacity", farmOpacity="Farm opacity", minimapButton="Minimap settings button",
    },
    deDE = {
        offscreenIndicator="Off-Screen-Zielanzeige", currentHighlight="Aktuelles Ziel hervorheben", routeDistances="Distanz zwischen Routenzielen anzeigen", tooltipType="Typ", tooltipProgress="Fortschritt", tooltipObjective="Ziel",
        stepTypeIcons="Step-Typ-Symbol im Ziel-Tooltip anzeigen", questProgress="Questfortschritt im Ziel-Tooltip anzeigen", zoneHints="Gebietswechsel-Hinweise", transportHints="Reise-/Transport-Hinweise",
        spiritHealer="Geistheiler-Hinweis im Geistmodus", corpseNearby="Leiche in der Nähe",
        minimapMarkerSize="Minimap-Markergröße", worldMarkerSize="Weltkarten-Markergröße", minimapAnimSpeed="Minimap-Pfeilgeschwindigkeit", worldAnimSpeed="Weltkarten-Pfeilgeschwindigkeit",
        mapDiagnostics="Kartendiagnose", bugReport="Fehlerbericht", nextZone="Nächstes Gebiet", travel="Reise", travelTo="Reise nach", travelZeppelin="Zeppelin", travelShip="Schiff", travelStart="Start", travelThen="Danach", spiritHealerLabel="Geistheiler", routePreview="Routenvorschau", rxpActiveCircle="RestedXP-Zielkreis auf der Karte anzeigen", searchAreas="Suchbereiche", patrolPaths="Patrouillenwege", farmRoutes="Farmrouten", objectMarkers="Questobjekt-Marker", searchAreaOpacity="Suchbereich-Deckkraft", patrolOpacity="Patrouillen-Deckkraft", farmOpacity="Farmrouten-Deckkraft", minimapButton="Minimap-Einstellungsbutton",
    },
}
for code, values in pairs(FEATURE_LOCALES) do
    if LOCALES[code] then for key, value in pairs(values) do LOCALES[code][key] = value end end
end

local function GetLocaleTable()
    local code = GetLocale and GetLocale() or "enUS"
    return LOCALES[code] or LOCALES.enUS
end

local function L(key)
    local t = GetLocaleTable()
    return t[key] or LOCALES.enUS[key] or key
end

local defaults = {
    enabled = true,
    showMinimap = true,
    showDistance = true,
    showWorldMap = true,
    showTargetMarker = true,
    showTaskTooltip = true,
    showHUDArrow = true,
    hudLocked = false,
    hudColorR = 0.08,
    hudColorG = 0.74,
    hudColorB = 1.00,
    hudSize = 1.0,
    hudTextSize = 1.0,
    hudArrowStyle = "classic",
    corpseSkullAlpha = 0.30,
    corpseHudSkullSize = 24,
    corpseRouteSkullSize = 14,
    corpseAnimationSpeed = 0.5,
    hudShowDistance = true,
    hudShowETA = true,
    hudPoint = "TOP",
    hudRelativePoint = "TOP",
    hudX = 0,
    hudY = -120,
    lineLength = 96,
    lineStyle = "normal",
    animation = true,
    animationSpeed = 0.5, -- legacy fallback
    targetSize = 14, -- legacy fallback
    minimapAnimationSpeed = 0.5,
    worldAnimationSpeed = 0.5,
    minimapTargetSize = 14,
    worldTargetSize = 14,
    showOffscreenIndicator = true,
    currentHighlight = true,
    showRXPActivePinCircle = false,
    showRouteDistances = false,
    showStepTypeIcons = true,
    showQuestProgress = true,
    showZoneHints = true,
    showTransportHints = true,
    showSpiritHealer = true,
    theme = "navigator",
    futureGoals = 3,
    showSearchAreas = true,
    showPatrolPaths = true,
    showFarmRoutes = true,
    showObjectMarkers = true,
    searchAreaAlpha = 0.18,
    patrolAlpha = 0.78,
    farmAlpha = 0.86,
    showMinimapButton = true,
    showMinimapFutureGoals = true,
    minimapButtonAngle = 220,
    keepGhostNavigation = true,
}

local db
local lastPlayerMapID, lastPlayerX, lastPlayerY, lastPlayerPosTime
local lastCorpseMapID, lastCorpseX, lastCorpseY
local overlay
local minimapRouteOutlineTexture
local minimapRouteTexture
local minimapArrows = {}
local targetDot
local minimapEdgeArrow
local minimapEdgeDistanceText
local distanceText
local elapsed = 0
local mapElapsed = 0

local worldMapOverlay
local worldMainRouteOutlineTexture
local worldMainRouteTexture
local worldTargetPin
local worldFuturePins = {}
local worldHitboxes = {}
local worldTaskFrame
local worldArrows = {}
local worldArrowTextures = {}
local worldArrowLayer
local worldFutureArrows = {}
local worldRouteDistanceLabels = {}
local worldSpiritHealerIcon
local worldCanvas
local worldRouteLines = {}
local worldRouteShadows = {}
local worldNativeLines = {}
local worldNativeShadows = {}

local hudArrowFrame
local hudArrowTexture
local hudCorpseSkull
local hudArrowShadow
local hudBackground
local hudBorder = {}
local hudDistanceText
local hudEtaText
local hudContextText
local hudDragHint
local hudElapsed = 0

-- Debug/Inspector capture is owned by Debug\Inspector.lua. Core chat output
-- only forwards lines to that module when a capture is active.
local function Print(msg)
    msg = tostring(msg)
    if Navigator.Debug and Navigator.Debug.CaptureLine then
        Navigator.Debug:CaptureLine(msg)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RestedXP-Navigator:|r " .. msg)
end

local function CopyDefaults()
    RXPNavigatorDB = RXPNavigatorDB or {}
    -- One-time, non-destructive migration: users who already tuned the legacy
    -- shared marker/animation settings keep those values as the initial values
    -- for the new separate minimap/world-map controls.
    if RXPNavigatorDB.minimapTargetSize == nil and RXPNavigatorDB.targetSize ~= nil then RXPNavigatorDB.minimapTargetSize = RXPNavigatorDB.targetSize end
    if RXPNavigatorDB.worldTargetSize == nil and RXPNavigatorDB.targetSize ~= nil then RXPNavigatorDB.worldTargetSize = RXPNavigatorDB.targetSize end
    if RXPNavigatorDB.minimapAnimationSpeed == nil and RXPNavigatorDB.animationSpeed ~= nil then RXPNavigatorDB.minimapAnimationSpeed = RXPNavigatorDB.animationSpeed end
    if RXPNavigatorDB.worldAnimationSpeed == nil and RXPNavigatorDB.animationSpeed ~= nil then RXPNavigatorDB.worldAnimationSpeed = RXPNavigatorDB.animationSpeed end
    for k, v in pairs(defaults) do
        if RXPNavigatorDB[k] == nil then
            RXPNavigatorDB[k] = v
        end
    end

    -- hotfix12: after presets were removed it was possible to have the
    -- Minimap Next Steps toggle enabled while futureGoals remained 0.
    -- That state is contradictory in the UI and renders no future targets.
    -- Migrate it once to a useful default (+3). Users can still explicitly
    -- disable Next Steps or choose 0 afterwards.
    if RXPNavigatorDB.futureGoalsMigration12 ~= true then
        if RXPNavigatorDB.showMinimapFutureGoals ~= false and (tonumber(RXPNavigatorDB.futureGoals) or 0) <= 0 then
            RXPNavigatorDB.futureGoals = 3
        end
        RXPNavigatorDB.futureGoalsMigration12 = true
    end
    if not THEMES[RXPNavigatorDB.theme] then RXPNavigatorDB.theme = "navigator" end
    RXPNavigatorDB.routingEnabled = nil
    RXPNavigatorDB.roadLearning = nil
    RXPNavigatorDB.roadPreference = nil
    RXPNavigatorDB.maxDetour = nil
    RXPNavigatorDB.maxRoadJoin = nil
    RXPNavigatorDB.maxRoadExit = nil
    RXPNavigatorDB.preloadedDataVersion = nil
    RXPNavigatorDB.debug = nil
    RXPNavigatorDB.orientationOffset = nil
    RXPNavigatorDB.hudMode = nil
    RXPNavigatorDB.hudDesign = nil
    -- v1.2.0-beta13: world/zone-map route distance labels are intentionally removed.
    RXPNavigatorDB.showRouteDistances = false
    db = RXPNavigatorDB
end

local function GetTheme()
    return THEMES[(db and db.theme) or "navigator"] or THEMES.navigator
end

local function GetOutlineColor(theme)
    local line = (theme and theme.line) or {0.12, 0.95, 0.30}
    local darken = 0.34
    return math.max(0, line[1] * darken), math.max(0, line[2] * darken), math.max(0, line[3] * darken)
end

local function GetRXPArrowElement()
    local frame = _G.RXPG_ARROW
    if frame and frame.element then return frame.element end
    return nil
end

local function NormalizeMapCoord(v)
    v = tonumber(v)
    if not v then return nil end
    if v > 1 then return v / 100 end
    return v
end

local function GetTargetMap(element)
    if not element then return nil end
    local mapID = tonumber(element.zone or element.mapID or element.map)
    -- RXPGuides uses x/y for regular goto/waypoint elements, but
    -- ingamewaypoint elements store normalized coordinates in zx/zy.
    local rawX = element.x
    local rawY = element.y
    if type(rawX) ~= "number" or type(rawY) ~= "number" then
        rawX = element.zx
        rawY = element.zy
    end
    local x = NormalizeMapCoord(rawX)
    local y = NormalizeMapCoord(rawY)
    if not mapID or not x or not y then return nil end
    return mapID, x, y
end

local function GetXY(pos)
    if not pos then return nil end
    if type(pos.GetXY) == "function" then return pos:GetXY() end
    return pos.x, pos.y
end

local function GetWorldPosForMap(mapID, x, y)
    if not (C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
    if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return nil end
    local continentID, worldPos = C_Map.GetWorldPosFromMapPos(mapID, { x = x, y = y })
    if not continentID or not worldPos then return nil end
    local wx, wy = GetXY(worldPos)
    if type(wx) ~= "number" or type(wy) ~= "number" then return nil end
    return wx, wy, continentID
end

local function GetTargetWorld(element)
    if not element then return nil end

    -- Derive world coordinates through Blizzard's C_Map API whenever map
    -- coordinates are available. RXPGuides wx/wy are useful internally but
    -- are not guaranteed to use the same axis/scale convention as C_Map on
    -- every Forever map.
    local mapID, x, y = GetTargetMap(element)
    if mapID and x and y then
        local wx, wy, continentID = GetWorldPosForMap(mapID, x, y)
        if wx and wy then return wx, wy, continentID end
    end

    -- Last-resort fallback only.
    local wx, wy = tonumber(element.wx), tonumber(element.wy)
    if wx and wy then return wx, wy, nil end
    return nil
end

local function GetPlayerPositionForMap(mapID)
    if not (C_Map and C_Map.GetPlayerMapPosition) or type(mapID) ~= "number" then return nil end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y = GetXY(pos)
    -- Some parent/world maps can return unusable translated coordinates. Only
    -- accept a real normalized position on the candidate map.
    if type(x) == "number" and type(y) == "number"
       and x >= 0 and x <= 1 and y >= 0 and y <= 1
       and (x ~= 0 or y ~= 0) then
        lastPlayerMapID, lastPlayerX, lastPlayerY = mapID, x, y
        lastPlayerPosTime = GetTime and GetTime() or 0
        return x, y
    end
    return nil
end

-- Resolve the player's position defensively. On Forever the automatic
-- GetBestMapForUnit() lookup can temporarily return nil while dead/ghosted,
-- even though GetPlayerMapPosition() still works when queried with the zone.


-- World-coordinate player fallback for Forever/Classic map edge cases.
-- This is deliberately isolated from the normal C_Map path: it is only
-- consulted after all validated map-position lookups failed.
Navigator.UnitPositionFallback = Navigator.UnitPositionFallback or {}

function Navigator.UnitPositionFallback:Resolve(preferredMapID)
    if type(UnitPosition) ~= "function" or not (C_Map and C_Map.GetMapPosFromWorldPos and C_Map.GetWorldPosFromMapPos) then return nil end

    local ok, a, b, z, instanceID = pcall(UnitPosition, "player")
    if not ok or type(a) ~= "number" or type(b) ~= "number" or type(instanceID) ~= "number" then return nil end
    if a == 0 and b == 0 then return nil end

    local function tryMap(mapID)
        mapID = tonumber(mapID)
        if not mapID or mapID <= 0 then return nil end
        for _, worldPos in ipairs({{x=a,y=b},{x=b,y=a}}) do
            local okPos, _, mapPos = pcall(C_Map.GetMapPosFromWorldPos, instanceID, worldPos, mapID)
            if okPos and mapPos then
                local x, y = GetXY(mapPos)
                if type(x)=="number" and type(y)=="number" and x>=0 and x<=1 and y>=0 and y<=1 and (x~=0 or y~=0) then
                    -- Round-trip validation: never accept a guessed map unless converting
                    -- back to world coordinates lands very close to UnitPosition.
                    local okWorld, c, back = pcall(C_Map.GetWorldPosFromMapPos, mapID, {x=x,y=y})
                    if okWorld and c == instanceID and back then
                        local bx, by = GetXY(back)
                        if bx and by then
                            local dx, dy = bx-worldPos.x, by-worldPos.y
                            if (dx*dx + dy*dy) <= 4 then
                                self.mapID, self.x, self.y, self.instanceID = mapID, x, y, instanceID
                                self.rawA, self.rawB = a, b
                                return mapID, x, y, "UnitPosition world fallback"
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    -- Fast path: re-check the last map that succeeded through UnitPosition.
    local m,x,y,src = tryMap(self.mapID)
    if m then return m,x,y,src end
    m,x,y,src = tryMap(preferredMapID)
    if m then return m,x,y,src end
    m,x,y,src = tryMap(lastPlayerMapID)
    if m then return m,x,y,src end

    local roots, seen = {}, {}
    local function addRoot(id)
        id=tonumber(id)
        if id and id>0 and not seen[id] then seen[id]=true; roots[#roots+1]=id end
    end
    if MapUtil and type(MapUtil.GetDisplayableMapForPlayer)=="function" then
        local okMap,id=pcall(MapUtil.GetDisplayableMapForPlayer); if okMap then addRoot(id) end
    end
    if WorldMapFrame and type(WorldMapFrame.GetMapID)=="function" then
        local okMap,id=pcall(WorldMapFrame.GetMapID,WorldMapFrame); if okMap then addRoot(id) end
    end
    if WorldMapFrame then addRoot(WorldMapFrame.mapID) end

    -- Scan descendants only as a last resort and validate every result by
    -- UnitPosition round-trip. This prevents selecting a wrong continent/zone.
    if C_Map and type(C_Map.GetMapChildrenInfo)=="function" then
        for _,rootID in ipairs(roots) do
            local okChildren,children=pcall(C_Map.GetMapChildrenInfo,rootID,nil,true)
            if okChildren and type(children)=="table" then
                for _,wantedType in ipairs({5,4,3,2}) do
                    for _,info in ipairs(children) do
                        if info and info.mapType==wantedType then
                            local id=info.mapID or info.uiMapID
                            m,x,y,src=tryMap(id)
                            if m then return m,x,y,src end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function ResolvePlayerMapAndPosition(preferredMapID)
    local candidates, seen, sources = {}, {}, {}
    local function AddCandidate(mapID, source)
        mapID = tonumber(mapID)
        if mapID and mapID > 0 and not seen[mapID] then
            seen[mapID] = true
            candidates[#candidates + 1] = mapID
            sources[mapID] = source or "candidate"
        end
    end

    -- Primary path: keep Blizzard's normal player-map lookup first. This is
    -- the path used by all previously working zones and must remain preferred.
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then AddCandidate(mapID, "C_Map.GetBestMapForUnit") end
    end

    -- Some Forever map transitions / dungeon or micro maps return nil above,
    -- while MapUtil can still resolve a displayable map for the player.
    if MapUtil and type(MapUtil.GetDisplayableMapForPlayer) == "function" then
        local ok, mapID = pcall(MapUtil.GetDisplayableMapForPlayer)
        if ok then AddCandidate(mapID, "MapUtil.GetDisplayableMapForPlayer") end
    end

    -- Legacy/Forever path: some clients only refresh their current-map state
    -- after SetMapToCurrentZone(). We do this only after the modern lookups,
    -- then validate any result before it can become the active player position.
    if type(SetMapToCurrentZone) == "function" then
        pcall(SetMapToCurrentZone)
    end

    if type(GetCurrentMapAreaID) == "function" then
        local ok, mapID = pcall(GetCurrentMapAreaID)
        if ok then AddCandidate(mapID, "GetCurrentMapAreaID after SetMapToCurrentZone") end
    end

    -- Older map APIs can sometimes still return the player's coordinates when
    -- C_Map.GetBestMapForUnit/GetPlayerMapPosition return nil. Pair those
    -- coordinates with the refreshed current map, but accept them only when
    -- both values are plausible normalized map coordinates.
    if type(GetPlayerMapPosition) == "function" then
        local ok, lx, ly = pcall(GetPlayerMapPosition, "player")
        if ok and type(lx) == "number" and type(ly) == "number"
           and lx >= 0 and lx <= 1 and ly >= 0 and ly <= 1
           and (lx ~= 0 or ly ~= 0) then
            local legacyMapID
            if type(GetCurrentMapAreaID) == "function" then
                local okMap, id = pcall(GetCurrentMapAreaID)
                if okMap then legacyMapID = tonumber(id) end
            end
            if legacyMapID and legacyMapID > 0 then
                lastPlayerMapID, lastPlayerX, lastPlayerY = legacyMapID, lx, ly
                lastPlayerPosTime = GetTime and GetTime() or 0
                return legacyMapID, lx, ly, "legacy GetPlayerMapPosition"
            end
        end
    end

    -- The target map is intentionally tried before any speculative child map.
    AddCandidate(preferredMapID, "preferred/target map")
    AddCandidate(lastPlayerMapID, "last valid map")

    -- If the player is inside a dungeon/micro-map belonging to the preferred
    -- zone, GetPlayerMapPosition(parentZone) may be nil. Probe child maps, but
    -- never trust them blindly: GetPlayerPositionForMap must validate each one.
    local function AddChildMaps(parentMapID, depth)
        if not (parentMapID and depth and depth > 0 and C_Map and type(C_Map.GetMapChildrenInfo) == "function") then return end
        local ok, children = pcall(C_Map.GetMapChildrenInfo, parentMapID)
        if not ok or type(children) ~= "table" then return end
        local count = 0
        for _, info in ipairs(children) do
            local childID = info and (info.mapID or info.uiMapID)
            if childID then
                AddCandidate(childID, "child of " .. tostring(parentMapID))
                count = count + 1
                if depth > 1 and count <= 24 then AddChildMaps(childID, depth - 1) end
                if count >= 48 then break end
            end
        end
    end
    AddChildMaps(preferredMapID, 2)

    -- WorldMapFrame can retain a valid current map even while hidden. Probe it
    -- unconditionally, but still require a valid player position before use.
    if WorldMapFrame and type(WorldMapFrame.GetMapID) == "function" then
        local ok, mapID = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
        if ok then AddCandidate(mapID, "WorldMapFrame:GetMapID") end
    end
    if WorldMapFrame and WorldMapFrame.mapID then
        AddCandidate(WorldMapFrame.mapID, "WorldMapFrame.mapID")
    end

    -- Forever can expose only the Azeroth/world map (for example uiMapID 947)
    -- while GetBestMapForUnit() is nil. A player position cannot be queried on
    -- that world map, so as a last-resort discovery step scan its descendants.
    -- This runs only after all normal/legacy candidates were collected and only
    -- accepts a descendant for which Blizzard returns a valid normalized player
    -- position. Nothing is inferred from zone names or hard-coded map IDs.
    if C_Map and type(C_Map.GetMapInfo) == "function"
       and type(C_Map.GetMapChildrenInfo) == "function" then
        local worldRoots = {}
        for _, candidateID in ipairs(candidates) do
            local okInfo, info = pcall(C_Map.GetMapInfo, candidateID)
            if okInfo and info and (info.mapType == 1 or info.mapType == 2) then
                worldRoots[#worldRoots + 1] = candidateID
            end
        end
        for _, rootID in ipairs(worldRoots) do
            local okChildren, descendants = pcall(C_Map.GetMapChildrenInfo, rootID, nil, true)
            if okChildren and type(descendants) == "table" then
                -- Prefer micro/dungeon maps before ordinary zones; if the player
                -- is inside one of those they are the most precise representation.
                for _, wantedType in ipairs({5, 4, 3}) do
                    for _, info in ipairs(descendants) do
                        local childID = info and (info.mapID or info.uiMapID)
                        if childID and info.mapType == wantedType then
                            local x, y = GetPlayerPositionForMap(childID)
                            if x and y then
                                return childID, x, y, "recursive descendant of " .. tostring(rootID)
                            end
                        end
                    end
                end
            end
        end
    end

    for _, mapID in ipairs(candidates) do
        local x, y = GetPlayerPositionForMap(mapID)
        if x and y then return mapID, x, y, sources[mapID] end
    end

    -- Last-resort world-coordinate fallback. This avoids relying on
    -- GetPlayerMapPosition() when Forever exposes only a world-level map.
    if Navigator.UnitPositionFallback and Navigator.UnitPositionFallback.Resolve then
        local mapID, x, y, source = Navigator.UnitPositionFallback:Resolve(preferredMapID)
        if mapID and x and y then
            lastPlayerMapID, lastPlayerX, lastPlayerY = mapID, x, y
            lastPlayerPosTime = GetTime and GetTime() or 0
            return mapID, x, y, source
        end
    end

    -- Short grace period prevents the route from blinking out during the
    -- death -> ghost transition. We never keep a stale position indefinitely.
    local deadOrGhost = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
    local now = GetTime and GetTime() or 0
    if db and db.keepGhostNavigation and deadOrGhost and lastPlayerMapID and lastPlayerX and lastPlayerY
       and (not lastPlayerPosTime or now - lastPlayerPosTime <= 8) then
        return lastPlayerMapID, lastPlayerX, lastPlayerY, "ghost grace cache"
    end
    return nil
end

local function GetPlayerWorld(preferredMapID)
    local mapID, x, y = ResolvePlayerMapAndPosition(preferredMapID)
    if not mapID then return nil end
    return GetWorldPosForMap(mapID, x, y)
end

local function GetWorldVectorInPlayerMap(playerMapID, px, py, targetWX, targetWY)
    if not (playerMapID and px and py and targetWX and targetWY) then return nil end
    local pwx, pwy, pcontinent = GetWorldPosForMap(playerMapID, px, py)
    if not pwx then return nil end

    -- Build a tiny local basis from the current Blizzard map. This avoids
    -- assuming a fixed orientation for world coordinates and keeps direction
    -- correct in cities/sub-zones such as Thunder Bluff.
    local eps = 0.001
    local ex = math.min(0.999, px + eps)
    local ey = math.min(0.999, py + eps)
    if ex == px then ex = math.max(0.001, px - eps) end
    if ey == py then ey = math.max(0.001, py - eps) end

    local ewx, ewy, ec = GetWorldPosForMap(playerMapID, ex, py)
    local swx, swy, sc = GetWorldPosForMap(playerMapID, px, ey)
    if not ewx or not swx or ec ~= pcontinent or sc ~= pcontinent then return nil end

    local ax, ay = ewx - pwx, ewy - pwy
    local bx, by = swx - pwx, swy - pwy
    local vx, vy = targetWX - pwx, targetWY - pwy
    local det = ax * by - ay * bx
    if math.abs(det) < 1e-12 then return nil end

    local mapDX = (vx * by - vy * bx) / det * eps
    local mapDY = (ax * vy - ay * vx) / det * eps
    return mapDX, mapDY, pwx, pwy, pcontinent
end

local function WorldDistance(x1, y1, x2, y2)
    if not (x1 and y1 and x2 and y2) then return nil end
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function NormalizeAngle(a)
    while a > math.pi do a = a - PI2 end
    while a < -math.pi do a = a + PI2 end
    return a
end

local function IsMinimapRotating()
    return GetCVar and GetCVar("rotateMinimap") == "1"
end

local MINIMAP_FALLBACK_RADIUS = {
    indoor = { [0]=150, [1]=120, [2]=90, [3]=60, [4]=40, [5]=25 },
    outdoor = { [0]=233.333, [1]=200, [2]=166.667, [3]=133.333, [4]=100, [5]=66.667 },
}

local function GetMinimapViewRadius()
    if C_Minimap and type(C_Minimap.GetViewRadius) == "function" then
        local r = C_Minimap.GetViewRadius()
        if type(r) == "number" and r > 0 then return r end
    end
    local zoom = Minimap and Minimap.GetZoom and Minimap:GetZoom() or 0
    local mode = "outdoor"
    if GetCVar then
        local current = tonumber(zoom)
        local inside = tonumber(GetCVar("minimapInsideZoom"))
        local outside = tonumber(GetCVar("minimapZoom"))
        if inside and outside and inside ~= outside and current == inside then mode = "indoor" end
    end
    return (MINIMAP_FALLBACK_RADIUS[mode] and MINIMAP_FALLBACK_RADIUS[mode][zoom]) or 100
end

local function GetBaseThickness()
    local style = db and db.lineStyle or "normal"
    if style == "thin" then return 3.0 end
    if style == "strong" then return 5.0 end
    return 4.0
end

local function CleanRXPText(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|A.-|a", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("%*quest%*", "Quest")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    text = text:gsub("%s+\n", "\n"):gsub("\n%s+", "\n")
    if text == "" then return nil end
    return text
end

local function GetTargetInstruction(element)
    if not element then return "RestedXP-Ziel" end
    -- RestedXP 4.11+ exposes purpose-built map/tooltip text on many parsed
    -- elements. Prefer those structured fields before falling back to the raw
    -- guide text. This keeps Navigator aligned with what RestedXP itself renders.
    local candidates = { element.mapTooltip, element.tooltipText, element.hiddentext, element.text, element.rawtext }
    for _, value in ipairs(candidates) do
        local cleaned = CleanRXPText(value)
        if cleaned then return cleaned end
    end

    local step = element.step
    if step and step.elements then
        for _, e in ipairs(step.elements) do
            if not e.completed and not e.skip and not e.textOnly then
                local cleaned = CleanRXPText(e.mapTooltip) or CleanRXPText(e.tooltipText) or
                    CleanRXPText(e.hiddentext) or CleanRXPText(e.text) or CleanRXPText(e.rawtext)
                if cleaned then return cleaned end
            end
        end
        local stepText = CleanRXPText(step.mapTooltip) or CleanRXPText(step.tooltipText) or
            CleanRXPText(step.hiddentext) or CleanRXPText(step.text)
        if stepText then return stepText end
    end
    return "Zum RestedXP-Ziel"
end

local function GetTargetStepLabel(element)
    local step = element and element.step
    local index = step and step.index
    if type(index) == "number" then return L("step") .. " " .. tostring(index) end
    return L("target")
end

local function GetStepIndex(element)
    if not element then return nil end
    local step = element.step
    if step and type(step.index) == "number" then return step.index end
    local guide = element.guide
    if guide and guide.steps and step then
        for i, candidate in ipairs(guide.steps) do
            if candidate == step then return i end
        end
    end
    return nil
end

local function FindWaypointElementInStep(step)
    if not step or not step.elements then return nil end
    local fallback
    -- RXPGuides uses textOnly=true together with arrow=true for a number of
    -- genuine navigation waypoints. arrow=true therefore takes precedence
    -- over textOnly when selecting a destination.
    for _, e in ipairs(step.elements) do
        local mapID, x, y = GetTargetMap(e)
        if mapID and x and y and not e.skip and not e.completed then
            if e.arrow == true and not e.lowPrio then return e end
            if not fallback and e.arrow == true then fallback = e end
        end
    end
    if fallback then return fallback end
    for _, e in ipairs(step.elements) do
        local mapID, x, y = GetTargetMap(e)
        if mapID and x and y and not e.skip and not e.completed and not e.textOnly then
            return e
        end
    end
    return nil
end

local function GetRXPGuidesAddon()
    -- RestedXP exposes its public API through the global RXPGuides table.
    -- Do not depend on AceAddon lookup here; Forever builds may not expose
    -- the private addon table under the same AceAddon name.
    local rxp = _G.RXPGuides
    if type(rxp) == "table" then return rxp end
    if LibStub then
        local ace = LibStub("AceAddon-3.0", true)
        if ace then return ace:GetAddon("RXPGuides", true) end
    end
    return nil
end

local function HasUsableCoordinates(element)
    if not element then return false end
    local mapID, x, y = GetTargetMap(element)
    return mapID ~= nil and x ~= nil and y ~= nil
end

local function IsUsableWaypointElement(element)
    if not element or element.skip or element.completed then return false end
    return HasUsableCoordinates(element)
end

local function FindBestWaypointElementInStep(step, rawArrow)
    if not step or not step.elements then return nil end
    if rawArrow and rawArrow.step == step and IsUsableWaypointElement(rawArrow) then
        return rawArrow
    end
    for _, e in ipairs(step.elements) do
        if IsUsableWaypointElement(e) and e.arrow == true and not e.lowPrio then return e end
    end
    for _, e in ipairs(step.elements) do
        if IsUsableWaypointElement(e) and e.arrow == true then return e end
    end
    for _, e in ipairs(step.elements) do
        if IsUsableWaypointElement(e) and not e.textOnly then return e end
    end
    return nil
end

local function GetActiveGuideStepSafe()
    local rxp = GetRXPGuidesAddon()
    local guide = rxp and rxp.currentGuide
    if not (guide and guide.steps) then return nil, nil end
    for i, step in ipairs(guide.steps) do
        if step and step.active == true and not step.completed then return step, i end
    end
    return nil, nil
end

local function IsCorpseRunMode()
    if not (db and db.keepGhostNavigation) then return false end
    if UnitIsGhost then return UnitIsGhost("player") and true or false end
    return UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") and true or false
end

local function GetCorpsePositionForMap(mapID)
    if not (C_DeathInfo and C_DeathInfo.GetCorpseMapPosition) or type(mapID) ~= "number" then return nil end
    local ok, pos = pcall(C_DeathInfo.GetCorpseMapPosition, mapID)
    if not ok or not pos then return nil end
    local x, y = GetXY(pos)
    -- Blizzard may return projected coordinates outside the queried map for
    -- parent/adjacent maps. Those are not valid corpse map positions and must
    -- never be cached or rendered as a route target.
    if type(x) == "number" and type(y) == "number"
        and x >= 0 and x <= 1 and y >= 0 and y <= 1
        and (x ~= 0 or y ~= 0) then
        lastCorpseMapID, lastCorpseX, lastCorpseY = mapID, x, y
        return x, y
    end
    return nil
end

local function GetCorpseNavigationElement()
    if not IsCorpseRunMode() then return nil end
    local candidates, seen = {}, {}
    local function AddMap(mapID)
        if type(mapID) ~= "number" or seen[mapID] then return end
        seen[mapID] = true
        candidates[#candidates + 1] = mapID
    end
    local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    AddMap(currentMap)
    AddMap(lastPlayerMapID)
    AddMap(lastCorpseMapID)
    -- Corpse positions are often exposed on a parent zone map while the ghost
    -- itself is standing in a city/sub-zone map. Walk the map hierarchy.
    local mapID = currentMap
    for _ = 1, 6 do
        local info = mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        local parentID = info and info.parentMapID
        if not parentID or parentID == 0 or parentID == mapID then break end
        AddMap(parentID)
        mapID = parentID
    end
    for _, candidate in ipairs(candidates) do
        local x, y = GetCorpsePositionForMap(candidate)
        if x and y then
            return { zone=candidate, x=x, y=y, arrow=true, textOnly=true, corpseNav=true, text=L("returnCorpse") }
        end
    end
    if lastCorpseMapID and lastCorpseX and lastCorpseY
        and lastCorpseX >= 0 and lastCorpseX <= 1 and lastCorpseY >= 0 and lastCorpseY <= 1 then
        return { zone=lastCorpseMapID, x=lastCorpseX, y=lastCorpseY, arrow=true, textOnly=true, corpseNav=true, text=L("returnCorpse") }
    end
    return nil
end

local function GetCurrentNavigationElement()
    local corpse = GetCorpseNavigationElement()
    if corpse then return corpse, "corpse" end
    local raw = GetRXPArrowElement()
    -- RXPG_ARROW.element is RestedXP's currently selected navigation target.
    -- Trust its coordinates even if completion/skip flags are momentarily stale
    -- during step transitions; those flags are still honored for future goals.
    if HasUsableCoordinates(raw) then
        return raw, "rxp-arrow"
    end

    -- Secondary fallback for builds that expose active waypoints publicly.
    local rxp = GetRXPGuidesAddon()
    local list = rxp and rxp.activeWaypoints
    if type(list) == "table" then
        for _, e in ipairs(list) do
            if e and e.step and e.step.active and IsUsableWaypointElement(e) and e.arrow then
                return e, "active-waypoint"
            end
        end
        for _, e in ipairs(list) do
            if IsUsableWaypointElement(e) and e.arrow then
                return e, "waypoint-fallback"
            end
        end
    end
    return nil, "none"
end


-- Cross-continent travel mode. This does not alter normal navigation; it only
-- activates when Blizzard world coordinates prove that player and target are
-- on different continents/world spaces. In that state a direct air-line route
-- would be misleading, so the HUD switches to a travel hint and map rendering
-- keeps only the destination marker where projection is possible.
Navigator.TravelMode = Navigator.TravelMode or {}

function Navigator.TravelMode:GetContinentName(mapID, continentID)
    local current = mapID
    for _ = 1, 12 do
        local info = current and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(current)
        if not info then break end
        -- Enum.UIMapType.Continent is 2 on the supported client API.
        if info.mapType == 2 and info.name and info.name ~= "" then return info.name end
        local parentID = info.parentMapID
        if not parentID or parentID == 0 or parentID == current then break end
        current = parentID
    end
    -- Classic/Forever world-coordinate IDs observed from C_Map.
    if continentID == 0 then return "Eastern Kingdoms" end
    if continentID == 1 then return "Kalimdor" end
    return nil
end

local function ResolveContinentMapID(mapID)
    local current = tonumber(mapID)
    local last
    for _ = 1, 16 do
        if not current or current == 0 or current == last then break end
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(current)
        if not info then break end
        -- Enum.UIMapType.Continent == 2 on the supported Classic/Forever API.
        if info.mapType == 2 then return current, info.name end
        last = current
        local parentID = tonumber(info.parentMapID)
        if not parentID or parentID == 0 or parentID == current then break end
        current = parentID
    end
    return nil, nil
end

function Navigator.TravelMode:GetInfo(element)
    if not element or element.corpseNav then return nil end
    local targetMapID = GetTargetMap(element)
    if not targetMapID then return nil end
    local playerMapID = ResolvePlayerMapAndPosition(targetMapID)
    if not playerMapID then return nil end

    -- First classify both maps through Blizzard's UI-map hierarchy. This is the
    -- authoritative check for normal zone transitions. Forever can expose
    -- different world-space IDs for neighbouring maps/submaps (for example
    -- Hillsbrad <-> Alterac), which must never trigger cross-continent travel.
    local playerContinentMapID, playerContinentMapName = ResolveContinentMapID(playerMapID)
    local targetContinentMapID, targetContinentMapName = ResolveContinentMapID(targetMapID)
    if playerContinentMapID and targetContinentMapID and playerContinentMapID == targetContinentMapID then
        return nil
    end

    local pwx, pwy, playerWorldSpace = GetPlayerWorld(playerMapID)
    local twx, twy, targetWorldSpace = GetTargetWorld(element)
    if not (pwx and pwy and twx and twy) then return nil end

    -- If both hierarchy lookups succeeded, different continent maps are enough
    -- to confirm real cross-continent travel. If one hierarchy is unavailable,
    -- fall back conservatively to the world-space IDs.
    local confirmedDifferentContinents = playerContinentMapID and targetContinentMapID and playerContinentMapID ~= targetContinentMapID
    if not confirmedDifferentContinents then
        if not (playerWorldSpace and targetWorldSpace) or playerWorldSpace == targetWorldSpace then return nil end
    end

    local targetInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(targetMapID)
    return {
        playerMapID = playerMapID,
        targetMapID = targetMapID,
        playerContinent = playerWorldSpace,
        targetContinent = targetWorldSpace,
        playerContinentMapID = playerContinentMapID,
        targetContinentMapID = targetContinentMapID,
        playerContinentName = playerContinentMapName,
        targetContinentName = targetContinentMapName or self:GetContinentName(targetMapID, targetWorldSpace) or ("Continent " .. tostring(targetWorldSpace or targetContinentMapID or "?")),
        targetZone = targetInfo and targetInfo.name or tostring(targetMapID),
        playerWorldX = pwx, playerWorldY = pwy,
        targetWorldX = twx, targetWorldY = twy,
    }
end

-- Verified Classic cross-continent transport points. These are optional HUD details only:
-- Travel Mode itself still depends exclusively on GetInfo(), so failure to resolve a
-- transport point can never suppress the existing cross-continent warning.
Navigator.TravelMode.routes = {
    { kind="Zeppelin", fromName="Undercity", fromDetail="Tirisfal Glades 61.0, 59.0 - west platform", toName="Orgrimmar", fromMap=1420, fromX=0.610, fromY=0.590, toMap=1411, toX=0.508, toY=0.136 },
    { kind="Zeppelin", fromName="Orgrimmar", fromDetail="Durotar 50.8, 13.6 - south platform", toName="Undercity", fromMap=1411, fromX=0.508, fromY=0.136, toMap=1420, toX=0.610, toY=0.590 },
    { kind="Zeppelin", fromName="Grom'gol", fromDetail="Stranglethorn Vale 31.5, 29.6 - south platform", toName="Orgrimmar", fromMap=1434, fromX=0.315, fromY=0.296, toMap=1411, toX=0.508, toY=0.136 },
    { kind="Zeppelin", fromName="Orgrimmar", fromDetail="Durotar 50.8, 13.6 - north platform", toName="Grom'gol", fromMap=1411, fromX=0.508, fromY=0.136, toMap=1434, toX=0.315, toY=0.296 },
    { kind="Ship", fromName="Booty Bay", fromDetail="Stranglethorn Vale 26.0, 73.2 - dock", toName="Ratchet", fromMap=1434, fromX=0.260, fromY=0.732, toMap=1413, toX=0.636, toY=0.387 },
    { kind="Ship", fromName="Ratchet", fromDetail="The Barrens 63.6, 38.7 - dock", toName="Booty Bay", fromMap=1413, fromX=0.636, fromY=0.387, toMap=1434, toX=0.260, toY=0.732 },
}

function Navigator.TravelMode:GetBestRoute(element, info)
    info = info or self:GetInfo(element)
    if not info then return nil end
    local best, bestScore
    for _, route in ipairs(self.routes or {}) do
        local dwx, dwy, dc = GetWorldPosForMap(route.fromMap, route.fromX, route.fromY)
        local awx, awy, ac = GetWorldPosForMap(route.toMap, route.toX, route.toY)
        if dwx and dwy and awx and awy and dc == info.playerContinent and ac == info.targetContinent then
            local approach = WorldDistance(info.playerWorldX, info.playerWorldY, dwx, dwy)
            local onward = WorldDistance(awx, awy, info.targetWorldX, info.targetWorldY)
            if approach and onward then
                local score = approach + onward + 250
                if not bestScore or score < bestScore then
                    bestScore = score
                    best = route
                end
            end
        end
    end
    return best
end

local function SameWaypoint(a, b)
    if not a or not b then return false end
    if a == b then return true end
    local am, ax, ay = GetTargetMap(a)
    local bm, bx, by = GetTargetMap(b)
    if not (am and ax and ay and bm and bx and by) or am ~= bm then return false end
    return math.abs(ax - bx) < 0.0025 and math.abs(ay - by) < 0.0025
end

local function ResolveActiveGuideAndStep()
    -- Resolve the PRIVATE RestedXP AceAddon directly here. This function is
    -- declared before the diagnostic GetAceRXPAddon helper, so referring to
    -- that later local function would resolve as a global nil in Lua.
    local addon
    if LibStub then
        local okAce, ace = pcall(LibStub, "AceAddon-3.0", true)
        if okAce and ace and type(ace.GetAddon) == "function" then
            local okAddon, a = pcall(ace.GetAddon, ace, "RXPGuides", true)
            if okAddon and type(a) == "table" then addon = a end
        end
    end
    if type(addon) ~= "table" then addon = GetRXPGuidesAddon() end

    local rxpc = rawget(_G, "RXPCData")
    if type(addon) ~= "table" then return nil, nil end

    local guide = rawget(addon, "currentGuide")
    local savedStep
    if type(rxpc) == "table" then
        savedStep = tonumber(rawget(rxpc, "currentStep"))
        if type(guide) ~= "table" then
            local group = rawget(rxpc, "currentGuideGroup")
            local name = rawget(rxpc, "currentGuideName")
            local fn = rawget(addon, "GetGuideTable")
            if type(fn) == "function" and group ~= nil and name ~= nil then
                local ok, g = pcall(fn, group, name)
                if ok and type(g) == "table" then guide = g end
            end
        end
    end
    if type(guide) ~= "table" then return nil, nil end

    local stepIndex = savedStep
    local gp = rawget(addon, "GetGuideProgress")
    if type(gp) == "function" then
        local ok, idx = pcall(gp, guide)
        if ok and tonumber(idx) then stepIndex = tonumber(idx) end
    end
    return guide, stepIndex
end

local function GetBestStepNavigationElement(step)
    if type(step) ~= "table" or step.completed or step.skip then return nil end
    local elements = rawget(step, "elements")
    if type(elements) ~= "table" then return nil end

    local fallback
    for _, e in ipairs(elements) do
        if type(e) == "table" and not e.skip and not e.completed then
            local mapID, x, y = GetTargetMap(e)
            if mapID and x and y then
                if e.arrow == true and not e.lowPrio then return e end
                if e.arrow == true and not fallback then fallback = e end
                if not fallback and not e.textOnly then fallback = e end
                if not fallback then fallback = e end
            end
        end
    end
    return fallback
end

local PositionInDisplayedMap

local function GetSelectedFutureTargets(maxFuture, current)
    local out = {}
    maxFuture = math.max(0, math.min(6, tonumber(maxFuture) or 0))
    if maxFuture == 0 then return out end

    local guide, stepIndex = ResolveActiveGuideAndStep()
    local steps = guide and rawget(guide, "steps")
    if type(steps) ~= "table" or not stepIndex then return out end

    -- Keep each future guide step, even when several steps point to almost the
    -- same location. The world-map renderer clusters those steps into one
    -- marker and exposes every contained objective in the tooltip.
    for si = stepIndex + 1, #steps do
        local step = rawget(steps, si)
        local e = GetBestStepNavigationElement(step)
        if e then
            e.rxpNavigatorStepIndex = si
            out[#out + 1] = e
            if #out >= maxFuture then break end
        end
    end
    return out
end

-- RXP Route Resolver ---------------------------------------------------------
-- RestedXP guide steps can contain ordered .goto/.waypoint chains before the
-- actual objective location. The resolver keeps those intermediate points as
-- route geometry only: they steer HUD/minimap/world-map lines, but do not
-- create extra target markers. If the chain cannot be reconstructed safely,
-- every caller falls back to the proven direct-navigation element.
Navigator.RouteResolver = Navigator.RouteResolver or { revision = 2 }

function Navigator.RouteResolver:IsSpecialOverlayStep(step)
    if type(step) ~= "table" then return false end
    -- RXP #loop blocks are area/farm/patrol geometry, not linear travel.
    -- They must never be appended to the cyan navigation chain.
    if step.loop then return true end
    return false
end

function Navigator.RouteResolver:IsRoutePoint(element)
    if type(element) ~= "table" or element.skip or element.completed or element.arrow ~= true then return false end
    if not HasUsableCoordinates(element) then return false end
    local tag = element.tag
    if not tag and Navigator.RXPData and Navigator.RXPData.GetTag then
        tag = Navigator.RXPData:GetTag(element)
    end
    tag = tag and tostring(tag):lower() or ""
    if tag == "goto" or tag == "groundgoto" or tag == "flygoto" or tag == "questgoto" then return true end
    if tag == "waypoint" or tag == "ingamewaypoint" then return true end
    return tag:find("goto", 1, true) ~= nil or tag:find("waypoint", 1, true) ~= nil
end

function Navigator.RouteResolver:GetStepRouteNodes(step, startElement)
    if type(step) ~= "table" or type(step.elements) ~= "table" then return nil end
    if self:IsSpecialOverlayStep(step) then
        -- If the loop is currently active, keep only RXP's current waypoint as
        -- a direct HUD/minimap target. The full loop is rendered separately.
        if startElement and HasUsableCoordinates(startElement) then return { startElement } end
        return nil
    end

    -- A non-route active target (flight, transport, special generated target,
    -- corpse navigation, etc.) remains authoritative and uses direct routing.
    if startElement and not self:IsRoutePoint(startElement) then
        return HasUsableCoordinates(startElement) and { startElement } or nil
    end

    local startIndex = 1
    if startElement then
        local found
        for i, element in ipairs(step.elements) do
            if element == startElement then startIndex = i; found = true; break end
        end
        if not found then return { startElement } end
    end

    local nodes, lastMap, lastX, lastY = {}, nil, nil, nil
    for i = startIndex, #step.elements do
        local element = step.elements[i]
        if type(element) == "table" and (element == startElement or self:IsRoutePoint(element)) then
            if not element.skip and not element.completed and (element == startElement or not element.lowPrio) then
                local mapID, x, y = GetTargetMap(element)
                if mapID and x and y then
                    local duplicate = lastMap == mapID and lastX and lastY and math.abs(lastX - x) < 0.00005 and math.abs(lastY - y) < 0.00005
                    if not duplicate then
                        nodes[#nodes + 1] = element
                        lastMap, lastX, lastY = mapID, x, y
                    end
                end
            end
        end
    end
    return #nodes > 0 and nodes or nil
end

function Navigator.RouteResolver:GetCurrentPlan()
    local current = GetCurrentNavigationElement()
    if not current then return nil end
    if current.corpseNav then
        return { nextPoint = current, goal = current, nodes = { current }, resolved = false, fallback = true }
    end

    local step = current.step
    if self:IsSpecialOverlayStep(step) then
        return { nextPoint = current, goal = current, nodes = { current }, resolved = false, fallback = true, specialOverlay = true, step = step }
    end
    local nodes = self:GetStepRouteNodes(step, current)
    if not nodes or #nodes == 0 then
        return { nextPoint = current, goal = current, nodes = { current }, resolved = false, fallback = true }
    end
    return {
        nextPoint = nodes[1] or current,
        goal = nodes[#nodes] or current,
        nodes = nodes,
        resolved = #nodes > 1,
        fallback = false,
        step = step,
    }
end

function Navigator.RouteResolver:GetFuturePlans(maxFuture)
    local plans = {}
    maxFuture = math.max(0, math.min(6, tonumber(maxFuture) or 0))
    if maxFuture == 0 then return plans end

    local guide, stepIndex = ResolveActiveGuideAndStep()
    local steps = guide and rawget(guide, "steps")
    if type(steps) ~= "table" or not stepIndex then return plans end

    for si = stepIndex + 1, #steps do
        local step = rawget(steps, si)
        if type(step) == "table" and not step.completed and not step.skip and not self:IsSpecialOverlayStep(step) then
            local nodes = self:GetStepRouteNodes(step)
            local goal
            if nodes and #nodes > 0 then
                goal = nodes[#nodes]
            else
                goal = GetBestStepNavigationElement(step)
                if goal then nodes = { goal } end
            end
            if goal and HasUsableCoordinates(goal) then
                goal.rxpNavigatorStepIndex = si
                for _, element in ipairs(nodes or {}) do element.rxpNavigatorStepIndex = si end
                plans[#plans + 1] = { goal = goal, nodes = nodes or { goal }, step = step, stepIndex = si, resolved = nodes and #nodes > 1 or false }
                if #plans >= maxFuture then break end
            end
        end
    end
    return plans
end

function Navigator.RouteResolver:GetWorldPath(maxFuture)
    local path = {}
    local function Append(element)
        if not element or not HasUsableCoordinates(element) then return end
        local mapID, x, y = GetTargetMap(element)
        local previous = path[#path]
        if previous then
            local pm, px, py = GetTargetMap(previous)
            if pm == mapID and px and py and math.abs(px - x) < 0.00005 and math.abs(py - y) < 0.00005 then return end
        end
        path[#path + 1] = element
    end

    local current = self:GetCurrentPlan()
    if current then
        for _, element in ipairs(current.nodes or {}) do Append(element) end
    end
    if current and current.goal and current.goal.corpseNav then return path end

    for _, plan in ipairs(self:GetFuturePlans(maxFuture)) do
        for _, element in ipairs(plan.nodes or {}) do Append(element) end
    end
    return path
end


-- Route smoothing moved to RXP_Navigator_RouteSmoother.lua

function Navigator.RouteResolver:GetNavigationTargets(maxFuture)
    local current = self:GetCurrentPlan()
    if not current or not current.goal then return {} end
    local out = { current.goal }
    if current.goal.corpseNav then return out end
    for _, plan in ipairs(self:GetFuturePlans(maxFuture)) do
        if plan.goal then out[#out + 1] = plan.goal end
    end
    return out
end

local function GetNavigationTargets(maxFuture)
    if Navigator.RouteResolver and Navigator.RouteResolver.GetNavigationTargets then
        local targets = Navigator.RouteResolver:GetNavigationTargets(maxFuture)
        if type(targets) == "table" and #targets > 0 then return targets end
    end
    -- Safe compatibility fallback to the original direct-navigation model.
    local current = GetCurrentNavigationElement()
    if not current then return {} end
    local out = { current }
    if current.corpseNav then return out end
    local futures = GetSelectedFutureTargets(maxFuture, current)
    for _, e in ipairs(futures) do out[#out + 1] = e end
    return out
end

-- Optional visual metadata helpers. These are intentionally additive: the
-- existing RestedXP target resolver remains the authority for navigation.
local STEP_ICONS = {
    accept = "Interface\\GossipFrame\\AvailableQuestIcon",
    turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
    kill = "Interface\\Icons\\Ability_DualWield",
    loot = "Interface\\Icons\\INV_Misc_Bag_08",
    talk = "Interface\\Icons\\INV_Misc_Note_06",
    travel = "Interface\\Icons\\INV_Misc_Map_01",
}

local function LowerClean(text)
    text = CleanRXPText(text)
    return text and string.lower(text) or ""
end

Navigator.RXPData = Navigator.RXPData or { revision = 0 }
Navigator.RXPData.cache = Navigator.RXPData.cache or setmetatable({}, {__mode = "k"})

function Navigator.RXPData:GetTag(element)
    if not element then return nil end
    local tag = element.tag or element.action or element.type or element.command
    if tag == nil then return nil end
    tag = tostring(tag):lower()
    if tag == "" then return nil end
    return tag
end

function Navigator.RXPData:FirstStructuredName(element)
    if not element then return nil end
    local direct = {element.itemName, element.title, element.targetName, element.mobName, element.npcName}
    for _, value in ipairs(direct) do
        local cleaned = CleanRXPText(value)
        if cleaned then return cleaned end
    end
    for _, key in ipairs({"unitlist", "targets", "mobs", "unitscan"}) do
        local list = element[key]
        if type(list) == "table" then
            for _, value in ipairs(list) do
                if type(value) == "string" then
                    local cleaned = CleanRXPText(value:gsub("^%+", ""))
                    if cleaned then return cleaned end
                end
            end
        end
    end
    return nil
end

-- Normalized RestedXP data model. Renderers continue to consume the original
-- element so 1.2.x visuals stay unchanged, while metadata/diagnostics use a
-- stable Navigator-owned representation. Cache is weak-keyed and invalidated
-- on RestedXP V2 messages or the existing polling fallback.
function Navigator.RXPData:Invalidate()
    self.cache = setmetatable({}, {__mode = "k"})
    self.revision = (self.revision or 0) + 1
end

function Navigator.RXPData:Normalize(element)
    if type(element) ~= "table" then return nil end
    local cached = self.cache[element]
    if cached and cached.revision == self.revision then return cached end

    local mapID, x, y = GetTargetMap(element)
    local questID
    for _, key in ipairs({"questId", "questID", "quest", "q", "qid"}) do
        local n = tonumber(element[key])
        if n and n > 0 then questID = n; break end
    end
    local objectiveIndex = tonumber(element.obj or element.objectiveIndex or element.objectiveNum or element.objective or element.goalIndex)
    local objectiveMax = tonumber(element.objMax)
    local itemID = tonumber(element.id)
    local itemName = CleanRXPText(element.itemName)
    local targetName = self:FirstStructuredName(element)
    local tag = self:GetTag(element)
    local semanticTag = tag

    -- Navigation coordinates are often carried by a .goto element while the
    -- actual objective (.complete/.collect/.accept/.turnin/.mob) lives beside
    -- it in the same RestedXP step. Pull structured metadata from that sibling
    -- context without replacing the navigation element itself.
    local step = element.step
    if type(step) == "table" and type(step.elements) == "table" then
        for _, sibling in ipairs(step.elements) do
            if type(sibling) == "table" and sibling ~= element and not sibling.skip and not sibling.completed then
                local siblingTag = self:GetTag(sibling)
                local siblingQuest = tonumber(sibling.questId or sibling.questID or sibling.quest or sibling.q or sibling.qid)
                if not questID and siblingQuest and siblingQuest > 0 then questID = siblingQuest end
                if not objectiveIndex then objectiveIndex = tonumber(sibling.obj or sibling.objectiveIndex or sibling.objectiveNum or sibling.objective or sibling.goalIndex) end
                if not objectiveMax then objectiveMax = tonumber(sibling.objMax) end
                if not itemID and (siblingTag == "collect" or siblingTag == "collectmultiple") then itemID = tonumber(sibling.id) end
                if not itemName and (siblingTag == "collect" or siblingTag == "collectmultiple") then itemName = CleanRXPText(sibling.itemName) end
                if not targetName then targetName = self:FirstStructuredName(sibling) end
                if (not semanticTag or semanticTag == "goto" or semanticTag == "waypoint" or semanticTag == "zone") and
                   siblingTag and siblingTag ~= "goto" and siblingTag ~= "waypoint" and siblingTag ~= "zone" then
                    semanticTag = siblingTag
                end
            end
        end
    end

    local model = {
        revision = self.revision,
        element = element,
        tag = tag,
        semanticTag = semanticTag,
        questID = questID,
        objectiveIndex = objectiveIndex,
        objectiveMax = objectiveMax,
        itemID = itemID,
        itemName = itemName,
        targetName = targetName,
        instruction = GetTargetInstruction(element),
        mapTooltip = CleanRXPText(element.mapTooltip),
        tooltipText = CleanRXPText(element.tooltipText),
        stepIndex = element.rxpNavigatorStepIndex or GetStepIndex(element),
        mapID = mapID, x = x, y = y,
        completed = element.completed == true,
        skipped = element.skip == true,
        lowPriority = element.lowPrio == true,
    }
    self.cache[element] = model
    return model
end

local function DetectTransportHint(element)
    local model = Navigator.RXPData:Normalize(element)
    local tag = model and (model.semanticTag or model.tag) or Navigator.RXPData:GetTag(element)
    -- Structured RestedXP commands first. These are authoritative and avoid
    -- locale-sensitive text matching for normal flight/hearth/travel steps.
    if tag == "fly" then return "Flight" end
    if tag == "fp" then return "Flight Path" end
    if tag == "hs" or tag == "hsbatching" then return "Hearthstone" end
    if tag == "home" or tag == "bindlocation" then return "Hearthstone" end

    local text = LowerClean(GetTargetInstruction(element))
    if text == "" then return nil end
    if text:find("zeppelin", 1, true) then return "Zeppelin" end
    if text:find("boat", 1, true) or text:find("ship", 1, true) or text:find("schiff", 1, true) then return "Boat" end
    if text:find("portal", 1, true) then return "Portal" end
    if text:find("flight master", 1, true) or text:find("fly to", 1, true) or text:find("flight path", 1, true) or text:find("flugmeister", 1, true) or text:find("fliegt", 1, true) or text:find("fliege", 1, true) or text:find("taxi", 1, true) then return "Flight" end
    return nil
end

local function DetectStepType(element)
    if not element then return nil end
    local model = Navigator.RXPData:Normalize(element)
    local tag = model and (model.semanticTag or model.tag) or Navigator.RXPData:GetTag(element)
    -- Prefer parsed RestedXP tags over natural-language heuristics.
    if tag == "accept" or tag == "daily" then return "accept" end
    if tag == "turnin" or tag == "dailyturnin" then return "turnin" end
    if tag == "collect" or tag == "collectmultiple" then return "loot" end
    if tag == "fly" or tag == "fp" or tag == "goto" or tag == "waypoint" or tag == "zone" or
       tag == "hs" or tag == "hsbatching" or tag == "home" or tag == "bindlocation" then return "travel" end

    -- Some parsed tags (complete/target/unitscan/mob) describe mechanics rather
    -- than intent, so retain text matching as a compatibility fallback.
    local action = tostring(element.action or element.type or element.command or ""):lower()
    local text = LowerClean(GetTargetInstruction(element))
    local combined = (tag or "") .. " " .. action .. " " .. text
    if combined:find("turnin",1,true) or combined:find("turn in",1,true) or combined:find("hand in",1,true) or combined:find("abgeben",1,true) or combined:find("abgabe",1,true) then return "turnin" end
    if combined:find("accept",1,true) or combined:find("pick up",1,true) or combined:find("annehmen",1,true) then return "accept" end
    if DetectTransportHint(element) or combined:find("travel",1,true) or combined:find("reise",1,true) then return "travel" end
    if combined:find("kill",1,true) or combined:find("slay",1,true) or combined:find("defeat",1,true) or combined:find("töte",1,true) or combined:find("toete",1,true) then return "kill" end
    if combined:find("loot",1,true) or combined:find("collect",1,true) or combined:find("gather",1,true) or combined:find("sammel",1,true) or combined:find("plünder",1,true) or combined:find("pluender",1,true) then return "loot" end
    if combined:find("talk",1,true) or combined:find("speak",1,true) or combined:find("sprich",1,true) or combined:find("rede mit",1,true) then return "talk" end
    return nil
end

function Navigator.RXPData:GetActionLabel(stepType)
    local locale = GetLocale and GetLocale() or "enUS"
    local de = locale == "deDE"
    local labels = de and {
        accept = "ANNEHMEN",
        turnin = "ABGEBEN",
        kill = "TÖTEN",
        loot = "SAMMELN",
        talk = "SPRECHEN",
        travel = "REISEN",
    } or {
        accept = "ACCEPT",
        turnin = "TURN IN",
        kill = "KILL",
        loot = "LOOT",
        talk = "TALK",
        travel = "TRAVEL",
    }
    return labels[stepType]
end

local function FindQuestID(element)
    if not element then return nil end
    local model = Navigator.RXPData:Normalize(element)
    if model and model.questID then return model.questID end
    local keys = {"questId","questID","quest","q","qid"}
    for _, key in ipairs(keys) do
        local n = tonumber(element[key])
        if n and n > 0 then return n end
    end
    local step = element.step
    if step and type(step.elements) == "table" then
        for _, e in ipairs(step.elements) do
            for _, key in ipairs(keys) do
                local n = tonumber(e and e[key])
                if n and n > 0 then return n end
            end
        end
    end
    return nil
end

local function NormalizeObjectiveMatchText(text)
    text = CleanRXPText(text)
    if not text then return nil end
    text = text:lower()
    text = text:gsub("%d+%s*/%s*%d+", " ")
    text = text:gsub("%d+", " ")
    text = text:gsub("[%p%c]", " ")
    text = text:gsub("%s+", " ")
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local OBJECTIVE_STOPWORDS = {
    ["a"]=true,["an"]=true,["the"]=true,["to"]=true,["of"]=true,["and"]=true,["or"]=true,
    ["kill"]=true,["slay"]=true,["slain"]=true,["defeat"]=true,["loot"]=true,["collect"]=true,["gather"]=true,
    ["use"]=true,["talk"]=true,["speak"]=true,["with"]=true,["from"]=true,["für"]=true,["der"]=true,["die"]=true,
    ["das"]=true,["den"]=true,["dem"]=true,["des"]=true,["ein"]=true,["eine"]=true,["einen"]=true,["einem"]=true,
    ["töte"]=true,["toete"]=true,["besiege"]=true,["sammle"]=true,["plündere"]=true,["pluendere"]=true,["sprich"]=true,["mit"]=true,
}

local function ObjectiveMatchScore(instruction, objectiveText)
    local a = NormalizeObjectiveMatchText(instruction)
    local b = NormalizeObjectiveMatchText(objectiveText)
    if not a or not b then return 0 end
    if a == b then return 100 end
    if #a >= 4 and b:find(a, 1, true) then return 80 end
    if #b >= 4 and a:find(b, 1, true) then return 80 end
    local words = {}
    for word in a:gmatch("%S+") do
        if #word >= 3 and not OBJECTIVE_STOPWORDS[word] then words[word] = true end
    end
    local score = 0
    for word in b:gmatch("%S+") do
        if words[word] then score = score + 1 end
    end
    return score
end

local function GetQuestObjectiveText(element)
    if not element then return nil end
    local questID = FindQuestID(element)
    if not (questID and C_QuestLog and type(C_QuestLog.GetQuestObjectives) == "function") then return nil end

    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not ok or type(objectives) ~= "table" or #objectives == 0 then return nil end

    -- Prefer an explicit objective index when RXPGuides exposes one.
    for _, key in ipairs({"obj", "objectiveIndex", "objectiveNum", "objective", "goalIndex"}) do
        local index = tonumber(element[key])
        if index and objectives[index] then
            local text = CleanRXPText(objectives[index].text)
            if text and text ~= "" then return text end
        end
    end

    -- Otherwise match the RXP instruction against Blizzard's objective text.
    -- This is important for quests with several simultaneous objectives: never
    -- show the first open counter if it belongs to a different mob/item.
    local model = Navigator.RXPData:Normalize(element)
    local instruction = GetTargetInstruction(element)
    local structuredName = model and model.targetName
    local bestText, bestScore
    local incomplete = {}
    for _, objective in ipairs(objectives) do
        local text = CleanRXPText(objective and objective.text)
        local finished = objective and (objective.finished == true or objective.isFinished == true)
        if text and not finished then
            incomplete[#incomplete + 1] = text
            local score = ObjectiveMatchScore(instruction, text)
            if structuredName then score = math.max(score, ObjectiveMatchScore(structuredName, text) + 2) end
            if not bestScore or score > bestScore then
                bestScore, bestText = score, text
            end
        end
    end
    if bestText and bestScore and bestScore > 0 then return bestText end
    if #incomplete == 1 then return incomplete[1] end

    -- With several unmatched objectives it is safer to show no extra line than
    -- a counter for the wrong mob or item. The RXP instruction remains visible.
    return nil
end

local function GetMajorZoneMapID(mapID)
    local current, last = mapID, mapID
    for _ = 1, 8 do
        if type(current) ~= "number" or not (C_Map and C_Map.GetMapInfo) then break end
        local info = C_Map.GetMapInfo(current)
        if not info then break end
        last = current
        if info.mapType == 3 then return current end
        local parent = info.parentMapID
        if not parent or parent == 0 or parent == current then break end
        current = parent
    end
    return last
end

local function GetZoneTransitionHint(element, playerMapID)
    if not element or not playerMapID or not (C_Map and C_Map.GetMapInfo) then return nil end
    local targetMapID = GetTargetMap(element)
    if not targetMapID then return nil end
    local pMajor, tMajor = GetMajorZoneMapID(playerMapID), GetMajorZoneMapID(targetMapID)
    if not pMajor or not tMajor or pMajor == tMajor then return nil end
    local info = C_Map.GetMapInfo(tMajor)
    return info and info.name or nil
end

local function GetElementDistance(a, b)
    if not a or not b then return nil end
    local ax, ay, ac = GetTargetWorld(a)
    local bx, by, bc = GetTargetWorld(b)
    if not ax or not ay or not bx or not by or (ac and bc and ac ~= bc) then return nil end
    return WorldDistance(ax, ay, bx, by)
end

local function GetNearestSpiritHealerElement()
    if not IsCorpseRunMode() or not (db and db.showSpiritHealer) then return nil end
    if not (C_DeathInfo and type(C_DeathInfo.GetGraveyardsForMap) == "function") then return nil end
    local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not playerMapID then return nil end
    local candidates = {playerMapID}
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)
    if info and info.parentMapID and info.parentMapID ~= 0 then candidates[#candidates+1] = info.parentMapID end
    for _, mapID in ipairs(candidates) do
        local ok, graves = pcall(C_DeathInfo.GetGraveyardsForMap, mapID)
        if ok and type(graves) == "table" then
            local best, bestDistance
            local px, py
            if C_Map and C_Map.GetPlayerMapPosition then
                local okPos, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
                if okPos and pos then px, py = GetXY(pos) end
            end
            for _, grave in ipairs(graves) do
                local pos = grave and (grave.position or grave.pos)
                local gx, gy = GetXY(pos)
                if gx and gy then
                    local d = px and py and ((gx-px)*(gx-px)+(gy-py)*(gy-py)) or 0
                    if not best or d < bestDistance then
                        bestDistance = d
                        best = {zone=mapID, x=gx, y=gy, arrow=true, textOnly=true, spiritHealer=true, text=grave.name or L("spiritHealerLabel")}
                    end
                end
            end
            if best then return best end
        end
    end
    return nil
end

local function UpdateMarkerMetadata(marker, element, ordinal, showStepLabel)
    if not marker then return end

    -- Keep the world map visually clean. Step/action information is exposed
    -- through mouseover tooltips on the active route/target instead of a
    -- permanently visible badge or text pill.
    if marker.rxpTypeIcon then marker.rxpTypeIcon:Hide() end
    if marker.rxpTypeBadge then marker.rxpTypeBadge:Hide() end
    if marker.rxpActionPill then marker.rxpActionPill:Hide() end

    -- Progress/objective counters and step numbers remain tooltip-only.
    if marker.rxpProgressLabel then
        marker.rxpProgressLabel:SetText("")
        marker.rxpProgressLabel:Hide()
    end
    if marker.rxpStepLabel then
        marker.rxpStepLabel:SetText("")
        marker.rxpStepLabel:Hide()
    end
end

local STEP_TYPE_NAMES = {
    accept = { enUS="Accept quest", deDE="Quest annehmen" },
    turnin = { enUS="Turn in quest", deDE="Quest abgeben" },
    kill = { enUS="Defeat enemies", deDE="Gegner besiegen" },
    loot = { enUS="Collect / Loot", deDE="Sammeln / Plündern" },
    talk = { enUS="Talk", deDE="Sprechen" },
    travel = { enUS="Travel", deDE="Reisen" },
}

local function GetStepTypeDisplayName(stepType)
    local names = STEP_TYPE_NAMES[stepType]
    if type(names) ~= "table" then return stepType end
    local locale = GetLocale and GetLocale() or "enUS"
    return names[locale] or names.enUS or stepType
end

local function AddTargetMetadataToTooltip(element)
    if not element or not GameTooltip then return end

    local model = Navigator.RXPData:Normalize(element)
    if db and db.showStepTypeIcons then
        local stepType = DetectStepType(element)
        local texture = stepType and STEP_ICONS[stepType]
        if stepType then
            local typeName = GetStepTypeDisplayName(stepType)
            local icon = texture and ("|T" .. texture .. ":14:14:0:0|t ") or ""
            GameTooltip:AddLine(icon .. L("tooltipType") .. ": " .. typeName, 0.90, 0.90, 0.90)
        end
    end

    if db and db.showQuestProgress then
        local objectiveText = GetQuestObjectiveText(element)
        if objectiveText and objectiveText ~= "" then
            local instruction = GetTargetInstruction(element)
            -- Avoid printing the same objective twice when RXP already provides
            -- exactly the same mob/item + counter as its instruction line.
            if NormalizeObjectiveMatchText(objectiveText) ~= NormalizeObjectiveMatchText(instruction)
               or objectiveText ~= instruction then
                GameTooltip:AddLine(L("tooltipObjective") .. ": " .. objectiveText, 0.45, 0.85, 1.00, true)
            end
        end
    end
end

local function SetCurrentMarkerHighlight(marker, enabled, corpseMode)
    if not marker or not marker.rxpHighlight then return end
    if not enabled then marker.rxpHighlight:Hide(); return end
    local now = GetTime and GetTime() or 0
    local alpha = 0.28 + 0.32 * ((math.sin(now * 4.2) + 1) / 2)
    if corpseMode then marker.rxpHighlight:SetVertexColor(1.0, 0.12, 0.08, alpha)
    else marker.rxpHighlight:SetVertexColor(1.0, 0.82, 0.20, alpha) end
    marker.rxpHighlight:Show()
end

local function ApplyCorpseProximityToIcons(arrows, distance)
    if not arrows or type(distance) ~= "number" then return end
    local proximity = math.max(0, math.min(1, (90 - distance) / 90))
    if proximity <= 0 then return end
    local baseAlpha = math.max(0.10, math.min(1.0, tonumber(db and db.corpseSkullAlpha) or 0.30))
    local baseSize = math.max(8, math.min(36, tonumber(db and db.corpseRouteSkullSize) or 14))
    for _, a in ipairs(arrows) do
        a:SetVertexColor(1.0, 0.82, 0.82, math.min(1, baseAlpha + proximity * 0.45))
        a:SetSize(baseSize * (1 + proximity * 0.20), baseSize * (1 + proximity * 0.20))
    end
end

local function GetTargetLabel(element, ordinal)
    if element and element.corpseNav then return L("corpse") end
    if ordinal == 1 then return L("current") end
    local label = L("next") .. " +" .. tostring(ordinal - 1)
    local si = element and element.rxpNavigatorStepIndex
    if si then label = label .. "  (Step " .. tostring(si) .. ")" end
    return label
end

local function BuildClusterFutureLabel(cluster)
    if not cluster or type(cluster.members) ~= "table" then return nil end
    local labels = {}
    for _, member in ipairs(cluster.members) do
        local ordinal = member.ordinal or 1
        if ordinal > 1 then labels[#labels + 1] = "+" .. tostring(ordinal - 1) end
    end
    if #labels == 0 then return nil end
    return table.concat(labels, "/")
end

local function BuildWorldTargetClusters(targets, displayMapID)
    local clusters = {}
    local threshold = 0.012
    for ordinal, element in ipairs(targets or {}) do
        local mapID, tx, ty = GetTargetMap(element)
        local dx, dy
        if mapID then dx, dy = PositionInDisplayedMap(mapID, tx, ty, displayMapID, true) end
        if dx and dy then
            local found
            for _, cluster in ipairs(clusters) do
                local ddx, ddy = dx - cluster.x, dy - cluster.y
                if math.sqrt(ddx * ddx + ddy * ddy) <= threshold then
                    found = cluster
                    break
                end
            end
            local member = { element = element, ordinal = ordinal, x = dx, y = dy }
            if found then
                found.members[#found.members + 1] = member
                -- Keep the first target's physical position so clustering does not
                -- make markers drift as more near-identical steps are added.
            else
                clusters[#clusters + 1] = { x = dx, y = dy, members = { member } }
            end
        end
    end
    return clusters
end

local function SetRouteTexture(tex, x1, y1, x2, y2, thickness)
    if not tex then return end
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then tex:Hide() return end
    tex:ClearAllPoints()
    local parent = tex:GetParent() or overlay
    tex:SetPoint("CENTER", parent, "CENTER", (x1 + x2) / 2, (y1 + y2) / 2)
    tex:SetSize(len + thickness, thickness)
    tex:SetRotation(math.atan2(dy, dx))
    tex:Show()
end

local function CreateArrowTexture(parent, size)
    local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_ArrowWhite.tga")
    t:SetSize(size, size)
    t:Hide()
    return t
end

local function UpdateArrowSet(arrows, parent, x1, y1, x2, y2, now, minLength, keepUpright, speedOverride)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < (minLength or 32) then
        for _, a in ipairs(arrows) do a:Hide() end
        return
    end
    local angle = math.atan2(dy, dx)
    local speed
    if keepUpright then speed = (db and db.corpseAnimationSpeed) or 0.5
    else speed = tonumber(speedOverride) or (db and db.animationSpeed) or 0.5 end
    local phase = ((now or 0) * 0.42 * speed) % 1
    local count = #arrows
    -- Smart density: short segments get a single directional cue, medium
    -- segments two, long segments three. Never flood the map with arrows.
    local desired = (len < 72) and 1 or ((len < 145) and 2 or 3)
    local activeCount = math.min(count, desired)
    for i, a in ipairs(arrows) do
        if i > activeCount then
            a:Hide()
        else
            local t = (phase + (i - 1) / activeCount) % 1
            t = 0.20 + t * 0.60
            a:ClearAllPoints()
            a:SetPoint("CENTER", parent, "CENTER", x1 + dx * t, y1 + dy * t)
            a:SetRotation(keepUpright and 0 or angle)
            a:Show()
        end
    end
end

local function UpdateArrowSetAlongPath(arrows, parent, points, now, minLength, keepUpright, speedOverride)
    if type(points) ~= "table" or #points < 2 then
        for _, a in ipairs(arrows) do a:Hide() end
        return
    end

    local lengths, total = {}, 0
    for i = 2, #points do
        local a, b = points[i - 1], points[i]
        local dx, dy = b.x - a.x, b.y - a.y
        local len = math.sqrt(dx * dx + dy * dy)
        lengths[i - 1] = len
        total = total + len
    end
    if total < (minLength or 32) then
        for _, a in ipairs(arrows) do a:Hide() end
        return
    end

    local speed
    if keepUpright then speed = (db and db.corpseAnimationSpeed) or 0.5
    else speed = tonumber(speedOverride) or (db and db.animationSpeed) or 0.5 end
    local phase = ((now or 0) * 0.42 * speed) % 1
    local desired = (total < 72) and 1 or ((total < 145) and 2 or 3)
    local activeCount = math.min(#arrows, desired)

    local function Sample(distance)
        local remaining = math.max(0, math.min(total, distance))
        for i = 1, #points - 1 do
            local segLen = lengths[i] or 0
            if segLen > 0.001 and remaining <= segLen then
                local a, b = points[i], points[i + 1]
                local t = remaining / segLen
                local x = a.x + (b.x - a.x) * t
                local y = a.y + (b.y - a.y) * t
                local angle = math.atan2(b.y - a.y, b.x - a.x)
                return x, y, angle
            end
            remaining = remaining - segLen
        end
        local a, b = points[#points - 1], points[#points]
        return b.x, b.y, math.atan2(b.y - a.y, b.x - a.x)
    end

    for i, arrow in ipairs(arrows) do
        if i > activeCount then
            arrow:Hide()
        else
            local t = (phase + (i - 1) / activeCount) % 1
            t = 0.20 + t * 0.60
            local x, y, angle = Sample(total * t)
            arrow:ClearAllPoints()
            arrow:SetPoint("CENTER", parent, "CENTER", x, y)
            arrow:SetRotation(keepUpright and 0 or angle)
            arrow:Show()
        end
    end
end

local function SetNativeWorldLine(line, parent, x1, y1, x2, y2, thickness)
    if not line then return end
    line:ClearAllPoints()
    line:SetStartPoint("CENTER", parent, x1, y1)
    line:SetEndPoint("CENTER", parent, x2, y2)
    line:SetThickness(thickness)
    line:Show()
end

local function HideNativeChevrons(arrows)
    for _, c in ipairs(arrows) do
        if c.a then c.a:Hide() end
        if c.b then c.b:Hide() end
    end
end

local function UpdateNativeChevrons(arrows, parent, x1, y1, x2, y2, now, minLength, scale)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < (minLength or 55) then HideNativeChevrons(arrows) return end

    local ux, uy = dx / len, dy / len
    local px, py = -uy, ux
    local speed = (db and db.animationSpeed) or 1
    local phase = ((now or 0) * 0.26 * speed) % 1
    local count = #arrows
    local size = 5.4 * (scale or 1)
    local halfWing = 2.8 * (scale or 1)

    for i, c in ipairs(arrows) do
        local t = (phase + (i - 1) / count) % 1
        t = 0.15 + t * 0.70
        local cx, cy = x1 + dx * t, y1 + dy * t
        local tipX, tipY = cx + ux * size * 0.45, cy + uy * size * 0.45
        local backX, backY = cx - ux * size * 0.45, cy - uy * size * 0.45
        local lX, lY = backX + px * halfWing, backY + py * halfWing
        local rX, rY = backX - px * halfWing, backY - py * halfWing
        c.a:ClearAllPoints(); c.b:ClearAllPoints()
        c.a:SetStartPoint("CENTER", parent, lX, lY)
        c.a:SetEndPoint("CENTER", parent, tipX, tipY)
        c.b:SetStartPoint("CENTER", parent, rX, rY)
        c.b:SetEndPoint("CENTER", parent, tipX, tipY)
        c.a:Show(); c.b:Show()
    end
end

local function BuildTargetMarker(parent, name, size)
    local f = CreateFrame("Button", name, parent)
    f:SetSize(size, size)
    f:EnableMouse(false)

    local ring = f:CreateTexture(nil, "OVERLAY", nil, 7)
    ring:SetAllPoints()
    ring:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")

    local center = f:CreateTexture(nil, "OVERLAY", nil, 6)
    center:SetAllPoints()
    center:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetCenter.tga")

    local highlight = f:CreateTexture(nil, "OVERLAY", nil, 5)
    highlight:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")
    highlight:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
    highlight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
    highlight:Hide()

    local typeBadge = f:CreateTexture(nil, "OVERLAY", nil, 6)
    typeBadge:SetSize(16, 16)
    typeBadge:SetPoint("TOPRIGHT", f, "TOPRIGHT", 7, 7)
    typeBadge:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")
    typeBadge:SetVertexColor(0.95, 0.72, 0.16, 0.98)
    typeBadge:Hide()

    local typeIcon = f:CreateTexture(nil, "OVERLAY", nil, 7)
    typeIcon:SetSize(11, 11)
    typeIcon:SetPoint("CENTER", typeBadge, "CENTER", 0, 0)
    typeIcon:Hide()

    local actionPill = CreateFrame("Frame", nil, f)
    actionPill:SetSize(58, 18)
    actionPill:SetPoint("LEFT", f, "RIGHT", 10, 0)
    actionPill:SetFrameLevel(f:GetFrameLevel() + 3)
    actionPill:EnableMouse(false)
    local actionBG = actionPill:CreateTexture(nil, "BACKGROUND")
    actionBG:SetAllPoints()
    actionBG:SetColorTexture(0.02, 0.025, 0.035, 0.90)
    local actionAccent = actionPill:CreateTexture(nil, "BORDER")
    actionAccent:SetPoint("LEFT", 0, 0)
    actionAccent:SetSize(3, 18)
    actionAccent:SetColorTexture(0.95, 0.72, 0.16, 0.98)
    local actionText = actionPill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    actionText:SetPoint("CENTER", 2, 0)
    actionText:SetTextColor(1.0, 0.84, 0.34, 1)
    if actionText.SetShadowOffset then actionText:SetShadowOffset(1, -1) end
    actionPill:Hide()

    local progress = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progress:SetPoint("TOP", f, "BOTTOM", 0, -1)
    progress:SetTextColor(1, 1, 1, 1)
    if progress.SetShadowOffset then progress:SetShadowOffset(1, -1) end
    progress:Hide()

    local stepLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stepLabel:SetPoint("LEFT", f, "RIGHT", 3, -9)
    stepLabel:SetTextColor(0.85, 0.85, 0.85, 1)
    if stepLabel.SetShadowOffset then stepLabel:SetShadowOffset(1, -1) end
    stepLabel:Hide()

    f.ring = ring
    f.center = center
    f.rxpHighlight = highlight
    f.rxpTypeBadge = typeBadge
    f.rxpTypeIcon = typeIcon
    f.rxpActionPill = actionPill
    f.rxpActionText = actionText
    f.rxpProgressLabel = progress
    f.rxpStepLabel = stepLabel
    f:Hide()
    return f
end

local function ResizeTargetMarker(marker, scale, baseSize)
    if not marker or not db then return end
    local size = (tonumber(baseSize) or tonumber(db.targetSize) or 14) * (scale or 1)
    marker:SetSize(size, size)
end

local function ApplyTheme()
    local theme = GetTheme()
    local lr, lg, lb = theme.line[1], theme.line[2], theme.line[3]
    local ar, ag, ab = 1, 1, 1
    local cr, cg, cb = theme.center[1], theme.center[2], theme.center[3]
    local orr, org, orb = GetOutlineColor(theme)
    if IsCorpseRunMode() then
        lr, lg, lb = CORPSE_LINE[1], CORPSE_LINE[2], CORPSE_LINE[3]
        cr, cg, cb = CORPSE_LINE_BRIGHT[1], CORPSE_LINE_BRIGHT[2], CORPSE_LINE_BRIGHT[3]
        orr, org, orb = CORPSE_OUTLINE[1], CORPSE_OUTLINE[2], CORPSE_OUTLINE[3]
    end

    if minimapRouteOutlineTexture then minimapRouteOutlineTexture:SetVertexColor(orr, org, orb, 0.96) end
    if minimapRouteTexture then minimapRouteTexture:SetVertexColor(lr, lg, lb, 1) end
    if worldMainRouteOutlineTexture then worldMainRouteOutlineTexture:SetVertexColor(orr, org, orb, 0.96) end
    if worldMainRouteTexture then worldMainRouteTexture:SetVertexColor(lr, lg, lb, 0.98) end
    for _, a in ipairs(minimapArrows) do a:SetVertexColor(ar, ag, ab, 1) end
    if minimapEdgeArrow then minimapEdgeArrow:SetVertexColor(lr, lg, lb, 1) end
    local hr = (db and tonumber(db.hudColorR)) or 0.08
    local hg = (db and tonumber(db.hudColorG)) or 0.74
    local hb = (db and tonumber(db.hudColorB)) or 1.00
    if hudArrowTexture then
        if IsCorpseRunMode() then hudArrowTexture:SetVertexColor(CORPSE_LINE_BRIGHT[1], CORPSE_LINE_BRIGHT[2], CORPSE_LINE_BRIGHT[3], 1)
        else hudArrowTexture:SetVertexColor(hr, hg, hb, 1) end
    end
    if targetDot and targetDot.center then targetDot.center:SetVertexColor(cr, cg, cb, 1) end
    if worldTargetPin and worldTargetPin.center then worldTargetPin.center:SetVertexColor(cr, cg, cb, 1) end
    for i, pin in ipairs(worldFuturePins) do
        if pin.center then pin.center:SetVertexColor(cr, cg, cb, math.max(0.42, 0.78 - (i - 1) * 0.12)) end
    end

    for _, line in ipairs(worldRouteLines) do
        if line.SetColorTexture then line:SetColorTexture(lr, lg, lb, 0.98) end
    end
    local gr, gg, gb = theme.accent[1], theme.accent[2], theme.accent[3]
    for _, line in ipairs(worldRouteShadows) do
        if line.SetColorTexture then line:SetColorTexture(orr, org, orb, 0.96) end
    end
    for _, c in ipairs(worldArrows) do
        if c.a and c.a.SetColorTexture then c.a:SetColorTexture(1, 1, 1, 0.98) end
        if c.b and c.b.SetColorTexture then c.b:SetColorTexture(1, 1, 1, 0.98) end
    end
    for _, a in ipairs(worldArrowTextures) do
        if a.SetVertexColor then a:SetVertexColor(1, 1, 1, 1) end
    end
    for _, set in ipairs(worldFutureArrows) do
        for _, a in ipairs(set) do
            if a.SetVertexColor then a:SetVertexColor(1, 1, 1, 1) end
        end
    end

    if worldTaskFrame and worldTaskFrame.accent then
        worldTaskFrame.accent:SetColorTexture(lr, lg, lb, 1)
    end
end

local function ConfigureRouteIconsForMode(arrows, corpseMode, size)
    for _, a in ipairs(arrows or {}) do
        if corpseMode then
            a:SetTexture(CORPSE_SKULL_TEXTURE)
            local alpha = math.max(0.10, math.min(1.0, tonumber(db and db.corpseSkullAlpha) or 0.30))
            local skullSize = math.max(8, math.min(36, tonumber(db and db.corpseRouteSkullSize) or ((size or 12) + 2)))
            a:SetVertexColor(1.0, 0.82, 0.82, alpha)
            a:SetSize(skullSize, skullSize)
        else
            a:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_ArrowWhite.tga")
            a:SetVertexColor(1, 1, 1, 1)
            a:SetSize(size or 12, size or 12)
        end
    end
end

local function BuildMinimapOverlay()
    overlay = CreateFrame("Frame", "RXPNavigatorOverlay", Minimap)
    overlay:SetAllPoints(Minimap)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
    overlay:EnableMouse(false)

    minimapRouteOutlineTexture = overlay:CreateTexture(nil, "OVERLAY", nil, 5)
    minimapRouteOutlineTexture:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_LineFade.tga")
    minimapRouteOutlineTexture:SetTexCoord(0, 1, 0, 1)
    minimapRouteOutlineTexture:Hide()

    minimapRouteTexture = overlay:CreateTexture(nil, "OVERLAY", nil, 6)
    minimapRouteTexture:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_LineFade.tga")
    minimapRouteTexture:SetTexCoord(0, 1, 0, 1)
    minimapRouteTexture:Hide()

    for i = 1, 3 do minimapArrows[i] = CreateArrowTexture(overlay, 12) end

    targetDot = BuildTargetMarker(overlay, "RXPNavigatorMinimapTarget", defaults.targetSize)
    targetDot:SetFrameLevel(overlay:GetFrameLevel() + 2)

    minimapEdgeArrow = CreateArrowTexture(overlay, 16)
    minimapEdgeDistanceText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minimapEdgeDistanceText:SetTextColor(1, 1, 1, 1)
    minimapEdgeDistanceText:SetShadowOffset(1, -1)
    minimapEdgeDistanceText:Hide()

    distanceText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    distanceText:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 8)
    distanceText:SetTextColor(1, 1, 1, 1)
    distanceText:SetShadowOffset(1, -1)
    distanceText:Hide()

    ApplyTheme()
end

local function HideMinimapRoute()
    if minimapRouteOutlineTexture then minimapRouteOutlineTexture:Hide() end
    if minimapRouteTexture then minimapRouteTexture:Hide() end
    for _, a in ipairs(minimapArrows) do a:Hide() end
    if targetDot then targetDot:Hide() end
    if minimapEdgeArrow then minimapEdgeArrow:Hide() end
    if minimapEdgeDistanceText then minimapEdgeDistanceText:Hide() end
    if distanceText then distanceText:Hide() end
    if Navigator.MinimapFuture and Navigator.MinimapFuture.HideAll then Navigator.MinimapFuture:HideAll() end
end

local function GetWorldMapCanvas()
    if not WorldMapFrame then return nil end
    local sc = WorldMapFrame.ScrollContainer
    if sc then
        if sc.Child then return sc.Child end
        if type(sc.GetScrollChild) == "function" then
            local child = sc:GetScrollChild()
            if child then return child end
        end
    end
    return WorldMapFrame
end

local function AddBorder(frame, color)
    local r, g, b, a = color[1], color[2], color[3], color[4] or 1
    local top = frame:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(1); top:SetColorTexture(r,g,b,a)
    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", 1, 1); bottom:SetPoint("BOTTOMRIGHT", -1, 1); bottom:SetHeight(1); bottom:SetColorTexture(r,g,b,a)
    local left = frame:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", 1, -1); left:SetPoint("BOTTOMLEFT", 1, 1); left:SetWidth(1); left:SetColorTexture(r,g,b,a)
    local right = frame:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", -1, -1); right:SetPoint("BOTTOMRIGHT", -1, 1); right:SetWidth(1); right:SetColorTexture(r,g,b,a)
end

local function BuildWorldTaskFrame(parent)
    local f = CreateFrame("Frame", "RXPNavigatorWorldTaskFrame", parent)
    f:SetSize(250, 54)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel((parent:GetFrameLevel() or 1) + 35)
    f:EnableMouse(false)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.025, 0.025, 0.03, 0.91)
    AddBorder(f, {0.70, 0.55, 0.18, 0.95})

    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 4, -4)
    accent:SetPoint("BOTTOMLEFT", 4, 4)
    accent:SetWidth(3)
    f.accent = accent

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 13, -8)
    title:SetPoint("TOPRIGHT", -10, -8)
    title:SetJustifyH("LEFT")
    title:SetTextColor(0.95, 0.76, 0.22, 1)
    f.title = title

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 13, -24)
    text:SetWidth(225)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetTextColor(0.96, 0.96, 0.96, 1)
    text:SetWordWrap(true)
    f.text = text

    f:Hide()
    return f
end

local function BindWorldHitboxTooltip(button)
    button:EnableMouse(true)
    if button.SetHitRectInsets then button:SetHitRectInsets(-5, -5, -5, -5) end
    button:SetScript("OnEnter", function(self)
        if not db or not db.showTaskTooltip or not GameTooltip then return end
        local members = self.rxpClusterMembers
        if Navigator.API and Navigator.API.ShowClusterTooltip and Navigator.TooltipEngine then
            Navigator.API:ShowClusterTooltip(self, members, self.rxpElement, self.rxpOrdinal or 1)
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()

        if type(members) == "table" and #members > 0 then
            local hasCurrent, futureCount = false, 0
            for _, member in ipairs(members) do
                if (member.ordinal or 1) == 1 then hasCurrent = true else futureCount = futureCount + 1 end
            end
            if #members > 1 then
                GameTooltip:AddLine(hasCurrent and L("alsoHere") or L("groupedHere"), 0.95, 0.76, 0.22)
                GameTooltip:AddLine(" ", 1, 1, 1)
            end
            for i, member in ipairs(members) do
                local element = member.element
                local ordinal = member.ordinal or 1
                if element then
                    local stepIndex = element.rxpNavigatorStepIndex
                    local label = (ordinal == 1) and L("current") or ("+" .. tostring(ordinal - 1))
                    if stepIndex then label = label .. "  •  " .. L("step") .. " " .. tostring(stepIndex) end
                    GameTooltip:AddLine(label, ordinal == 1 and 0.30 or 0.95, ordinal == 1 and 0.85 or 0.76, ordinal == 1 and 1.00 or 0.22)
                    local instruction = GetTargetInstruction(element)
                    if instruction and instruction ~= "" then GameTooltip:AddLine(instruction, 1, 1, 1, true) end
                    AddTargetMetadataToTooltip(element)
                    if i < #members then GameTooltip:AddLine(" ", 1, 1, 1) end
                end
            end
        else
            local element = self.rxpElement
            if not element then return end
            local ordinal = self.rxpOrdinal or 1
            GameTooltip:AddLine(GetTargetLabel(element, ordinal) .. " — " .. GetTargetStepLabel(element), 0.95, 0.76, 0.22)
            local instruction = GetTargetInstruction(element)
            if instruction and instruction ~= "" then GameTooltip:AddLine(instruction, 1, 1, 1, true) end
            AddTargetMetadataToTooltip(element)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local function EnsureWorldMapOverlay()
    local canvas = GetWorldMapCanvas()
    if not canvas then return false end

    if worldCanvas ~= canvas then
        if worldMapOverlay then worldMapOverlay:Hide() end
        for _, hitbox in ipairs(worldHitboxes) do hitbox:Hide() end

        worldCanvas = canvas
        worldMapOverlay = CreateFrame("Frame", "RXPNavigatorWorldMapOverlay", canvas)
        worldMapOverlay:SetAllPoints(canvas)
        worldMapOverlay:SetFrameStrata("HIGH")
        worldMapOverlay:SetFrameLevel((canvas:GetFrameLevel() or 1) + 20)
        worldMapOverlay:EnableMouse(false)

        worldMainRouteOutlineTexture = worldMapOverlay:CreateTexture(nil, "OVERLAY", nil, 5)
        worldMainRouteOutlineTexture:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_LineFade.tga")
        worldMainRouteOutlineTexture:SetTexCoord(0, 1, 0, 1)
        worldMainRouteOutlineTexture:Hide()

        worldMainRouteTexture = worldMapOverlay:CreateTexture(nil, "OVERLAY", nil, 6)
        worldMainRouteTexture:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_LineFade.tga")
        worldMainRouteTexture:SetTexCoord(0, 1, 0, 1)
        worldMainRouteTexture:Hide()

        -- Dedicated arrow layer above route lines so chevrons can never be
        -- covered by lines created later on the same map canvas.
        worldArrowLayer = CreateFrame("Frame", "RXPNavigatorWorldArrowLayer", worldMapOverlay)
        worldArrowLayer:SetAllPoints(worldMapOverlay)
        worldArrowLayer:SetFrameStrata("HIGH")
        worldArrowLayer:SetFrameLevel((worldMapOverlay:GetFrameLevel() or 1) + 35)
        worldArrowLayer:EnableMouse(false)

        -- Visual markers stay on the non-interactive overlay.
        worldTargetPin = BuildTargetMarker(worldMapOverlay, "RXPNavigatorWorldTargetPin", defaults.targetSize)
        worldTargetPin:SetFrameLevel(worldMapOverlay:GetFrameLevel() + 12)
        worldTargetPin:EnableMouse(false)

        worldFuturePins = {}
        worldHitboxes = {}
        worldRouteDistanceLabels = {}
        worldSpiritHealerIcon = worldMapOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
        worldSpiritHealerIcon:SetTexture("Interface\\Icons\\Spell_Holy_Resurrection")
        worldSpiritHealerIcon:SetSize(18, 18)
        worldSpiritHealerIcon:SetVertexColor(0.88, 0.88, 1.0, 0.95)
        worldSpiritHealerIcon:Hide()
        worldTaskFrame = BuildWorldTaskFrame(worldMapOverlay)
        worldTaskFrame:Hide()

        -- IMPORTANT: use the exact native-Line setup that was working in 0.8.1.
        worldRouteLines = {}
        worldRouteShadows = {}
        worldNativeLines = {}
        worldNativeShadows = {}
        worldArrows = {}
        for i = 1, 3 do
            local c = {}
            c.a = worldMapOverlay:CreateLine(nil, "OVERLAY", nil, 7)
            c.b = worldMapOverlay:CreateLine(nil, "OVERLAY", nil, 7)
            c.a:SetThickness(1.8)
            c.b:SetThickness(1.8)
            c.a:Hide()
            c.b:Hide()
            worldArrows[i] = c
        end
        -- Texture arrows are used for the animated world-map flow. They are
        -- more reliable on the Forever map canvas than animated Line chevrons.
        worldArrowTextures = {}
        for i = 1, 3 do
            worldArrowTextures[i] = CreateArrowTexture(worldArrowLayer or worldMapOverlay, 14)
        end
        ApplyTheme()
    end
    return worldMapOverlay ~= nil
end

local function GetWorldTargetPin(index)
    if index == 1 then return worldTargetPin end
    local futureIndex = index - 1
    local pin = worldFuturePins[futureIndex]
    if not pin then
        pin = BuildTargetMarker(worldMapOverlay, "RXPNavigatorWorldFuturePin" .. tostring(futureIndex), defaults.worldTargetSize or defaults.targetSize)
        pin:SetFrameLevel(worldMapOverlay:GetFrameLevel() + 12)
        pin:EnableMouse(false)
        local label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", pin, "RIGHT", 3, 0)
        label:SetJustifyH("LEFT")
        label:SetTextColor(1.0, 0.82, 0.18, 1.0)
        if label.SetShadowOffset then label:SetShadowOffset(1, -1) end
        if label.SetShadowColor then label:SetShadowColor(0, 0, 0, 1) end
        pin.rxpFutureLabel = label
        worldFuturePins[futureIndex] = pin
    end
    return pin
end

local function GetWorldHitbox(index)
    local hitbox = worldHitboxes[index]
    if not hitbox and worldCanvas then
        hitbox = CreateFrame("Button", "RXPNavigatorWorldHitbox" .. tostring(index), worldMapOverlay)
        hitbox:SetSize(28, 28)
        hitbox:SetFrameStrata("TOOLTIP")
        hitbox:SetFrameLevel((worldMapOverlay:GetFrameLevel() or 1) + 80)
        BindWorldHitboxTooltip(hitbox)
        hitbox:Hide()
        worldHitboxes[index] = hitbox
    end
    return hitbox
end

local function GetWorldRouteSegment(index)
    local line = worldRouteLines[index]
    local shadow = worldRouteShadows[index]
    if not line then
        shadow = worldMapOverlay:CreateLine(nil, "OVERLAY", nil, 5)
        shadow:SetColorTexture(0.93, 0.72, 0.16, 0.96)
        shadow:Hide()
        line = worldMapOverlay:CreateLine(nil, "OVERLAY", nil, 6)
        line:Hide()
        worldRouteShadows[index] = shadow
        worldRouteLines[index] = line
        ApplyTheme()
    end
    return line, shadow
end

local function GetWorldRouteDistanceLabel(index)
    local label = worldRouteDistanceLabels[index]
    if not label and worldMapOverlay then
        label = worldMapOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetTextColor(0.92, 0.92, 0.92, 0.92)
        if label.SetShadowOffset then label:SetShadowOffset(1, -1) end
        label:Hide()
        worldRouteDistanceLabels[index] = label
    end
    return label
end

-- Each future route segment gets its own animated icon set.  Keeping these
-- separate from the main route arrows prevents future segments from stealing
-- or hiding the animation of the active player -> target segment.
local function GetWorldFutureArrowSet(index)
    local set = worldFutureArrows[index]
    if not set then
        set = {}
        for i = 1, 3 do
            set[i] = CreateArrowTexture(worldArrowLayer or worldMapOverlay, 14)
        end
        worldFutureArrows[index] = set
        ApplyTheme()
    end
    return set
end

local function HideWorldFutureArrowSets(fromIndex)
    fromIndex = fromIndex or 1
    for i = fromIndex, #worldFutureArrows do
        local set = worldFutureArrows[i]
        if set then
            for _, arrow in ipairs(set) do arrow:Hide() end
        end
    end
end

local function HideWorldRoute()
    for _, line in ipairs(worldRouteLines) do line:Hide() end
    for _, line in ipairs(worldRouteShadows) do line:Hide() end
    for _, label in ipairs(worldRouteDistanceLabels) do label:Hide() end
    if worldSpiritHealerIcon then worldSpiritHealerIcon:Hide() end
    if worldMainRouteOutlineTexture then worldMainRouteOutlineTexture:Hide() end
    if worldMainRouteTexture then worldMainRouteTexture:Hide() end
    if worldTargetPin then worldTargetPin:Hide() end
    for _, pin in ipairs(worldFuturePins) do pin:Hide() end
    for _, hitbox in ipairs(worldHitboxes) do hitbox:Hide() end
    if worldTaskFrame then worldTaskFrame:Hide() end
    HideNativeChevrons(worldArrows)
    for _, a in ipairs(worldArrowTextures) do a:Hide() end
    HideWorldFutureArrowSets(1)
    if Navigator.MapOverlays and Navigator.MapOverlays.HideAll then Navigator.MapOverlays:HideAll() end
    if Navigator.RouteTooltip and Navigator.RouteTooltip.HideAll then Navigator.RouteTooltip:HideAll() end
end

PositionInDisplayedMap = function(sourceMapID, x, y, displayMapID, allowOutside)
    if sourceMapID == displayMapID then return x, y end
    if not (C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
    local continentID, worldPos = C_Map.GetWorldPosFromMapPos(sourceMapID, { x = x, y = y })
    if not continentID or not worldPos then return nil end

    -- Normal Blizzard conversion first.
    if C_Map.GetMapPosFromWorldPos then
        local _, mapPos = C_Map.GetMapPosFromWorldPos(continentID, worldPos, displayMapID)
        if mapPos then
            local mx, my = GetXY(mapPos)
            if mx and my and (allowOutside or (mx >= 0 and mx <= 1 and my >= 0 and my <= 1)) then
                return mx, my
            end
        end
    end

    -- Some city/sub-zone maps (e.g. Thunder Bluff) return nil for a target
    -- outside the displayed map. Build an affine basis from the visible map
    -- corners and project the world position ourselves.
    local c0, p0 = C_Map.GetWorldPosFromMapPos(displayMapID, { x = 0, y = 0 })
    local cx, px = C_Map.GetWorldPosFromMapPos(displayMapID, { x = 1, y = 0 })
    local cy, py = C_Map.GetWorldPosFromMapPos(displayMapID, { x = 0, y = 1 })
    if not c0 or c0 ~= continentID or cx ~= c0 or cy ~= c0 or not p0 or not px or not py then return nil end
    local x0, y0 = GetXY(p0); local xx, yx = GetXY(px); local xy, yy = GetXY(py)
    local wx, wy = GetXY(worldPos)
    if not x0 or not xx or not xy or not wx then return nil end
    local ax, ay = xx - x0, yx - y0
    local bx, by = xy - x0, yy - y0
    local vx, vy = wx - x0, wy - y0
    local det = ax * by - ay * bx
    if math.abs(det) < 1e-12 then return nil end
    local mx = (vx * by - vy * bx) / det
    local my = (ax * vy - ay * vx) / det
    if not allowOutside and (mx < 0 or mx > 1 or my < 0 or my > 1) then return nil end
    return mx, my
end

local function ClampTargetToMapEdge(px, py, tx, ty, inset)
    inset = inset or 0.025
    if tx >= inset and tx <= 1 - inset and ty >= inset and ty <= 1 - inset then
        return tx, ty, false
    end
    local dx, dy = tx - px, ty - py
    if math.abs(dx) < 1e-9 and math.abs(dy) < 1e-9 then return px, py, false end
    local t = 1
    if dx > 0 then t = math.min(t, (1 - inset - px) / dx) elseif dx < 0 then t = math.min(t, (inset - px) / dx) end
    if dy > 0 then t = math.min(t, (1 - inset - py) / dy) elseif dy < 0 then t = math.min(t, (inset - py) / dy) end
    t = math.max(0, math.min(1, t))
    return px + dx * t, py + dy * t, true
end

local function GetPlayerPositionInDisplayedMap(displayMapID, allowOutside)
    local x, y = GetPlayerPositionForMap(displayMapID)
    if x then return x, y, false end
    local playerMapID, px, py = ResolvePlayerMapAndPosition(displayMapID)
    if not playerMapID then return nil end
    if playerMapID == displayMapID then return px, py, false end
    local mx, my = PositionInDisplayedMap(playerMapID, px, py, displayMapID, allowOutside)
    if not mx or not my then return nil end
    return mx, my, (mx < 0 or mx > 1 or my < 0 or my > 1)
end

local function UpdateMinimapRoute()
    if not db or not db.enabled or not db.showMinimap then HideMinimapRoute() return end
    local rawElement = GetCurrentNavigationElement()
    if not rawElement then HideMinimapRoute() return end

    -- During cross-continent travel the immediate transport departure point
    -- is the real local navigation target. Keep the minimap route visible and
    -- route to that point instead of hiding all navigation while continents differ.
    local travelInfo = Navigator.TravelMode and Navigator.TravelMode:GetInfo(rawElement)
    local smartTravelPlan = travelInfo and Navigator.TravelPlanner and Navigator.TravelPlanner.GetPlan and Navigator.TravelPlanner:GetPlan(rawElement) or nil
    local travelApproach = smartTravelPlan and smartTravelPlan.approachElement or nil

    local routePlan = (not travelApproach) and Navigator.RouteResolver and Navigator.RouteResolver:GetCurrentPlan() or nil
    local element = travelApproach or (routePlan and routePlan.nextPoint) or rawElement
    local targetMapID, tx, ty = GetTargetMap(element)
    if not targetMapID then HideMinimapRoute() return end

    local playerMapID, px, py = ResolvePlayerMapAndPosition(targetMapID)
    if not playerMapID or not px then HideMinimapRoute() return end

    local dx, dy
    local pwx, pwy, pcontinent
    local twx, twy, tcontinent

    -- First project the RXP target into the player's CURRENT Blizzard map.
    -- This is the most reliable path both inside a zone and across city/submap
    -- transitions such as The Barrens <-> Crossroads or Mulgore <-> Thunder Bluff.
    local localTX, localTY = PositionInDisplayedMap(targetMapID, tx, ty, playerMapID)
    if localTX and localTY then
        dx, dy = localTX - px, localTY - py
    end

    -- If the target cannot be projected directly, derive a vector through
    -- Blizzard world coordinates. Never use RXPGuides' raw wx/wy as the first
    -- choice because their convention can differ from C_Map on Forever.
    if not dx then
        twx, twy, tcontinent = GetTargetWorld(element)
        if twx and twy then
            dx, dy, pwx, pwy, pcontinent = GetWorldVectorInPlayerMap(playerMapID, px, py, twx, twy)
            if pcontinent and tcontinent and pcontinent ~= tcontinent then dx, dy = nil, nil end
        end
    end
    if not dx or not dy then HideMinimapRoute() return end
    if math.abs(dx) < 0.000001 and math.abs(dy) < 0.000001 then HideMinimapRoute() return end

    local bearing = math.atan2(-dx, -dy)
    if bearing < 0 then bearing = bearing + PI2 end
    local relativeBearing = bearing
    if IsMinimapRotating() and GetPlayerFacing then
        local facing = GetPlayerFacing()
        if type(facing) == "number" then relativeBearing = NormalizeAngle(bearing - facing) end
    end

    local vx = -math.sin(relativeBearing)
    local vy = math.cos(relativeBearing)
    if not twx then twx, twy, tcontinent = GetTargetWorld(element) end
    if not pwx then pwx, pwy, pcontinent = GetPlayerWorld(playerMapID) end
    local distance
    if twx and twy and pwx and pwy and (not tcontinent or not pcontinent or pcontinent == tcontinent) then
        distance = WorldDistance(pwx, pwy, twx, twy)
    end

    local halfW = math.max(1, (overlay:GetWidth() or Minimap:GetWidth() or 140) / 2)
    local halfH = math.max(1, (overlay:GetHeight() or Minimap:GetHeight() or 140) / 2)
    local minimapMarkerScale = 0.82
    local minimapBaseSize = tonumber(db.minimapTargetSize) or tonumber(db.targetSize) or 14
    local markerRadius = math.max(5, ((minimapBaseSize * minimapMarkerScale) / 2) + 2)
    local edgeRadiusX = math.max(8, halfW - markerRadius - 3)
    local edgeRadiusY = math.max(8, halfH - markerRadius - 3)
    local viewRadius = GetMinimapViewRadius()
    local targetVisible = distance and viewRadius and distance <= viewRadius

    local pixelDistance
    if distance and viewRadius and viewRadius > 0 then
        pixelDistance = distance / viewRadius
    else
        pixelDistance = 1
    end
    pixelDistance = math.max(0, pixelDistance)

    -- Use an elliptical radius so this also behaves on non-square minimaps.
    local scaleToEdge = 1 / math.sqrt((vx * vx) / (edgeRadiusX * edgeRadiusX) + (vy * vy) / (edgeRadiusY * edgeRadiusY))
    local visibleScale = targetVisible and math.min(scaleToEdge, scaleToEdge * pixelDistance) or scaleToEdge
    local endX, endY = vx * visibleScale, vy * visibleScale

    local mainThickness = GetBaseThickness() + 1.2
    local outlineThickness = mainThickness + 3.8
    local corpseMode = element and element.corpseNav
    if corpseMode then
        minimapRouteOutlineTexture:SetVertexColor(CORPSE_OUTLINE[1], CORPSE_OUTLINE[2], CORPSE_OUTLINE[3], 0.98)
        minimapRouteTexture:SetVertexColor(CORPSE_LINE[1], CORPSE_LINE[2], CORPSE_LINE[3], 1)
        if targetDot and targetDot.center then targetDot.center:SetVertexColor(CORPSE_LINE_BRIGHT[1], CORPSE_LINE_BRIGHT[2], CORPSE_LINE_BRIGHT[3], 1) end
        ConfigureRouteIconsForMode(minimapArrows, true, 12)
    else
        local theme = GetTheme()
        local orr, org, orb = GetOutlineColor(theme)
        minimapRouteOutlineTexture:SetVertexColor(orr, org, orb, 0.96)
        minimapRouteTexture:SetVertexColor(theme.line[1], theme.line[2], theme.line[3], 1)
        if targetDot and targetDot.center then targetDot.center:SetVertexColor(theme.center[1], theme.center[2], theme.center[3], 1) end
        ConfigureRouteIconsForMode(minimapArrows, false, 12)
    end
    SetRouteTexture(minimapRouteOutlineTexture, 0, 0, endX, endY, outlineThickness)
    SetRouteTexture(minimapRouteTexture, 0, 0, endX, endY, mainThickness)
    if db.animation then
        UpdateArrowSet(minimapArrows, overlay, 0, 0, endX, endY, GetTime and GetTime() or 0, 28, corpseMode, db.minimapAnimationSpeed)
        if corpseMode then ApplyCorpseProximityToIcons(minimapArrows, distance) end
    else
        for _, a in ipairs(minimapArrows) do a:Hide() end
    end

    ResizeTargetMarker(targetDot, minimapMarkerScale, minimapBaseSize)
    UpdateMarkerMetadata(targetDot, element, 1, false)
    SetCurrentMarkerHighlight(targetDot, db.currentHighlight, corpseMode)
    if db.showTargetMarker and targetVisible then
        targetDot:ClearAllPoints()
        targetDot:SetPoint("CENTER", overlay, "CENTER", endX, endY)
        targetDot:Show()
        if minimapEdgeArrow then minimapEdgeArrow:Hide() end
        if minimapEdgeDistanceText then minimapEdgeDistanceText:Hide() end
    else
        targetDot:Hide()
        if db.showOffscreenIndicator and minimapEdgeArrow then
            minimapEdgeArrow:ClearAllPoints()
            minimapEdgeArrow:SetPoint("CENTER", overlay, "CENTER", endX, endY)
            minimapEdgeArrow:SetRotation(math.atan2(endY, endX))
            minimapEdgeArrow:Show()
            if minimapEdgeDistanceText and distance then
                minimapEdgeDistanceText:ClearAllPoints()
                minimapEdgeDistanceText:SetPoint("CENTER", overlay, "CENTER", endX * 0.77, endY * 0.77)
                if distance >= 1000 then minimapEdgeDistanceText:SetText(string.format("%.1f km", distance/1000)) else minimapEdgeDistanceText:SetText(string.format("%d yd", math.floor(distance+0.5))) end
                minimapEdgeDistanceText:Show()
            end
        else
            if minimapEdgeArrow then minimapEdgeArrow:Hide() end
            if minimapEdgeDistanceText then minimapEdgeDistanceText:Hide() end
        end
    end

    if Navigator.MinimapOverlays and Navigator.MinimapOverlays.Update then
        Navigator.MinimapOverlays:Update({
            overlay = overlay,
            playerMapID = playerMapID,
            playerX = px,
            playerY = py,
            halfW = halfW,
            halfH = halfH,
            viewRadius = viewRadius,
            markerSize = minimapBaseSize,
            rotating = IsMinimapRotating(),
            futureGoals = db.futureGoals or 0,
            corpseMode = corpseMode,
        })
    end

    if Navigator.MinimapFuture and Navigator.MinimapFuture.Update then
        Navigator.MinimapFuture:Update({
            overlay = overlay,
            playerMapID = playerMapID,
            playerX = px,
            playerY = py,
            halfW = halfW,
            halfH = halfH,
            viewRadius = viewRadius,
            markerSize = minimapBaseSize,
            currentX = endX,
            currentY = endY,
            rotating = IsMinimapRotating(),
            futureGoals = db.futureGoals or 0,
            enabled = db.showMinimapFutureGoals ~= false,
            corpseMode = corpseMode,
        })
    end

    if db.showDistance and distance then
        local prefix = corpseMode and (L("corpse") .. "  ") or "RXP  "
        if distance >= 1000 then distanceText:SetText(prefix .. string.format("%.1f km", distance / 1000))
        else distanceText:SetText(prefix .. string.format("%d yd", math.floor(distance + 0.5))) end
        distanceText:Show()
    else
        distanceText:Hide()
    end
end

local function GetDisplayedMapID()
    if WorldMapFrame and type(WorldMapFrame.GetMapID) == "function" then
        local id = WorldMapFrame:GetMapID()
        if id then return id end
    end
    if WorldMapFrame and WorldMapFrame.mapID then return WorldMapFrame.mapID end
    return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
end

local function UpdateWorldTask(element, gx, gy)
    -- Task text is shown only as a mouseover tooltip on the target marker.
    if worldTaskFrame then worldTaskFrame:Hide() end
end


-- RestedXP world-map filtering moved to RXP_Navigator_WorldMapFilter.lua

local function UpdateWorldMapRoute()
    if not db or not db.enabled or not db.showWorldMap then HideWorldRoute() return end
    if not (WorldMapFrame and WorldMapFrame:IsShown()) then HideWorldRoute() return end
    if not EnsureWorldMapOverlay() then HideWorldRoute() return end

    local displayMapID = GetDisplayedMapID()
    if not displayMapID then HideWorldRoute() return end

    local rawCurrent = GetCurrentNavigationElement()
    if not rawCurrent then HideWorldRoute() return end
    local routePlan = Navigator.RouteResolver and Navigator.RouteResolver:GetCurrentPlan()
    local current = routePlan and routePlan.goal or rawCurrent
    local targetMapID, tx, ty = GetTargetMap(current)
    if not targetMapID then current = rawCurrent; targetMapID, tx, ty = GetTargetMap(current) end
    if not targetMapID then HideWorldRoute() return end

    local travelInfo = Navigator.TravelMode and Navigator.TravelMode:GetInfo(rawCurrent)
    local smartTravelPlan = travelInfo and Navigator.TravelPlanner and Navigator.TravelPlanner.GetPlan and Navigator.TravelPlanner:GetPlan(rawCurrent) or nil
    local travelApproach = smartTravelPlan and smartTravelPlan.approachElement or nil

    -- If a concrete departure point is known, make it the current goal and let
    -- the normal world-map renderer draw the line from the player to that point.
    -- Only fall back to the old remote-marker behavior when no safe local
    -- transport point could be resolved.
    if travelInfo and travelApproach then
        current = travelApproach
        targetMapID, tx, ty = GetTargetMap(current)
    elseif travelInfo then
        local travelMapID, travelX, travelY = GetTargetMap(rawCurrent)
        local gx, gy = travelMapID and PositionInDisplayedMap(travelMapID, travelX, travelY, displayMapID, true)
        local w, h = worldMapOverlay:GetWidth(), worldMapOverlay:GetHeight()
        if not gx or not gy or gx < 0 or gx > 1 or gy < 0 or gy > 1 or not w or not h or w < 10 or h < 10 then
            HideWorldRoute()
            return
        end
        HideWorldRoute()
        ResizeTargetMarker(worldTargetPin, 0.72, db.worldTargetSize or db.targetSize)
        UpdateMarkerMetadata(worldTargetPin, rawCurrent, 1, true)
        SetCurrentMarkerHighlight(worldTargetPin, db.currentHighlight, false)
        worldTargetPin:SetScale(1)
        worldTargetPin:SetAlpha(1)
        worldTargetPin:ClearAllPoints()
        worldTargetPin:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", gx * w, -gy * h)
        if db.showTargetMarker then worldTargetPin:Show() end
        local hb = GetWorldHitbox(1)
        if hb then
            hb.rxpElement = rawCurrent
            hb.rxpOrdinal = 1
            hb.rxpClusterMembers = nil
            hb:ClearAllPoints()
            hb:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", gx * w, -gy * h)
            if db.showTargetMarker and db.showTaskTooltip then hb:Show() else hb:Hide() end
        end
        UpdateWorldTask(rawCurrent, gx, gy)
        if Navigator.WorldMapFilter then Navigator.WorldMapFilter:SuppressNativeRXPWorldProgressLabels() end
        return
    end

    -- Project the real goal marker first. Intermediate RXP waypoints are route
    -- geometry only and never receive target markers of their own.
    local px, py, playerOffMap = GetPlayerPositionInDisplayedMap(displayMapID, true)
    local rawGX, rawGY = PositionInDisplayedMap(targetMapID, tx, ty, displayMapID, true)
    if not px or not py or not rawGX or not rawGY then HideWorldRoute() return end

    local targetInside = rawGX >= 0 and rawGX <= 1 and rawGY >= 0 and rawGY <= 1
    if playerOffMap and targetInside then
        px, py = ClampTargetToMapEdge(rawGX, rawGY, px, py, 0.025)
    elseif playerOffMap then
        HideWorldRoute()
        return
    end
    local gx, gy = ClampTargetToMapEdge(px, py, rawGX, rawGY, 0.025)

    local w, h = worldMapOverlay:GetWidth(), worldMapOverlay:GetHeight()
    if not w or not h or w < 10 or h < 10 then HideWorldRoute() return end

    local baseThickness = GetBaseThickness()
    local boost = 1.0
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(displayMapID)
    if info and info.mapType then
        if info.mapType <= 1 then boost = 1.80 elseif info.mapType == 2 then boost = 1.55 end
    end
    local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
    if sc and type(sc.GetCanvasScale) == "function" then
        local cs = sc:GetCanvasScale()
        if type(cs) == "number" and cs > 0 and cs < 1 then boost = math.max(boost, math.min(2.05, 1 / math.sqrt(cs))) end
    end

    local mainThickness = math.max(2.6, baseThickness * 0.74 * boost)
    local shadowThickness = mainThickness + math.max(1.6, 1.00 * boost)
    local worldMarkerScale = math.max(0.42, math.min(0.72, 0.72 / (boost ^ 0.78)))
    local theme = GetTheme()
    local corpseMode = rawCurrent and rawCurrent.corpseNav
    local orr, org, orb = GetOutlineColor(theme)
    local lr, lg, lb = theme.line[1], theme.line[2], theme.line[3]
    if corpseMode then
        orr, org, orb = CORPSE_OUTLINE[1], CORPSE_OUTLINE[2], CORPSE_OUTLINE[3]
        lr, lg, lb = CORPSE_LINE[1], CORPSE_LINE[2], CORPSE_LINE[3]
    end

    -- Real current-goal marker. Waypoints remain invisible route geometry.
    ResizeTargetMarker(worldTargetPin, worldMarkerScale, db.worldTargetSize or db.targetSize)
    UpdateMarkerMetadata(worldTargetPin, current, 1, true)
    SetCurrentMarkerHighlight(worldTargetPin, db.currentHighlight, corpseMode)
    worldTargetPin:SetScale(1)
    worldTargetPin:SetAlpha(1)
    worldTargetPin:ClearAllPoints()
    worldTargetPin:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", gx * w, -gy * h)
    if db.showTargetMarker then worldTargetPin:Show() else worldTargetPin:Hide() end

    local hitbox = GetWorldHitbox(1)
    if hitbox then
        hitbox.rxpElement = current
        hitbox.rxpOrdinal = 1
        hitbox.rxpClusterMembers = nil
        hitbox:ClearAllPoints()
        hitbox:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", gx * w, -gy * h)
        if db.showTargetMarker and db.showTaskTooltip then hitbox:Show() else hitbox:Hide() end
    end

    -- Build the actual RXP route path: current unresolved .goto chain followed
    -- by the ordered chains of the selected future guide steps. Projection is
    -- best-effort; unusable points are skipped, preserving a safe direct path.
    local routeElements
    if travelApproach then
        routeElements = { travelApproach }
    else
        routeElements = Navigator.RouteResolver and Navigator.RouteResolver:GetWorldPath(db.futureGoals or 0) or { rawCurrent }
    end
    if type(routeElements) ~= "table" or #routeElements == 0 then routeElements = { current or rawCurrent } end
    local projected = {}
    local prevPX, prevPY = px, py
    for _, element in ipairs(routeElements) do
        local mapID, ex, ey = GetTargetMap(element)
        local rx, ry
        if mapID then rx, ry = PositionInDisplayedMap(mapID, ex, ey, displayMapID, true) end
        if rx and ry then
            rx, ry = ClampTargetToMapEdge(prevPX, prevPY, rx, ry, 0.025)
            local last = projected[#projected]
            if not last or math.abs(last.x - rx) > 0.0002 or math.abs(last.y - ry) > 0.0002 then
                projected[#projected + 1] = { x = rx, y = ry, element = element }
                prevPX, prevPY = rx, ry
            end
        end
    end
    if #projected == 0 then projected[1] = { x = gx, y = gy, element = current } end

    -- Build a smooth visual polyline through the exact projected RXP points.
    -- The original points are preserved; only the segments between them are
    -- rounded for a less angular route presentation.
    local sourcePoints = { { x = px * w - w / 2, y = -py * h + h / 2 } }
    for _, point in ipairs(projected) do
        sourcePoints[#sourcePoints + 1] = { x = point.x * w - w / 2, y = -point.y * h + h / 2 }
    end
    local smoothPoints = Navigator.RouteSmoother and Navigator.RouteSmoother:BuildPixelPath(sourcePoints, 0.20) or sourcePoints
    if Navigator.RouteTooltip and Navigator.RouteTooltip.Update then
        Navigator.RouteTooltip:Update(worldMapOverlay, smoothPoints, current)
    end

    if worldMainRouteOutlineTexture then worldMainRouteOutlineTexture:Hide() end
    if worldMainRouteTexture then worldMainRouteTexture:Hide() end
    HideNativeChevrons(worldArrows)

    local segmentIndex = 0
    for i = 2, #smoothPoints do
        local a, b = smoothPoints[i - 1], smoothPoints[i]
        if math.sqrt((b.x - a.x)^2 + (b.y - a.y)^2) > 0.8 then
            segmentIndex = segmentIndex + 1
            local line, shadow = GetWorldRouteSegment(segmentIndex)
            shadow:SetColorTexture(orr, org, orb, 0.90)
            SetNativeWorldLine(shadow, worldMapOverlay, a.x, a.y, b.x, b.y, shadowThickness * 0.92)
            line:SetColorTexture(lr, lg, lb, 0.96)
            SetNativeWorldLine(line, worldMapOverlay, a.x, a.y, b.x, b.y, mainThickness * 0.92)
        end
    end

    -- Keep the animated direction cues sparse and tied to the original route
    -- segments. This avoids flooding the map with arrows just because the
    -- visual line contains additional smoothing samples.
    local sourceSegmentCount = math.max(0, #sourcePoints - 1)
    if db.animation and sourceSegmentCount > 0 then
        local arrowSize = math.min(16, 11.0 + (boost - 1) * 1.8)
        for i = 1, sourceSegmentCount do
            local arrows = (i == 1) and worldArrowTextures or GetWorldFutureArrowSet(i - 1)
            local segmentPath = Navigator.RouteSmoother:BuildSegmentPath(smoothPoints, sourcePoints, i)
            ConfigureRouteIconsForMode(arrows, corpseMode, arrowSize)
            UpdateArrowSetAlongPath(arrows, worldArrowLayer or worldMapOverlay, segmentPath, GetTime and GetTime() or 0, i == 1 and 42 or 24, corpseMode, db.worldAnimationSpeed)
        end
    else
        for _, a in ipairs(worldArrowTextures) do a:Hide() end
        HideWorldFutureArrowSets(1)
    end

    for i = segmentIndex + 1, #worldRouteLines do
        worldRouteLines[i]:Hide()
        if worldRouteShadows[i] then worldRouteShadows[i]:Hide() end
    end
    if db.animation then HideWorldFutureArrowSets(math.max(1, sourceSegmentCount)) end
    for _, label in ipairs(worldRouteDistanceLabels) do label:Hide() end

    if Navigator.MapOverlays and Navigator.MapOverlays.Render then
        Navigator.MapOverlays:Render(displayMapID, worldMapOverlay, w, h, boost)
    end

    -- Target markers are still based only on real current/future goals. Route
    -- waypoints never create visible pins or labels.
    local targets = GetNavigationTargets(db.futureGoals or 0)
    local clusters = BuildWorldTargetClusters(targets, displayMapID)
    local shownFuture, hitboxIndex = 0, 1
    for _, cluster in ipairs(clusters) do
        local isCurrentCluster = false
        for _, member in ipairs(cluster.members) do if member.ordinal == 1 then isCurrentCluster = true break end end
        local cx, cy = ClampTargetToMapEdge(px, py, cluster.x, cluster.y, 0.025)
        if isCurrentCluster then
            local hb = GetWorldHitbox(1)
            if hb then
                hb.rxpElement = current
                hb.rxpOrdinal = 1
                hb.rxpClusterMembers = cluster.members
            end
            if worldTargetPin and worldTargetPin.rxpFutureLabel then worldTargetPin.rxpFutureLabel:SetText(""); worldTargetPin.rxpFutureLabel:Hide() end
        else
            shownFuture = shownFuture + 1
            local pinOrdinal = shownFuture + 1
            local pin = GetWorldTargetPin(pinOrdinal)
            local strongestOrdinal = cluster.members[1] and cluster.members[1].ordinal or pinOrdinal
            ResizeTargetMarker(pin, worldMarkerScale, db.worldTargetSize or db.targetSize)
            UpdateMarkerMetadata(pin, cluster.members[1] and cluster.members[1].element or nil, strongestOrdinal, true)
            pin:SetScale(1)
            pin:SetAlpha(math.max(0.48, 0.74 - (strongestOrdinal - 2) * 0.10))
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", cx * w, -cy * h)
            if pin.rxpFutureLabel then pin.rxpFutureLabel:SetText(""); pin.rxpFutureLabel:Hide() end
            if db.showTargetMarker then pin:Show() else pin:Hide() end

            hitboxIndex = hitboxIndex + 1
            local hb = GetWorldHitbox(hitboxIndex)
            if hb then
                local firstMember = cluster.members[1]
                hb.rxpElement = firstMember and firstMember.element or nil
                hb.rxpOrdinal = firstMember and firstMember.ordinal or pinOrdinal
                hb.rxpClusterMembers = cluster.members
                hb:ClearAllPoints()
                hb:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", cx * w, -cy * h)
                if db.showTargetMarker and db.showTaskTooltip then hb:Show() else hb:Hide() end
            end
        end
    end
    for i = shownFuture + 1, #worldFuturePins do worldFuturePins[i]:Hide() end
    for i = hitboxIndex + 1, #worldHitboxes do worldHitboxes[i].rxpClusterMembers = nil; worldHitboxes[i]:Hide() end

    if worldSpiritHealerIcon then
        worldSpiritHealerIcon:Hide()
        if IsCorpseRunMode() and db.showSpiritHealer then
            local healer = GetNearestSpiritHealerElement()
            local hm, hx, hy = GetTargetMap(healer)
            local hdx, hdy
            if hm then hdx, hdy = PositionInDisplayedMap(hm, hx, hy, displayMapID, true) end
            if hdx and hdy and hdx >= 0 and hdx <= 1 and hdy >= 0 and hdy <= 1 then
                worldSpiritHealerIcon:ClearAllPoints()
                worldSpiritHealerIcon:SetPoint("CENTER", worldMapOverlay, "TOPLEFT", hdx*w, -hdy*h)
                worldSpiritHealerIcon:Show()
            end
        end
    end

    UpdateWorldTask(current, gx, gy)
    if Navigator.WorldMapFilter then Navigator.WorldMapFilter:SuppressNativeRXPWorldProgressLabels() end
end

local function FormatHUDDistance(distance)
    if type(distance) ~= "number" then return "--" end
    if distance >= 1000 then
        return string.format("%.1f km", distance / 1000)
    end
    return string.format("%d yd", math.floor(distance + 0.5))
end

local function FormatETA(seconds, approximate)
    if type(seconds) ~= "number" or seconds < 0 or seconds ~= seconds then return "ETA --:--" end
    seconds = math.min(seconds, 359999)
    local rounded = math.floor(seconds + 0.5)
    local h = math.floor(rounded / 3600)
    local m = math.floor((rounded % 3600) / 60)
    local s = rounded % 60
    local prefix = approximate and "ETA ~" or "ETA "
    if h > 0 then
        return string.format("%s%d:%02d:%02d", prefix, h, m, s)
    end
    return string.format("%s%d:%02d", prefix, m, s)
end

local function ApplyHUDPosition()
    if not hudArrowFrame or not db then return end
    hudArrowFrame:ClearAllPoints()
    local point = db.hudPoint or "TOP"
    local relativePoint = db.hudRelativePoint or point
    hudArrowFrame:SetPoint(point, UIParent, relativePoint, tonumber(db.hudX) or 0, tonumber(db.hudY) or -120)
end

local HUD_ARROW_TEXTURES = {
    classic = "Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_HUDArrow2D_Classic.tga",
    compass = "Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_HUDArrow2D_Compass.tga",
    crystal = "Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_HUDArrow2D_Crystal.tga",
}

local function GetHUDArrowStyle()
    local style = db and db.hudArrowStyle or "classic"
    if style ~= "classic" and style ~= "compass" and style ~= "crystal" then style = "classic" end
    return style
end

local function GetHUDArrowTexturePath()
    return HUD_ARROW_TEXTURES[GetHUDArrowStyle()] or HUD_ARROW_TEXTURES.classic
end

local function StyleUsesHudColor(style)
    return style == "classic"
end

local function SaveHUDPosition()
    if not hudArrowFrame or not db then return end
    local point, _, relativePoint, x, y = hudArrowFrame:GetPoint(1)
    db.hudPoint = point or "TOP"
    db.hudRelativePoint = relativePoint or db.hudPoint
    db.hudX = x or 0
    db.hudY = y or -120
end

local function ApplyHUDStyle()
    if not hudArrowFrame or not db then return end
    local arrowScale = tonumber(db.hudSize) or 1.0
    arrowScale = math.max(0.55, math.min(2.0, arrowScale))
    local textScale = tonumber(db.hudTextSize) or 1.0
    textScale = math.max(0.70, math.min(1.60, textScale))
    hudArrowFrame:SetScale(1)

    local style = GetHUDArrowStyle()
    local texture = GetHUDArrowTexturePath()
    local corpseMode = IsCorpseRunMode()
    if hudArrowTexture then
        hudArrowTexture:SetTexture(texture)
        hudArrowTexture:SetSize(64 * arrowScale, 36 * arrowScale)
        if corpseMode then
            hudArrowTexture:SetVertexColor(CORPSE_LINE_BRIGHT[1], CORPSE_LINE_BRIGHT[2], CORPSE_LINE_BRIGHT[3], 1)
        elseif StyleUsesHudColor(style) then
            hudArrowTexture:SetVertexColor(tonumber(db.hudColorR) or 0.08, tonumber(db.hudColorG) or 0.74, tonumber(db.hudColorB) or 1.0, 1)
        else
            hudArrowTexture:SetVertexColor(1, 1, 1, 1)
        end
    end
    if hudCorpseSkull then
        local skullSize = math.max(10, math.min(64, tonumber(db.corpseHudSkullSize) or 24))
        local skullAlpha = math.max(0.05, math.min(1.0, tonumber(db.corpseSkullAlpha) or 0.30))
        hudCorpseSkull:SetSize(skullSize, skullSize)
        hudCorpseSkull:SetVertexColor(1, 1, 1, skullAlpha)
        if corpseMode then hudCorpseSkull:Show() else hudCorpseSkull:Hide() end
    end
    if hudArrowShadow then
        hudArrowShadow:SetTexture(texture)
        hudArrowShadow:SetSize(64 * arrowScale, 36 * arrowScale)
    end


    if hudDistanceText and GameFontNormalLarge and GameFontNormalLarge.GetFont then
        local path, size, flags = GameFontNormalLarge:GetFont()
        if path and size then hudDistanceText:SetFont(path, size * textScale, flags) end
    end
    if hudEtaText and GameFontHighlightSmall and GameFontHighlightSmall.GetFont then
        local path, size, flags = GameFontHighlightSmall:GetFont()
        if path and size then
            hudEtaText:SetFont(path, size * textScale, flags)
            if hudContextText then hudContextText:SetFont(path, math.max(8, size * textScale * 0.92), flags) end
        end
    end

    if hudDistanceText then
        hudDistanceText:ClearAllPoints()
        hudDistanceText:SetPoint("TOP", hudArrowFrame, "TOP", 0, -(44 + 20 * arrowScale))
        hudDistanceText:SetTextColor(1, 1, 1, 1)
    end
    if hudEtaText then
        hudEtaText:ClearAllPoints()
        hudEtaText:SetPoint("TOP", hudArrowFrame, "TOP", 0, -(69 + 20 * arrowScale))
        hudEtaText:SetTextColor(0.82, 0.88, 0.94, 1)
    end

    -- Release design: modern only.
    if hudBackground then hudBackground:Hide() end
    for _, edge in ipairs(hudBorder) do edge:Hide() end

    local locked = db.hudLocked and true or false
    hudArrowFrame:EnableMouse(not locked)
    if hudDragHint then hudDragHint:Hide() end
end

local function HideGrindHUD()
    if not hudArrowFrame then return end
    if hudArrowFrame.rxpGrindBar then hudArrowFrame.rxpGrindBar:Hide() end
    if hudArrowFrame.rxpGrindText then hudArrowFrame.rxpGrindText:Hide() end
    if hudArrowFrame.rxpGrindPercent then hudArrowFrame.rxpGrindPercent:Hide() end
    if hudArrowFrame.rxpGrindAction then hudArrowFrame.rxpGrindAction:Hide() end
    hudArrowFrame:SetHeight(136)
end

local function EnsureGrindHUD()
    if not hudArrowFrame or hudArrowFrame.rxpGrindBar then return end

    local bar = CreateFrame("StatusBar", nil, hudArrowFrame)
    bar:SetSize(180, 12)
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bar:SetStatusBarColor(0.20, 0.65, 1.00, 0.98)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetPoint("TOP", hudArrowFrame, "TOP", 0, -105)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.02, 0.02, 0.02, 0.88)

    local borderTop = bar:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    borderTop:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 1, 1)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.72, 0.58, 0.22, 0.90)

    local borderBottom = bar:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", -1, -1)
    borderBottom:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.72, 0.58, 0.22, 0.90)

    local progressText = hudArrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("BOTTOM", bar, "TOP", 0, 5)
    progressText:SetTextColor(1, 1, 1, 1)
    progressText:SetShadowColor(0, 0, 0, 1)
    progressText:SetShadowOffset(1, -1)

    local percentText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    percentText:SetPoint("CENTER", bar, "CENTER", 0, 0)
    percentText:SetTextColor(1, 1, 1, 1)
    percentText:SetShadowColor(0, 0, 0, 1)
    percentText:SetShadowOffset(1, -1)

    local actionText = hudArrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionText:SetPoint("TOP", bar, "BOTTOM", 0, -7)
    actionText:SetWidth(290)
    actionText:SetJustifyH("CENTER")
    actionText:SetTextColor(1.00, 0.82, 0.28, 1)
    actionText:SetShadowColor(0, 0, 0, 1)
    actionText:SetShadowOffset(1, -1)

    hudArrowFrame.rxpGrindBar = bar
    hudArrowFrame.rxpGrindText = progressText
    hudArrowFrame.rxpGrindPercent = percentText
    hudArrowFrame.rxpGrindAction = actionText
    bar:Hide()
    progressText:Hide()
    percentText:Hide()
    actionText:Hide()
end

local function UpdateGrindHUD(state)
    if not hudArrowFrame then return false end
    if state == nil then
        state = Navigator.GrindHUD and Navigator.GrindHUD.GetState and Navigator.GrindHUD:GetState() or nil
    end
    if not state then
        HideGrindHUD()
        return false
    end

    EnsureGrindHUD()
    local bar = hudArrowFrame.rxpGrindBar
    local progressText = hudArrowFrame.rxpGrindText
    local percentText = hudArrowFrame.rxpGrindPercent
    local actionText = hudArrowFrame.rxpGrindAction
    if not bar or not progressText or not percentText or not actionText then return false end

    -- Grind steps intentionally replace ETA with a larger XP block.
    -- Keep a clear visual gap below the distance readout so the XP block
    -- does not feel cramped against the navigation distance.
    local y = db and db.hudShowDistance and 116 or 90
    bar:ClearAllPoints()
    bar:SetPoint("TOP", hudArrowFrame, "TOP", 0, -y)
    bar:SetMinMaxValues(0, math.max(1, state.goalXP))
    bar:SetValue(math.min(state.currentXP, state.goalXP))

    local percent = math.floor(((state.currentXP or 0) / math.max(1, state.goalXP or 1)) * 100 + 0.5)
    percent = math.max(0, math.min(100, percent))

    progressText:SetText(state.progressText or "")
    percentText:SetText(string.format("%d%%", percent))
    actionText:SetText(state.actionText or "")

    bar:Show()
    progressText:Show()
    percentText:Show()
    actionText:Show()
    hudArrowFrame:SetHeight(y + 58)
    return true
end

local function BuildHUDArrow()
    if hudArrowFrame then return hudArrowFrame end
    local f = CreateFrame("Frame", "RXPNavigatorHUDArrow", UIParent)
    f:SetSize(190, 136)
    -- Keep the navigation HUD behind Blizzard dialog/options/map frames.
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(5)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")

    hudBackground = f:CreateTexture(nil, "BACKGROUND", nil, 0)
    hudBackground:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -2)
    hudBackground:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
    hudBackground:SetColorTexture(0.035, 0.025, 0.015, 0.78)

    local function BorderTex()
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.72, 0.52, 0.18, 0.95)
        hudBorder[#hudBorder + 1] = t
        return t
    end
    local top = BorderTex(); top:SetPoint("TOPLEFT", hudBackground, "TOPLEFT"); top:SetPoint("TOPRIGHT", hudBackground, "TOPRIGHT"); top:SetHeight(1)
    local bottom = BorderTex(); bottom:SetPoint("BOTTOMLEFT", hudBackground, "BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT", hudBackground, "BOTTOMRIGHT"); bottom:SetHeight(1)
    local left = BorderTex(); left:SetPoint("TOPLEFT", hudBackground, "TOPLEFT"); left:SetPoint("BOTTOMLEFT", hudBackground, "BOTTOMLEFT"); left:SetWidth(1)
    local right = BorderTex(); right:SetPoint("TOPRIGHT", hudBackground, "TOPRIGHT"); right:SetPoint("BOTTOMRIGHT", hudBackground, "BOTTOMRIGHT"); right:SetWidth(1)

    hudArrowShadow = f:CreateTexture(nil, "ARTWORK", nil, 1)
    hudArrowShadow:SetTexture(GetHUDArrowTexturePath())
    hudArrowShadow:SetSize(64, 36)
    hudArrowShadow:SetPoint("TOP", f, "TOP", 2, -5)
    hudArrowShadow:SetVertexColor(0, 0, 0, 0.42)

    hudArrowTexture = f:CreateTexture(nil, "OVERLAY", nil, 3)
    hudArrowTexture:SetTexture(GetHUDArrowTexturePath())
    hudArrowTexture:SetSize(64, 36)
    hudArrowTexture:SetPoint("TOP", f, "TOP", 0, -3)
    hudArrowTexture:SetBlendMode("BLEND")

    hudCorpseSkull = f:CreateTexture(nil, "OVERLAY", nil, 4)
    hudCorpseSkull:SetTexture(CORPSE_SKULL_TEXTURE)
    hudCorpseSkull:SetSize(24, 24)
    hudCorpseSkull:SetPoint("TOP", f, "TOP", 0, -9)
    hudCorpseSkull:SetVertexColor(1, 1, 1, 0.30)
    hudCorpseSkull:Hide()

    hudDistanceText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hudDistanceText:SetPoint("TOP", f, "TOP", 0, -76)
    hudDistanceText:SetTextColor(1, 1, 1, 1)
    hudDistanceText:SetShadowColor(0, 0, 0, 1)
    hudDistanceText:SetShadowOffset(1, -1)

    hudEtaText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hudEtaText:SetPoint("TOP", f, "TOP", 0, -101)
    hudEtaText:SetTextColor(0.82, 0.88, 0.94, 1)
    hudEtaText:SetShadowColor(0, 0, 0, 1)
    hudEtaText:SetShadowOffset(1, -1)

    hudContextText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hudContextText:SetPoint("TOP", f, "TOP", 0, -121)
    hudContextText:SetWidth(190)
    hudContextText:SetJustifyH("CENTER")
    hudContextText:SetTextColor(0.95, 0.78, 0.30, 1)
    hudContextText:SetShadowColor(0, 0, 0, 1)
    hudContextText:SetShadowOffset(1, -1)
    hudContextText:Hide()

    hudDragHint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hudDragHint:SetPoint("BOTTOM", f, "BOTTOM", 0, 7)
    hudDragHint:SetText(L("hudDragHint"))
    hudDragHint:SetTextColor(0.75, 0.75, 0.75, 1)
    hudDragHint:Hide()

    f:SetScript("OnDragStart", function(self)
        if db and not db.hudLocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveHUDPosition()
    end)
    f:SetScript("OnEnter", function()
        if db and not db.hudLocked and hudDragHint then hudDragHint:Show() end
    end)
    f:SetScript("OnLeave", function()
        if hudDragHint then hudDragHint:Hide() end
    end)

    hudArrowFrame = f
    ApplyHUDPosition()
    ApplyHUDStyle()
    ApplyTheme()
    f:Hide()
    return f
end

local function HideHUDArrow()
    if hudArrowFrame and hudArrowFrame.rxpTravelIcon then hudArrowFrame.rxpTravelIcon:Hide() end
    if hudArrowFrame then hudArrowFrame:Hide() end
end

local function GetHUDNavigationMetrics(elementOverride)
    local element = elementOverride
    if not element then
        local routePlan = Navigator.RouteResolver and Navigator.RouteResolver:GetCurrentPlan()
        element = routePlan and routePlan.nextPoint or GetCurrentNavigationElement()
    end
    if not element then return nil end
    local targetMapID, tx, ty = GetTargetMap(element)
    if not targetMapID then return nil end

    local playerMapID, px, py = ResolvePlayerMapAndPosition(targetMapID)
    if not playerMapID or not px then return nil end

    local dx, dy
    local localTX, localTY = PositionInDisplayedMap(targetMapID, tx, ty, playerMapID)
    if localTX and localTY then dx, dy = localTX - px, localTY - py end

    local twx, twy, tcontinent = GetTargetWorld(element)
    local pwx, pwy, pcontinent = GetPlayerWorld(playerMapID)
    if not dx and twx and twy then dx, dy = GetWorldVectorInPlayerMap(playerMapID, px, py, twx, twy) end
    if not dx or not dy then return nil end

    local distance
    if twx and twy and pwx and pwy and (not tcontinent or not pcontinent or tcontinent == pcontinent) then
        distance = WorldDistance(pwx, pwy, twx, twy)
    end

    local bearing = math.atan2(-dx, -dy)
    if bearing < 0 then bearing = bearing + PI2 end
    local facing = GetPlayerFacing and GetPlayerFacing() or 0
    local relative = NormalizeAngle(bearing - (type(facing) == "number" and facing or 0))
    -- HUD arrow textures point to the right at rotation 0. Convert the same
    -- relative bearing used by the minimap into screen-space rotation.
    local rotation = NormalizeAngle((math.pi / 2) + relative)
    return rotation, distance, relative
end

local function UpdateHUDArrow(dt)
    if not db or not db.enabled or not db.showHUDArrow then HideHUDArrow() return end
    if not hudArrowFrame then BuildHUDArrow() end
    ApplyHUDStyle()
    -- Keep the HUD arrow scale local to this update as well. ApplyHUDStyle()
    -- uses its own local value, so relying on that variable here would result
    -- in a nil global after the arrow/text size split introduced in beta2.
    local arrowScale = tonumber(db.hudSize) or 1.0
    arrowScale = math.max(0.55, math.min(2.0, arrowScale))

    local currentElement = GetCurrentNavigationElement()

    -- Travel HUD announcements (e.g. Hearthstone) take precedence over
    -- directional navigation. A Travel action is an instruction, not a path.
    local travelAnnouncement = Navigator.TravelHUD and Navigator.TravelHUD:GetAnnouncement(currentElement)
    if travelAnnouncement then
        HideGrindHUD()
        if hudCorpseSkull then hudCorpseSkull:Hide() end
        if hudArrowTexture then hudArrowTexture:Hide() end
        if hudArrowShadow then hudArrowShadow:Hide() end

        if hudArrowFrame and not hudArrowFrame.rxpTravelIcon then
            hudArrowFrame.rxpTravelIcon = hudArrowFrame:CreateTexture(nil, "OVERLAY", nil, 4)
            hudArrowFrame.rxpTravelIcon:SetSize(48, 48)
            hudArrowFrame.rxpTravelIcon:SetPoint("TOP", hudArrowFrame, "TOP", 0, -2)
        end
        if hudArrowFrame and hudArrowFrame.rxpTravelIcon then
            hudArrowFrame.rxpTravelIcon:SetTexture(travelAnnouncement.icon or "Interface\\Icons\\INV_Misc_Rune_01")
            hudArrowFrame.rxpTravelIcon:SetTexCoord(0, 1, 0, 1)
            hudArrowFrame.rxpTravelIcon:Show()
        end

        if hudDistanceText then
            hudDistanceText:ClearAllPoints()
            hudDistanceText:SetPoint("TOP", hudArrowFrame, "TOP", 0, -(54 + 18 * arrowScale))
            hudDistanceText:SetWidth(260)
            hudDistanceText:SetJustifyH("CENTER")
            if GameFontNormalLarge and GameFontNormalLarge.GetFont then
                local path, size, flags = GameFontNormalLarge:GetFont()
                if path and size then hudDistanceText:SetFont(path, math.max(12, size * (tonumber(db.hudTextSize) or 1.0) * 0.92), flags) end
            end
            hudDistanceText:SetText("|cffffd24a" .. (travelAnnouncement.title or "TRAVEL") .. "|r")
            hudDistanceText:Show()
        end
        if hudEtaText then
            hudEtaText:SetText("")
            hudEtaText:Hide()
        end
        if hudContextText then
            hudContextText:SetText("")
            hudContextText:Hide()
        end
        hudArrowFrame:Show()
        return
    end

    if hudArrowFrame and hudArrowFrame.rxpTravelIcon then
        hudArrowFrame.rxpTravelIcon:Hide()
    end

    local travelInfo = Navigator.TravelMode and Navigator.TravelMode:GetInfo(currentElement)
    if travelInfo then
        HideGrindHUD()
        -- Beta41: route selection is centralized in TravelPlanner. The proven
        -- TravelMode fallback remains authoritative when no smart plan exists.
        local smartTravelPlan = Navigator.TravelPlanner and Navigator.TravelPlanner.GetPlan and Navigator.TravelPlanner:GetPlan(currentElement) or nil
        local travelRoute = smartTravelPlan and smartTravelPlan.routeRaw or Navigator.TravelMode:GetBestRoute(currentElement, travelInfo)
        if hudCorpseSkull then hudCorpseSkull:Hide() end

        if travelRoute then
            local departureElement = smartTravelPlan and smartTravelPlan.approachElement or { zone=travelRoute.fromMap, x=travelRoute.fromX, y=travelRoute.fromY, arrow=true, textOnly=true, travelPoint=true }
            local rotation, distance = GetHUDNavigationMetrics(departureElement)
            if rotation then
                if hudArrowTexture then hudArrowTexture:Show(); hudArrowTexture:SetRotation(rotation) end
                if hudArrowShadow then hudArrowShadow:Show(); hudArrowShadow:SetRotation(rotation) end
            else
                if hudArrowTexture then hudArrowTexture:Hide() end
                if hudArrowShadow then hudArrowShadow:Hide() end
            end

            if hudDistanceText then
                local planForDisplay = smartTravelPlan
                local routeKind = planForDisplay and planForDisplay.route and planForDisplay.route.kind or nil
                local iconTexture = Navigator.Presentation and Navigator.Presentation:GetTransportIcon(routeKind) or "Interface\MINIMAP\TRACKING\FlightMaster"
                local icon = "|T" .. iconTexture .. ":20:20:0:0|t"
                local title = Navigator.Presentation and Navigator.Presentation:FormatTravelTitle(planForDisplay)
                if not title then
                    local kind = travelRoute.kind == "Ship" and (L("travelShip") or "Ship") or (L("travelZeppelin") or "Zeppelin")
                    title = kind .. " -> " .. travelRoute.toName
                end
                if GameFontNormalLarge and GameFontNormalLarge.GetFont then
                    local path, size = GameFontNormalLarge:GetFont()
                    if path and size then
                        hudDistanceText:SetFont(path, math.max(13, size * (tonumber(db.hudTextSize) or 1.0)), "OUTLINE")
                    end
                end
                hudDistanceText:SetShadowColor(0, 0, 0, 1)
                hudDistanceText:SetShadowOffset(2, -2)
                hudDistanceText:SetText(icon .. "  |cffffd24a" .. title .. "|r")
                hudDistanceText:Show()
            end
            if hudEtaText then
                if distance then
                    if GameFontNormalLarge and GameFontNormalLarge.GetFont then
                        local path, size = GameFontNormalLarge:GetFont()
                        if path and size then
                            hudEtaText:SetFont(path, math.max(14, size * (tonumber(db.hudTextSize) or 1.0) * 0.95), "OUTLINE")
                        end
                    end
                    hudEtaText:SetTextColor(1, 1, 1, 1)
                    hudEtaText:SetShadowColor(0, 0, 0, 1)
                    hudEtaText:SetShadowOffset(2, -2)
                    hudEtaText:SetText(FormatHUDDistance(distance))
                    hudEtaText:Show()
                else
                    hudEtaText:Hide()
                end
            end
            if hudContextText then
                local context = Navigator.Presentation and Navigator.Presentation:FormatTravelContext(planForDisplay) or nil
                if context and context ~= "" then
                    hudContextText:ClearAllPoints()
                    hudContextText:SetPoint("TOP", hudArrowFrame, "TOP", 0, -126)
                    hudContextText:SetWidth(320)
                    hudContextText:SetJustifyH("CENTER")
                    if GameFontHighlightSmall and GameFontHighlightSmall.GetFont then
                        local path, size = GameFontHighlightSmall:GetFont()
                        if path and size then
                            hudContextText:SetFont(path, math.max(11, size * (tonumber(db.hudTextSize) or 1.0)), "OUTLINE")
                        end
                    end
                    hudContextText:SetTextColor(1.00, 0.86, 0.48, 1)
                    hudContextText:SetShadowColor(0, 0, 0, 1)
                    hudContextText:SetShadowOffset(2, -2)
                    hudContextText:SetText(context)
                    hudContextText:Show()
                else
                    hudContextText:SetText("")
                    hudContextText:Hide()
                end
            end
        else
            -- Safe fallback: never hide the proven beta8 travel warning just because
            -- no curated transport point can be selected.
            if hudArrowTexture then hudArrowTexture:Hide() end
            if hudArrowShadow then hudArrowShadow:Hide() end
            if hudDistanceText then
                local icon = "|TInterface\\MINIMAP\\TRACKING\\FlightMaster:18:18:0:0|t"
                hudDistanceText:SetText(icon .. "  |cffffd24a" .. (L("travel") or "Travel") .. "|r")
                hudDistanceText:Show()
            end
            if hudEtaText then hudEtaText:Hide() end
            if hudContextText then
                local prefix = L("travelTo") or "Travel to"
                local thenWord = L("travelThen") or "Then"
                hudContextText:SetText("|cffffd24a" .. prefix .. " " .. travelInfo.targetContinentName .. "|r\n|cffb8b8b8" .. thenWord .. ": " .. travelInfo.targetZone .. "|r")
                hudContextText:Show()
            end
        end
        hudArrowFrame:Show()
        return
    end

    -- Restore normal arrow visuals automatically after arriving on the target continent.
    if hudArrowTexture then hudArrowTexture:Show() end
    if hudArrowShadow then hudArrowShadow:Show() end

    local rotation, distance, relativeBearing = GetHUDNavigationMetrics()
    if not rotation or not distance then HideHUDArrow() return end

    -- WoW Forever may return a protected/secret number from GetUnitSpeed().
    -- Secret values cannot legally be compared or used in arithmetic by addons,
    -- so ETA deliberately uses a safe estimated travel speed instead.
    local etaSpeed = 7.0
    if IsMounted and IsMounted() then etaSpeed = 14.0 end
    local approximate = true

    hudArrowTexture:SetRotation(rotation)
    if hudArrowShadow then hudArrowShadow:SetRotation(rotation) end

    local corpseMode = IsCorpseRunMode()
    if db.hudShowDistance then
        if corpseMode then hudDistanceText:SetText(L("corpse") .. ": " .. FormatHUDDistance(distance))
        else hudDistanceText:SetText(FormatHUDDistance(distance)) end
        hudDistanceText:Show()
    else
        hudDistanceText:Hide()
    end
    if corpseMode and hudCorpseSkull then
        local proximity = math.max(0, math.min(1, (90-distance)/90))
        local baseSize = math.max(10, math.min(64, tonumber(db.corpseHudSkullSize) or 24))
        local baseAlpha = math.max(0.05, math.min(1.0, tonumber(db.corpseSkullAlpha) or 0.30))
        hudCorpseSkull:SetSize(baseSize*(1+proximity*0.22), baseSize*(1+proximity*0.22))
        hudCorpseSkull:SetVertexColor(1,1,1,math.min(1,baseAlpha+proximity*0.50))
    end
    local grindState = (not corpseMode and Navigator.GrindHUD and Navigator.GrindHUD.GetState) and Navigator.GrindHUD:GetState() or nil
    if db.hudShowETA and not grindState then
        if corpseMode then hudEtaText:SetText(distance < 30 and L("corpseNearby") or L("corpseRun")) else hudEtaText:SetText(FormatETA(distance / math.max(0.1, etaSpeed), approximate)) end
        hudEtaText:Show()
        if not db.hudShowDistance then hudEtaText:ClearAllPoints(); hudEtaText:SetPoint("TOP", hudArrowFrame, "TOP", 0, -(46 + 20 * (tonumber(db.hudSize) or 1)))
        else hudEtaText:ClearAllPoints(); hudEtaText:SetPoint("TOP", hudArrowFrame, "TOP", 0, -(69 + 20 * arrowScale)) end
    else
        hudEtaText:Hide()
    end

    if hudContextText then
        local hints = {}
        local element = GetCurrentNavigationElement()
        local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        if not corpseMode and db.showZoneHints then
            local zoneName = GetZoneTransitionHint(element, playerMapID)
            if zoneName then hints[#hints+1] = L("nextZone") .. ": " .. zoneName end
        end
        if not corpseMode and db.showTransportHints then
            local travel = DetectTransportHint(element)
            if travel then hints[#hints+1] = L("travel") .. ": " .. travel end
        end
        if corpseMode and db.showSpiritHealer then
            local healer = GetNearestSpiritHealerElement()
            local hm = healer and GetTargetMap(healer)
            if hm and playerMapID then
                local htx, hty, hc = GetTargetWorld(healer)
                local pwx, pwy, pc = GetPlayerWorld(playerMapID)
                if htx and hty and pwx and pwy and (not hc or not pc or hc == pc) then
                    local hd = WorldDistance(pwx,pwy,htx,hty)
                    if hd then hints[#hints+1] = L("spiritHealerLabel") .. ": " .. FormatHUDDistance(hd) end
                end
            end
        end
        if #hints > 0 then hudContextText:SetText(table.concat(hints, "  •  ")); hudContextText:Show() else hudContextText:Hide() end
    end
    UpdateGrindHUD(grindState)
    hudArrowFrame:Show()
end

local function RefreshAll()
    ApplyTheme()
    ResizeTargetMarker(targetDot, 0.82, db and db.minimapTargetSize)
    ResizeTargetMarker(worldTargetPin, 1.0, db and db.worldTargetSize)
    for _, pin in ipairs(worldFuturePins) do ResizeTargetMarker(pin, 1.0, db and db.worldTargetSize) end
    UpdateMinimapRoute()
    UpdateWorldMapRoute()
    UpdateHUDArrow(0)
    if Navigator.MinimapButton and Navigator.MinimapButton.Update then Navigator.MinimapButton:Update() end
    if Navigator.Options and Navigator.Options.Refresh then Navigator.Options:Refresh() end
end

-- Optional RestedXP V2 message bridge. RestedXP 4.11.15 broadcasts these
-- through AceEvent messages. Navigator listens when AceEvent is available, but
-- keeps the existing polling path as a fallback so an RXP internal rename or an
-- older build cannot break navigation.
Navigator.rxpEventBridgeReady = false

-- RestedXP event bridge moved to Core\RXPBridge.lua in beta37.


-- Diagnostics implementation moved to Debug\Diagnostics.lua in beta37.

-- Options UI moved to UI\Options.lua

-- RestedXP waypoint-engine compatibility moved to Core\RXPBridge.lua.

-- ---------------------------------------------------------------------------
-- Beta 5 diagnostics: SAFE RestedXP Step Inspector
-- Uses only rawget/next for foreign tables to avoid RestedXP metamethod loops.
-- Read-only: never mutates RestedXP state or navigation.
-- ---------------------------------------------------------------------------
-- Inspector implementation moved to Debug\Inspector.lua in beta37.

-- Cross-file API -------------------------------------------------------------
-- Modules loaded after the core file use these narrow accessors instead of
-- reaching into core lexical locals. This keeps modules independent and
-- prevents the main Lua chunk from growing back toward WoW's 200-local limit.
Navigator.API = Navigator.API or {}
function Navigator.API:GetDB() return db end
function Navigator.API:GetVersion() return ADDON_VERSION end
function Navigator.API:BeginInspectorCapture(label) if Navigator.Debug and Navigator.Debug.BeginCapture then Navigator.Debug:BeginCapture(label) end end
function Navigator.API:EndInspectorCapture() if Navigator.Debug and Navigator.Debug.EndCapture then Navigator.Debug:EndCapture() end end
function Navigator.API:GetInspectorExportText() return Navigator.Debug and Navigator.Debug.GetExportText and Navigator.Debug:GetExportText() or "" end
function Navigator.API:ShowInspectorExport() if Navigator.Debug and Navigator.Debug.ShowExport then Navigator.Debug:ShowExport() end end
function Navigator.API:GetCurrentNavigationElement() return GetCurrentNavigationElement() end
function Navigator.API:ResolveActiveGuideAndStep() return ResolveActiveGuideAndStep() end
function Navigator.API:GetSelectedFutureTargets(maxFuture, current) return GetSelectedFutureTargets(maxFuture, current) end
function Navigator.API:GetDisplayedMapID() return GetDisplayedMapID() end
function Navigator.API:ResolvePlayerMapAndPosition(preferredMapID) return ResolvePlayerMapAndPosition(preferredMapID) end
function Navigator.API:IsCorpseRunMode() return IsCorpseRunMode() end
function Navigator.API:GetTargetWorld(element) return GetTargetWorld(element) end
function Navigator.API:GetWorldPosForMap(mapID, x, y) return GetWorldPosForMap(mapID, x, y) end
function Navigator.API:GetThemeName() local theme = GetTheme(); return theme and theme.name or "?" end
function Navigator.API:GetCorpseNavigationElement() return GetCorpseNavigationElement() end
function Navigator.API:GetTargetMap(element) return GetTargetMap(element) end
function Navigator.API:GetNavigationTargets(maxFuture) return GetNavigationTargets(maxFuture) end
function Navigator.API:GetTargetInstruction(element) return GetTargetInstruction(element) end
function Navigator.API:GetNormalizedRXPData(element) return Navigator.RXPData and Navigator.RXPData.Normalize and Navigator.RXPData:Normalize(element) or nil end
function Navigator.API:DetectStepType(element) return DetectStepType(element) end
function Navigator.API:GetStepTypeDisplayName(stepType) return GetStepTypeDisplayName(stepType) end
function Navigator.API:GetStepIcon(stepType) return STEP_ICONS and STEP_ICONS[stepType] or nil end
function Navigator.API:GetQuestObjectiveText(element) return GetQuestObjectiveText(element) end
function Navigator.API:GetTransportHint(element) return DetectTransportHint(element) end
function Navigator.API:GetTargetStepLabel(element) return GetTargetStepLabel(element) end
function Navigator.API:GetTargetLabel(element, ordinal) return GetTargetLabel(element, ordinal) end
function Navigator.API:ShowElementTooltip(owner, element, context)
    if Navigator.TooltipEngine and Navigator.TooltipEngine.ShowElement then
        return Navigator.TooltipEngine:ShowElement(owner, element, context)
    end
    if not owner or not element or not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    local stepType = DetectStepType(element)
    if stepType then
        local texture = STEP_ICONS[stepType]
        local typeName = GetStepTypeDisplayName(stepType)
        local icon = texture and ("|T" .. texture .. ":14:14:0:0|t ") or ""
        GameTooltip:AddLine(icon .. typeName, 0.95, 0.76, 0.22)
    end
    local instruction = GetTargetInstruction(element)
    if instruction and instruction ~= "" then GameTooltip:AddLine(instruction, 1, 1, 1, true) end
    AddTargetMetadataToTooltip(element)
    GameTooltip:Show()
end
function Navigator.API:ShowClusterTooltip(owner, members, fallbackElement, fallbackOrdinal)
    if Navigator.TooltipEngine and Navigator.TooltipEngine.ShowCluster then
        return Navigator.TooltipEngine:ShowCluster(owner, members, fallbackElement, fallbackOrdinal)
    end
    return self:ShowElementTooltip(owner, fallbackElement, { ordinal = fallbackOrdinal })
end

function Navigator.API:GetMinimapFuturePoint(element, playerMapID, px, py, halfW, halfH, viewRadius, markerSize, rotating, allowOffscreen)
    if not element or not playerMapID or not px or not py or not viewRadius or viewRadius <= 0 then return nil end
    local targetMapID, tx, ty = GetTargetMap(element)
    if not targetMapID then return nil end

    local dx, dy
    local localTX, localTY = PositionInDisplayedMap(targetMapID, tx, ty, playerMapID)
    if localTX and localTY then dx, dy = localTX - px, localTY - py end

    local twx, twy, tcontinent = GetTargetWorld(element)
    local pwx, pwy, pcontinent
    if not dx and twx and twy then
        dx, dy, pwx, pwy, pcontinent = GetWorldVectorInPlayerMap(playerMapID, px, py, twx, twy)
    end
    if not dx or not dy then return nil end

    -- Never reject a nearby future target merely because Forever exposes a
    -- different world-space id for a neighbouring zone/submap. The Blizzard
    -- UI-map hierarchy is authoritative for continent membership.
    local playerContinentMapID = ResolveContinentMapID(playerMapID)
    local targetContinentMapID = ResolveContinentMapID(targetMapID)
    if playerContinentMapID and targetContinentMapID and playerContinentMapID ~= targetContinentMapID then
        return nil
    end

    local bearing = math.atan2(-dx, -dy)
    if bearing < 0 then bearing = bearing + PI2 end
    local relativeBearing = bearing
    if rotating and GetPlayerFacing then
        local facing = GetPlayerFacing()
        if type(facing) == "number" then relativeBearing = NormalizeAngle(bearing - facing) end
    end
    local vx, vy = -math.sin(relativeBearing), math.cos(relativeBearing)

    -- Prefer real world distance when both points share a world space. If they
    -- do not, derive an approximate local-map distance from Blizzard's map basis.
    if not twx then twx, twy, tcontinent = GetTargetWorld(element) end
    if not pwx then pwx, pwy, pcontinent = GetPlayerWorld(playerMapID) end
    local distance
    if twx and twy and pwx and pwy and (not tcontinent or not pcontinent or tcontinent == pcontinent) then
        distance = WorldDistance(pwx, pwy, twx, twy)
    end
    if not distance then
        local eps = 0.001
        local ewx, ewy, ec = GetWorldPosForMap(playerMapID, math.min(0.999, px + eps), py)
        local swx, swy, sc = GetWorldPosForMap(playerMapID, px, math.min(0.999, py + eps))
        local bx, by, bc = GetWorldPosForMap(playerMapID, px, py)
        if bx and by and ewx and ewy and swx and swy and ec == bc and sc == bc then
            local ux, uy = (ewx - bx) / eps, (ewy - by) / eps
            local vxw, vyw = (swx - bx) / eps, (swy - by) / eps
            local wx = ux * dx + vxw * dy
            local wy = uy * dx + vyw * dy
            distance = math.sqrt(wx * wx + wy * wy)
        end
    end
    if not distance then return nil end
    local offscreen = distance > viewRadius
    if offscreen and not allowOffscreen then return nil end

    local radius = math.max(4, ((tonumber(markerSize) or 14) * 0.45) / 2 + 2)
    local edgeRadiusX = math.max(8, (tonumber(halfW) or 70) - radius - 3)
    local edgeRadiusY = math.max(8, (tonumber(halfH) or 70) - radius - 3)
    local scaleToEdge = 1 / math.sqrt((vx * vx) / (edgeRadiusX * edgeRadiusX) + (vy * vy) / (edgeRadiusY * edgeRadiusY))
    local pixelDistance = math.max(0, math.min(1, distance / viewRadius))
    return vx * scaleToEdge * pixelDistance, vy * scaleToEdge * pixelDistance, distance, offscreen
end
function Navigator.API:ResolveActiveGuideAndStep() return ResolveActiveGuideAndStep() end
function Navigator.API:PositionInDisplayedMap(...) return PositionInDisplayedMap(...) end
function Navigator.API:SetNativeWorldLine(...) return SetNativeWorldLine(...) end
function Navigator.API:LowerClean(value) return LowerClean(value) end
function Navigator.API:GetWorldMapCanvas() return GetWorldMapCanvas() end
function Navigator.API:RefreshAll() return RefreshAll() end
function Navigator.API:Translate(key) return L(key) end
function Navigator.API:ApplyHUDPosition() return ApplyHUDPosition() end
function Navigator.API:PrintMapDiagnostics(captureOnly) if Navigator.Diagnostics and Navigator.Diagnostics.PrintMapDiagnostics then return Navigator.Diagnostics:PrintMapDiagnostics(captureOnly) end end
function Navigator.API:GenerateBugReport() if Navigator.Diagnostics and Navigator.Diagnostics.GenerateBugReport then return Navigator.Diagnostics:GenerateBugReport() end end
function Navigator.API:GetRXPGuidesAddon() return GetRXPGuidesAddon() end
function Navigator.API:GetDefaults() return defaults end
function Navigator.API:Print(message) return Print(message) end
function Navigator.API:HasTheme(key) return THEMES[key] ~= nil end

SLASH_RXPNAV1 = "/rxpnav"
SlashCmdList.RXPNAV = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "on" then db.enabled = true; RefreshAll(); Print("aktiviert")
    elseif msg == "off" then db.enabled = false; HideMinimapRoute(); HideWorldRoute(); HideHUDArrow(); Print("deaktiviert")
    elseif msg == "toggle" then db.enabled = not db.enabled; if db.enabled then RefreshAll() else HideMinimapRoute(); HideWorldRoute(); HideHUDArrow() end; Print("Navigator: " .. (db.enabled and "an" or "aus"))
    elseif msg == "distance" then db.showDistance = not db.showDistance; RefreshAll(); Print("Distanzanzeige " .. (db.showDistance and "an" or "aus"))
    elseif msg == "map" then db.showWorldMap = not db.showWorldMap; RefreshAll(); Print("Weltkarten-Linie " .. (db.showWorldMap and "an" or "aus"))
    elseif msg == "options" or msg == "config" then if Navigator.Options and Navigator.Options.Open then Navigator.Options:Open() else Print("Options module not loaded") end
    elseif msg == "animation" then db.animation = not db.animation; RefreshAll(); Print("Animation " .. (db.animation and "an" or "aus"))
    elseif msg == "arrow" then db.showHUDArrow = not db.showHUDArrow; RefreshAll(); Print("Navigationspfeil " .. (db.showHUDArrow and "an" or "aus"))
    elseif msg == "hudlock" then db.hudLocked = not db.hudLocked; RefreshAll(); Print("Pfeilposition gesperrt: " .. tostring(db.hudLocked))
    elseif msg == "width thin" then db.lineStyle = "thin"; RefreshAll(); Print("Linienstärke: Dünn")
    elseif msg == "width normal" then db.lineStyle = "normal"; RefreshAll(); Print("Linienstärke: Normal")
    elseif msg == "width strong" then db.lineStyle = "strong"; RefreshAll(); Print("Linienstärke: Kräftig")
    elseif msg:match("^goals%s+[0-6]$") then local n=tonumber(msg:match("(%d)$")); db.futureGoals=n; RefreshAll(); Print("Folgeziele: " .. (n==0 and "aus" or ("+"..n)))
    elseif msg == "maptest" then if Navigator.Diagnostics then Navigator.Diagnostics:PrintMapDiagnostics(true); Navigator.API:ShowInspectorExport() end
    elseif msg == "bugreport" then if Navigator.Diagnostics then Navigator.Diagnostics:GenerateBugReport() end
    elseif msg == "future 0" then db.futureGoals = 0; RefreshAll(); Print("Folgeziele: aus")
    elseif msg == "future 1" then db.futureGoals = 1; RefreshAll(); Print("Folgeziele: +1")
    elseif msg == "future 2" then db.futureGoals = 2; RefreshAll(); Print("Folgeziele: +2")
    elseif msg == "future 3" then db.futureGoals = 3; RefreshAll(); Print("Folgeziele: +3")
    elseif msg == "future 4" then db.futureGoals = 4; RefreshAll(); Print("Folgeziele: +4")
    elseif msg == "future 5" then db.futureGoals = 5; RefreshAll(); Print("Folgeziele: +5")
    elseif msg == "future 6" then db.futureGoals = 6; RefreshAll(); Print("Folgeziele: +6")
    elseif msg == "deathstatus" then if Navigator.Diagnostics then Navigator.Diagnostics:DeathStatus() end
    elseif msg == "guideinspect" then Navigator.Inspector.TargetedGuideInspect()
    elseif msg == "futureguide" then Navigator.Inspector.FutureGuideDebug()
    elseif msg == "renderfuture" then Navigator.Inspector.RenderFutureDebug()
    elseif msg == "inspectsteps" then Navigator.Inspector.SafeInspectSteps()
    elseif msg:match("^inspectstep%s+") then Navigator.Inspector.SafeInspectStep(msg:match("^inspectstep%s+(.+)$"))
    elseif msg == "inspectsave" then Navigator.Inspector.SafeInspectSave()
    elseif msg == "inspectcopy" then Navigator.Inspector.SafeInspectCopy()
    elseif msg == "reset" then
        RXPNavigatorDB = nil; CopyDefaults(); RefreshAll(); Print("Einstellungen zurückgesetzt")
    elseif msg == "" or msg == "status" then if Navigator.Diagnostics then Navigator.Diagnostics:Status() end
    else
        Print("/rxpnav status | toggle | goals 0-6 | maptest | bugreport | deathstatus | options | arrow | hudlock | future 0|1|2|3|4|5|6 | animation | distance | map | on | off | reset")
    end
end

Navigator:RegisterEvent("ADDON_LOADED")
Navigator:RegisterEvent("PLAYER_LOGIN")
Navigator:RegisterEvent("ZONE_CHANGED_NEW_AREA")
Navigator:RegisterEvent("ZONE_CHANGED")
Navigator:RegisterEvent("ZONE_CHANGED_INDOORS")
Navigator:RegisterEvent("PLAYER_ENTERING_WORLD")
Navigator:RegisterEvent("PLAYER_DEAD")
Navigator:RegisterEvent("PLAYER_ALIVE")
Navigator:RegisterEvent("PLAYER_UNGHOST")
Navigator:RegisterEvent("CORPSE_IN_RANGE")
Navigator:RegisterEvent("CORPSE_OUT_OF_RANGE")
Navigator:RegisterEvent("PLAYER_LOGOUT")
Navigator:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        CopyDefaults()
    elseif event == "PLAYER_LOGIN" then
        if not db then CopyDefaults() end
        Navigator.RXPBridge:EnsureWaypointEngine()
        Navigator.RXPBridge:SetupEventBridge()
        if not overlay then BuildMinimapOverlay() end
        BuildHUDArrow()
        EnsureWorldMapOverlay()
        if Navigator.Options and Navigator.Options.Build then Navigator.Options:Build() end
        if Navigator.MinimapButton and Navigator.MinimapButton.Update then Navigator.MinimapButton:Update() end
        RefreshAll()
        Print(L("loaded") .. " (v" .. ADDON_VERSION .. " RestedXP-Navigator). /rxpnav options")
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST"
        or event == "CORPSE_IN_RANGE" or event == "CORPSE_OUT_OF_RANGE" then
        Navigator.RXPBridge:EnsureWaypointEngine()
        Navigator.RXPData:Invalidate()
        RefreshAll()
    elseif event == "PLAYER_LOGOUT" then
        Navigator.RXPBridge:RestoreArrowSetting()
    end
end)

Navigator:SetScript("OnUpdate", function(self, dt)
    if not overlay or not db then return end
    self._rxpEnsure = (self._rxpEnsure or 0) + dt
    if self._rxpEnsure >= 0.5 then
        self._rxpEnsure = 0
        Navigator.RXPBridge:EnsureWaypointEngine()
        if not Navigator.rxpEventBridgeReady then Navigator.RXPBridge:SetupEventBridge() end
    end
    if self._rxpEventRefreshPending then
        self._rxpEventRefreshPending = nil
        RefreshAll()
    end
    elapsed = elapsed + dt
    if elapsed >= UPDATE_INTERVAL then elapsed = 0; UpdateMinimapRoute() end
    mapElapsed = mapElapsed + dt
    if mapElapsed >= MAP_UPDATE_INTERVAL then mapElapsed = 0; UpdateWorldMapRoute() end
    hudElapsed = hudElapsed + dt
    if hudElapsed >= 0.05 then hudElapsed = 0; UpdateHUDArrow(dt) end
end)
