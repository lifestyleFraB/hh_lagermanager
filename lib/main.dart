import 'dart:convert';
// Nutzt die Web-Schnittstelle von Dart für den echten Datei-Download im Browser
// ignore: undefined_shown_name
import 'dart:html' as html;
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const ProfiKlimaLagerApp());
}

// --- ERMÖGLICHT DAS WISCHEN AUF SMARTPHONES & NAVIGATION PER MAUS/TRACKPAD ---
class WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind
        .touch, // Aktiviert das Wischen mit dem Finger auf Mobilgeräten
    PointerDeviceKind.mouse, // Erlaubt normales Klicken/Ziehen mit der Maus
    PointerDeviceKind.trackpad, // Unterstützt Laptop-Trackpads
    PointerDeviceKind.stylus, // Unterstützt Eingabestifte
  };
}

class ProfiKlimaLagerApp extends StatelessWidget {
  const ProfiKlimaLagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SKAYO Lager",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005B94),
          brightness: Brightness.light,
        ),
      ),
      scrollBehavior: WebScrollBehavior(), // Hier global für die App aktiviert
      home: const HauptLagerDashboard(),
    );
  }
}

// Datenmodell für Lagerorte
class LagerZone {
  String id;
  String name;
  IconData icon;
  String? imageUrl;

  LagerZone({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'imageUrl': imageUrl,
  };

  factory LagerZone.fromJson(Map<String, dynamic> json) => LagerZone(
    id: json['id'],
    name: json['name'],
    icon: IconData(json['icon'] ?? 58746, fontFamily: 'MaterialIcons'),
    imageUrl: json['imageUrl'],
  );
}

// Datenmodell für Artikel
class LagerArtikel {
  String id;
  String name;
  String kategorie;
  String spezifikation;
  String zoneId;
  String genauesRegal;
  int istBestand;
  int mindestBestand;

  LagerArtikel({
    required this.id,
    required this.name,
    required this.kategorie,
    required this.spezifikation,
    required this.zoneId,
    required this.genauesRegal,
    required this.istBestand,
    required this.mindestBestand,
  });

  bool get brauchtNachbestellung => istBestand <= mindestBestand;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kategorie': kategorie,
    'spezifikation': spezifikation,
    'zoneId': zoneId,
    'genauesRegal': genauesRegal,
    'istBestand': istBestand,
    'mindestBestand': mindestBestand,
  };

  factory LagerArtikel.fromJson(Map<String, dynamic> json) => LagerArtikel(
    id: json['id'] ?? '',
    name: json['name'] ?? json['kategorie'] ?? '',
    kategorie: json['kategorie'] ?? '',
    spezifikation: json['spezifikation'] ?? '',
    zoneId: json['zoneId'] ?? '',
    genauesRegal: json['genauesRegal'] ?? '',
    istBestand: json['istBestand'] ?? 0,
    mindestBestand: json['mindestBestand'] ?? 0,
  );
}

class HauptLagerDashboard extends StatefulWidget {
  const HauptLagerDashboard({super.key});

  @override
  State<HauptLagerDashboard> createState() => _HauptLagerDashboardState();
}

class _HauptLagerDashboardState extends State<HauptLagerDashboard> {
  final List<LagerZone> _zonen = [
    LagerZone(id: "all_zones", name: "Alle Orte", icon: Icons.map),
    LagerZone(
      id: "h1",
      name: "Haupthalle 1",
      icon: Icons.store,
      imageUrl:
          "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=150",
    ),
    LagerZone(id: "h2", name: "Kleinteile-Raum", icon: Icons.meeting_room),
    LagerZone(id: "c1", name: "Material-Container A", icon: Icons.factory),
    LagerZone(
      id: "w1",
      name: "Werkstattwagen Bus 1",
      icon: Icons.local_shipping,
    ),
  ];

  final List<String> _kategorien = [
    "Alle",
    "Großgeräte (Klima/WP)",
    "Kanal- & Luftführung",
    "Filtertechnik",
    "Kältetechnik & Chemie",
  ];

  late List<LagerArtikel> _inventar;
  String _aktiveKategorie = "Alle";
  String _aktiveZoneId = "all_zones";
  LagerArtikel? _gewaehlterArtikel;

  @override
  void initState() {
    super.initState();
    _inventar = [
      LagerArtikel(
        id: "DEV-WP-09",
        name: "Monoblock Wärmepumpe 9kW",
        kategorie: "Großgeräte (Klima/WP)",
        spezifikation: "R32",
        zoneId: "h1",
        genauesRegal: "Nordwand",
        istBestand: 2,
        mindestBestand: 1,
      ),
      LagerArtikel(
        id: "FIL-ISO-01",
        name: "Taschenfilter ePM1",
        kategorie: "Filtertechnik",
        spezifikation: "592x592x360",
        zoneId: "h2",
        genauesRegal: "Regal 1",
        istBestand: 4,
        mindestBestand: 5,
      ),
    ];
  }

  // ECHTER DATEI-DOWNLOAD (Erzeugt lager_backup.json im Browser-Download)
  void _loeseDateiDownloadAus() {
    final exportData = {
      'zonen': _zonen.map((z) => z.toJson()).toList(),
      'kategorien': _kategorien,
      'inventar': _inventar.map((i) => i.toJson()).toList(),
    };

    final jsonString = jsonEncode(exportData);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "lager_backup.json")
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ lager_backup.json wurde heruntergeladen!"),
      ),
    );
  }

  // UPLOAD-DIALOG (Korrigiert ohne den fehlerhaften options-Parameter)
  void _zeigeUploadDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("JSON-Backup importieren"),
        content: TextField(
          controller: textController,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Füge hier den Inhalt deiner JSON-Datei ein...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                try {
                  final importData = jsonDecode(textController.text);
                  setState(() {
                    _kategorien.clear();
                    _kategorien.addAll(
                      List<String>.from(importData['kategorien']),
                    );
                    _zonen.clear();
                    _zonen.addAll(
                      (importData['zonen'] as List)
                          .map((z) => LagerZone.fromJson(z))
                          .toList(),
                    );
                    _inventar.clear();
                    _inventar.addAll(
                      (importData['inventar'] as List)
                          .map((i) => LagerArtikel.fromJson(i))
                          .toList(),
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Daten erfolgreich importiert!"),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fehler: Ungültiges JSON.")),
                  );
                }
              }
            },
            child: const Text("Importieren"),
          ),
        ],
      ),
    );
  }

  void _zeigeOrtEditierenDialog(LagerZone zone) {
    final nameController = TextEditingController(text: zone.name);
    final imgController = TextEditingController(text: zone.imageUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${zone.name} bearbeiten"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name des Ortes"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: imgController,
              decoration: const InputDecoration(
                labelText: "Bild-URL (Optional)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                zone.name = nameController.text;
                zone.imageUrl = imgController.text.isEmpty
                    ? null
                    : imgController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  void _zeigeKategorieEditierenDialog(String alteKat, int index) {
    final controller = TextEditingController(text: alteKat);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kategorie umbenennen"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _kategorien[index] = controller.text;
                for (var artikel in _inventar) {
                  if (artikel.kategorie == alteKat) {
                    artikel.kategorie = controller.text;
                  }
                }
                if (_aktiveKategorie == alteKat) {
                  _aktiveKategorie = controller.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  void _zeigeArtikelBearbeitenDialog(LagerArtikel artikel) {
    final nameController = TextEditingController(text: artikel.name);
    final regalController = TextEditingController(text: artikel.genauesRegal);
    final bestandController = TextEditingController(
      text: artikel.istBestand.toString(),
    );
    String gewaehlteZoneId = artikel.zoneId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("${artikel.name} bearbeiten"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Artikelname"),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gewaehlteZoneId,
                  decoration: const InputDecoration(
                    labelText: "Lagerort / Zone",
                    border: OutlineInputBorder(),
                  ),
                  items: _zonen
                      .where((z) => z.id != "all_zones")
                      .map(
                        (zone) => DropdownMenuItem(
                          value: zone.id,
                          child: Text(zone.name),
                        ),
                      )
                      .toList(),
                  onChanged: (neuZoneId) {
                    if (neuZoneId != null) {
                      setDialogState(() {
                        gewaehlteZoneId = neuZoneId;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regalController,
                  decoration: const InputDecoration(
                    labelText: "Genaues Regal / Position",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bestandController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Bestand (Stück)",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  artikel.name = nameController.text;
                  artikel.zoneId = gewaehlteZoneId;
                  artikel.genauesRegal = regalController.text;
                  artikel.istBestand =
                      int.tryParse(bestandController.text) ??
                      artikel.istBestand;

                  if (_gewaehlterArtikel?.id == artikel.id) {
                    _gewaehlterArtikel = artikel;
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "✓ ${artikel.name} aktualisiert und zugewiesen.",
                    ),
                  ),
                );
              },
              child: const Text("Speichern"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final istMobil = screenWidth < 900;

    final gefiltertesInventar = _inventar.where((artikel) {
      final passtKategorie =
          _aktiveKategorie == "Alle" || artikel.kategorie == _aktiveKategorie;
      final passtZone =
          _aktiveZoneId == "all_zones" || artikel.zoneId == _aktiveZoneId;
      return passtKategorie && passtZone;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text(
          "SKAYO Lager",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: "Artikel +",
            onPressed: _zeigeArtikelErstellenDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "JSON Herunterladen",
            onPressed: _loeseDateiDownloadAus,
          ),
          PopupMenuButton<String>(
            tooltip: "Mehr Optionen",
            // --- HIER WURDEN DIE AKTIONEN FÜR ORT & KATEGORIE AKTIVIERT ---
            onSelected: (wert) {
              switch (wert) {
                case 'upload':
                  _zeigeUploadDialog();
                  break;
                case 'ort':
                  _zeigeOrtErstellenDialog();
                  break;
                case 'kategorie':
                  _zeigeKategorieErstellenDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'upload',
                child: Row(
                  children: [
                    Icon(Icons.upload, size: 20),
                    SizedBox(width: 10),
                    Text("JSON Hochladen"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'ort',
                child: Row(
                  children: [
                    Icon(Icons.add_location, size: 20),
                    SizedBox(width: 10),
                    Text("Ort hinzufügen"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'kategorie',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, size: 20),
                    SizedBox(width: 10),
                    Text("Kategorie hinzufügen"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _zonen.indexWhere((z) => z.id == _aktiveZoneId),
            onDestinationSelected: (index) =>
                setState(() => _aktiveZoneId = _zonen[index].id),
            labelType: NavigationRailLabelType.all,
            destinations: _zonen.map((z) {
              return NavigationRailDestination(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    z.imageUrl != null
                        ? CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(z.imageUrl!),
                          )
                        : Icon(z.icon),
                    if (z.id != "all_zones")
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.grey,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => _zeigeOrtEditierenDialog(z),
                      ),
                  ],
                ),
                label: Text(z.name, style: const TextStyle(fontSize: 10)),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _kategorien.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final kat = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onDoubleTap: kat == "Alle"
                                ? null
                                : () =>
                                      _zeigeKategorieEditierenDialog(kat, idx),
                            child: ChoiceChip(
                              label: Text(kat + (kat == "Alle" ? "" : " ✏️")),
                              selected: _aktiveKategorie == kat,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _aktiveKategorie = kat);
                                }
                              },
                              elevation: _aktiveKategorie == kat ? 2 : 0,
                              pressElevation: 4,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: gefiltertesInventar.isEmpty
                      ? const Center(child: Text("Keine Artikel."))
                      : ListView.builder(
                          itemCount: gefiltertesInventar.length,
                          itemBuilder: (context, index) {
                            final artikel = gefiltertesInventar[index];
                            final zoneDesArtikels = _zonen.firstWhere(
                              (z) => z.id == artikel.zoneId,
                              orElse: () => _zonen.first,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: artikel.brauchtNachbestellung
                                    ? Colors.red.shade100
                                    : Colors.blue.shade50,
                                child: Icon(
                                  artikel.brauchtNachbestellung
                                      ? Icons.report_problem
                                      : Icons.widgets,
                                  color: artikel.brauchtNachbestellung
                                      ? Colors.red
                                      : Colors.blue.shade700,
                                ),
                              ),
                              title: Text(
                                artikel.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${zoneDesArtikels.name} -> ${artikel.genauesRegal}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${artikel.istBestand} Stk.  ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_note,
                                      color: Colors.blueGrey,
                                    ),
                                    tooltip: "Artikel bearbeiten / verschieben",
                                    onPressed: () =>
                                        _zeigeArtikelBearbeitenDialog(artikel),
                                  ),
                                ],
                              ),
                              selected: _gewaehlterArtikel?.id == artikel.id,
                              onTap: () {
                                setState(() {
                                  _gewaehlterArtikel = artikel;
                                });
                                if (istMobil) {
                                  _zeigeMobileDetailAnsicht(context);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (!istMobil) ...[
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2,
              child: _gewaehlterArtikel == null
                  ? const Center(child: Text("Wähle einen Artikel."))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _baueDetailInhalt(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  void _zeigeMobileDetailAnsicht(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: _baueDetailInhalt(),
      ),
    );
  }

  Widget _baueDetailInhalt() {
    if (_gewaehlterArtikel == null) return const SizedBox.shrink();
    final aktuelleZone = _zonen.firstWhere(
      (z) => z.id == _gewaehlterArtikel!.zoneId,
      orElse: () => _zonen.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _gewaehlterArtikel!.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _gewaehlterArtikel!.kategorie,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const Divider(height: 24),
        Text(
          "Aktueller Ort: ${aktuelleZone.name}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          "Position/Regal: ${_gewaehlterArtikel!.genauesRegal}",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "Spezifikation: ${_gewaehlterArtikel!.spezifikation}",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "Aktueller Bestand: ${_gewaehlterArtikel!.istBestand} Stk.",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "Mindestbestand: ${_gewaehlterArtikel!.mindestBestand} Stk.",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        if (_gewaehlterArtikel!.brauchtNachbestellung) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "Nachbestellung erforderlich!",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- ERSTELLEN-DIALOGE ---

  void _zeigeArtikelErstellenDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final spezifikationController = TextEditingController();
    final regalController = TextEditingController();
    final istBestandController = TextEditingController(text: "0");
    final mindestBestandController = TextEditingController(text: "0");

    String gewaehlteKategorie = _kategorien.firstWhere(
      (k) => k != "Alle",
      orElse: () => "",
    );
    String gewaehlteZoneId = _zonen
        .firstWhere((z) => z.id != "all_zones", orElse: () => _zonen.first)
        .id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Neuen Artikel anlegen"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: "Artikelnummer / ID (z.B. FIL-ISO-02)",
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Artikelname"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gewaehlteKategorie,
                  decoration: const InputDecoration(
                    labelText: "Kategorie",
                    border: OutlineInputBorder(),
                  ),
                  items: _kategorien
                      .where((k) => k != "Alle")
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (wert) =>
                      setDialogState(() => gewaehlteKategorie = wert!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gewaehlteZoneId,
                  decoration: const InputDecoration(
                    labelText: "Lagerort / Zone",
                    border: OutlineInputBorder(),
                  ),
                  items: _zonen
                      .where((z) => z.id != "all_zones")
                      .map(
                        (z) =>
                            DropdownMenuItem(value: z.id, child: Text(z.name)),
                      )
                      .toList(),
                  onChanged: (wert) =>
                      setDialogState(() => gewaehlteZoneId = wert!),
                ),
                TextField(
                  controller: spezifikationController,
                  decoration: const InputDecoration(
                    labelText: "Spezifikation / Maße",
                  ),
                ),
                TextField(
                  controller: regalController,
                  decoration: const InputDecoration(
                    labelText: "Genaues Regal / Position",
                  ),
                ),
                TextField(
                  controller: istBestandController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Aktueller Bestand",
                  ),
                ),
                TextField(
                  controller: mindestBestandController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Mindestbestand",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () {
                if (idController.text.isNotEmpty &&
                    nameController.text.isNotEmpty) {
                  setState(() {
                    _inventar.add(
                      LagerArtikel(
                        id: idController.text,
                        name: nameController.text,
                        kategorie: gewaehlteKategorie,
                        spezifikation: spezifikationController.text,
                        zoneId: gewaehlteZoneId,
                        genauesRegal: regalController.text,
                        istBestand:
                            int.tryParse(istBestandController.text) ?? 0,
                        mindestBestand:
                            int.tryParse(mindestBestandController.text) ?? 0,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Hinzufügen"),
            ),
          ],
        ),
      ),
    );
  }

  void _zeigeOrtErstellenDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final imgController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Neuen Lagerort hinzufügen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: "Eindeutige ID (z.B. h3 oder c2)",
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name des Ortes (z.B. Halle 3)",
              ),
            ),
            TextField(
              controller: imgController,
              decoration: const InputDecoration(
                labelText: "Bild-URL (Optional)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                setState(() {
                  _zonen.add(
                    LagerZone(
                      id: idController.text,
                      name: nameController.text,
                      icon: Icons.warehouse,
                      imageUrl: imgController.text.isEmpty
                          ? null
                          : imgController.text,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Hinzufügen"),
          ),
        ],
      ),
    );
  }

  void _zeigeKategorieErstellenDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Neue Kategorie hinzufügen"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Name der Kategorie"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _kategorien.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Hinzufügen"),
          ),
        ],
      ),
    );
  }
}
