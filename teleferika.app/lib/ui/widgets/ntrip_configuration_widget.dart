import 'package:flutter/material.dart';
import 'package:teleferika/ble/ntrip_client.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/l10n/country_region_localizations.dart';
import 'package:teleferika/db/database.dart';
import 'package:teleferika/db/drift_database_helper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';

class NtripConfigurationWidget extends StatefulWidget {
  final NTRIPConnectionState connectionState;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController mountPointController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool useSsl;
  final bool isForwardingRtcm;
  /// When false, connect is disabled until position data is received from BLE (e.g. pulsing indicator gone).
  final bool canConnectNtrip;
  final ValueChanged<int?> onConnect; // Passes the selected host ID
  final VoidCallback onDisconnect;
  final ValueChanged<bool> onSslChanged;
  final int
  hostStatusRefreshTrigger; // Trigger to force refresh when host status changes

  const NtripConfigurationWidget({
    super.key,
    required this.connectionState,
    required this.hostController,
    required this.portController,
    required this.mountPointController,
    required this.usernameController,
    required this.passwordController,
    required this.useSsl,
    required this.isForwardingRtcm,
    this.canConnectNtrip = true,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSslChanged,
    this.hostStatusRefreshTrigger = 0,
  });

  @override
  State<NtripConfigurationWidget> createState() =>
      _NtripConfigurationWidgetState();
}

class _NtripConfigurationWidgetState extends State<NtripConfigurationWidget> {
  String? _selectedCountry;
  String? _selectedState;
  NtripSetting? _selectedHost;
  List<NtripSetting> _availableHosts = [];
  List<String> _countries = [];
  List<String> _states = [];
  bool _isLoading = false;
  bool _showAddHostForm = false;
  bool _isEditingHost = false;
  int? _editingHostId;
  String? _selectedCountryInForm;
  NTRIPConnectionState? _previousConnectionState;
  int _previousRefreshTrigger = 0;

  // Standard list of countries
  static const List<String> _standardCountries = [
    'Italy',
    'Austria',
    'Switzerland',
    'France',
    'Germany',
    'Spain',
    'United Kingdom',
    'Netherlands',
    'Belgium',
    'Portugal',
    'Greece',
    'Poland',
    'Czech Republic',
    'Hungary',
    'Romania',
    'Croatia',
    'Slovenia',
    'Slovakia',
    'Denmark',
    'Sweden',
    'Norway',
    'Finland',
    'Ireland',
    'United States',
    'Canada',
    'Australia',
    'New Zealand',
    'Japan',
    'South Korea',
    'China',
    'India',
    'Brazil',
    'Argentina',
    'Mexico',
    'South Africa',
  ];

  // Map of countries to their states/regions
  static const Map<String, List<String>> _countryStates = {
    'Italy': [
      'Abruzzo',
      'Basilicata',
      'Bolzano/Bozen',
      'Calabria',
      'Campania',
      'Emilia-Romagna',
      'Friuli-Venezia Giulia',
      'Lazio',
      'Liguria',
      'Lombardy',
      'Marche',
      'Molise',
      'Piedmont',
      'Puglia',
      'Sardinia',
      'Sicily',
      'Trentino',
      'Tuscany',
      'Umbria',
      'Valle d\'Aosta',
      'Veneto',
    ],
    'Austria': [
      'Burgenland',
      'Carinthia',
      'Lower Austria',
      'Salzburg',
      'Styria',
      'Tyrol',
      'Upper Austria',
      'Vienna',
      'Vorarlberg',
    ],
    'Switzerland': [
      'Aargau',
      'Appenzell Ausserrhoden',
      'Appenzell Innerrhoden',
      'Basel-Landschaft',
      'Basel-Stadt',
      'Bern',
      'Fribourg',
      'Geneva',
      'Glarus',
      'Grisons',
      'Jura',
      'Lucerne',
      'Neuchâtel',
      'Nidwalden',
      'Obwalden',
      'Schaffhausen',
      'Schwyz',
      'Solothurn',
      'St. Gallen',
      'Thurgau',
      'Ticino',
      'Uri',
      'Valais',
      'Vaud',
      'Zug',
      'Zürich',
    ],
    'France': [
      'Auvergne-Rhône-Alpes',
      'Bourgogne-Franche-Comté',
      'Brittany',
      'Centre-Val de Loire',
      'Corsica',
      'Grand Est',
      'Hauts-de-France',
      'Île-de-France',
      'Normandy',
      'Nouvelle-Aquitaine',
      'Occitanie',
      'Pays de la Loire',
      'Provence-Alpes-Côte d\'Azur',
    ],
    'Germany': [
      'Baden-Württemberg',
      'Bavaria',
      'Berlin',
      'Brandenburg',
      'Bremen',
      'Hamburg',
      'Hesse',
      'Lower Saxony',
      'Mecklenburg-Vorpommern',
      'North Rhine-Westphalia',
      'Rhineland-Palatinate',
      'Saarland',
      'Saxony',
      'Saxony-Anhalt',
      'Schleswig-Holstein',
      'Thuringia',
    ],
    'Spain': [
      'Andalusia',
      'Aragon',
      'Asturias',
      'Balearic Islands',
      'Basque Country',
      'Canary Islands',
      'Cantabria',
      'Castile and León',
      'Castile-La Mancha',
      'Catalonia',
      'Extremadura',
      'Galicia',
      'La Rioja',
      'Madrid',
      'Murcia',
      'Navarre',
      'Valencia',
    ],
    'United Kingdom': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
    'Netherlands': [
      'Drenthe',
      'Flevoland',
      'Friesland',
      'Gelderland',
      'Groningen',
      'Limburg',
      'North Brabant',
      'North Holland',
      'Overijssel',
      'South Holland',
      'Utrecht',
      'Zeeland',
    ],
    'Belgium': ['Brussels', 'Flanders', 'Wallonia'],
    'Portugal': [
      'Aveiro',
      'Beja',
      'Braga',
      'Bragança',
      'Castelo Branco',
      'Coimbra',
      'Évora',
      'Faro',
      'Guarda',
      'Leiria',
      'Lisbon',
      'Portalegre',
      'Porto',
      'Santarém',
      'Setúbal',
      'Viana do Castelo',
      'Vila Real',
      'Viseu',
    ],
    'Greece': [
      'Attica',
      'Central Greece',
      'Central Macedonia',
      'Crete',
      'East Macedonia and Thrace',
      'Epirus',
      'Ionian Islands',
      'North Aegean',
      'Peloponnese',
      'South Aegean',
      'Thessaly',
      'West Greece',
      'West Macedonia',
    ],
    'Poland': [
      'Greater Poland',
      'Kuyavian-Pomeranian',
      'Lesser Poland',
      'Łódź',
      'Lower Silesian',
      'Lublin',
      'Lubusz',
      'Masovian',
      'Opole',
      'Podlaskie',
      'Pomeranian',
      'Silesian',
      'Subcarpathian',
      'Świętokrzyskie',
      'Warmian-Masurian',
      'West Pomeranian',
    ],
    'Czech Republic': ['Bohemia', 'Moravia', 'Silesia'],
    'Hungary': [
      'Bács-Kiskun',
      'Baranya',
      'Békés',
      'Borsod-Abaúj-Zemplén',
      'Csongrád-Csanád',
      'Fejér',
      'Győr-Moson-Sopron',
      'Hajdú-Bihar',
      'Heves',
      'Jász-Nagykun-Szolnok',
      'Komárom-Esztergom',
      'Nógrád',
      'Pest',
      'Somogy',
      'Szabolcs-Szatmár-Bereg',
      'Tolna',
      'Vas',
      'Veszprém',
      'Zala',
    ],
    'Romania': [
      'Alba',
      'Arad',
      'Argeș',
      'Bacău',
      'Bihor',
      'Bistrița-Năsăud',
      'Botoșani',
      'Brașov',
      'Brăila',
      'Buzău',
      'Caraș-Severin',
      'Călărași',
      'Cluj',
      'Constanța',
      'Covasna',
      'Dâmbovița',
      'Dolj',
      'Galați',
      'Giurgiu',
      'Gorj',
      'Harghita',
      'Hunedoara',
      'Ialomița',
      'Iași',
      'Ilfov',
      'Maramureș',
      'Mehedinți',
      'Mureș',
      'Neamț',
      'Olt',
      'Prahova',
      'Sălaj',
      'Satu Mare',
      'Sibiu',
      'Suceava',
      'Teleorman',
      'Timiș',
      'Tulcea',
      'Vâlcea',
      'Vaslui',
      'Vrancea',
    ],
    'Croatia': [
      'Bjelovar-Bilogora',
      'Brod-Posavina',
      'Dubrovnik-Neretva',
      'Istria',
      'Karlovac',
      'Koprivnica-Križevci',
      'Krapina-Zagorje',
      'Lika-Senj',
      'Međimurje',
      'Osijek-Baranja',
      'Požega-Slavonia',
      'Primorje-Gorski Kotar',
      'Šibenik-Knin',
      'Sisak-Moslavina',
      'Split-Dalmatia',
      'Varaždin',
      'Virovitica-Podravina',
      'Vukovar-Srijem',
      'Zadar',
      'Zagreb',
      'Zagreb County',
    ],
    'Slovenia': [
      'Central Slovenia',
      'Coastal-Karst',
      'Drava',
      'Gorizia',
      'Lower Sava',
      'Mura',
      'Savinja',
      'Southeast Slovenia',
      'Upper Carniola',
    ],
    'Slovakia': [
      'Banská Bystrica',
      'Bratislava',
      'Košice',
      'Nitra',
      'Prešov',
      'Trenčín',
      'Trnava',
      'Žilina',
    ],
    'Denmark': [
      'Capital Region',
      'Central Denmark',
      'North Denmark',
      'Region Zealand',
      'South Denmark',
    ],
    'Sweden': [
      'Blekinge',
      'Dalarna',
      'Gävleborg',
      'Gotland',
      'Halland',
      'Jämtland',
      'Jönköping',
      'Kalmar',
      'Kronoberg',
      'Norrbotten',
      'Örebro',
      'Östergötland',
      'Skåne',
      'Södermanland',
      'Stockholm',
      'Uppsala',
      'Värmland',
      'Västerbotten',
      'Västernorrland',
      'Västmanland',
      'Västra Götaland',
    ],
    'Norway': [
      'Agder',
      'Innlandet',
      'Møre og Romsdal',
      'Nordland',
      'Oslo',
      'Rogaland',
      'Troms og Finnmark',
      'Trøndelag',
      'Vestfold og Telemark',
      'Vestland',
      'Viken',
    ],
    'Finland': [
      'Central Finland',
      'Central Ostrobothnia',
      'Kainuu',
      'Kymenlaakso',
      'Lapland',
      'North Karelia',
      'North Ostrobothnia',
      'North Savo',
      'Ostrobothnia',
      'Päijät-Häme',
      'Pirkanmaa',
      'Satakunta',
      'South Karelia',
      'South Ostrobothnia',
      'South Savo',
      'Southwest Finland',
      'Tavastia Proper',
      'Uusimaa',
    ],
    'Ireland': ['Connacht', 'Leinster', 'Munster', 'Ulster'],
    'United States': [
      'Alabama',
      'Alaska',
      'Arizona',
      'Arkansas',
      'California',
      'Colorado',
      'Connecticut',
      'Delaware',
      'Florida',
      'Georgia',
      'Hawaii',
      'Idaho',
      'Illinois',
      'Indiana',
      'Iowa',
      'Kansas',
      'Kentucky',
      'Louisiana',
      'Maine',
      'Maryland',
      'Massachusetts',
      'Michigan',
      'Minnesota',
      'Mississippi',
      'Missouri',
      'Montana',
      'Nebraska',
      'Nevada',
      'New Hampshire',
      'New Jersey',
      'New Mexico',
      'New York',
      'North Carolina',
      'North Dakota',
      'Ohio',
      'Oklahoma',
      'Oregon',
      'Pennsylvania',
      'Rhode Island',
      'South Carolina',
      'South Dakota',
      'Tennessee',
      'Texas',
      'Utah',
      'Vermont',
      'Virginia',
      'Washington',
      'West Virginia',
      'Wisconsin',
      'Wyoming',
    ],
    'Canada': [
      'Alberta',
      'British Columbia',
      'Manitoba',
      'New Brunswick',
      'Newfoundland and Labrador',
      'Northwest Territories',
      'Nova Scotia',
      'Nunavut',
      'Ontario',
      'Prince Edward Island',
      'Quebec',
      'Saskatchewan',
      'Yukon',
    ],
    'Australia': [
      'Australian Capital Territory',
      'New South Wales',
      'Northern Territory',
      'Queensland',
      'South Australia',
      'Tasmania',
      'Victoria',
      'Western Australia',
    ],
    'New Zealand': [
      'Auckland',
      'Bay of Plenty',
      'Canterbury',
      'Gisborne',
      'Hawke\'s Bay',
      'Manawatu-Wanganui',
      'Marlborough',
      'Nelson',
      'Northland',
      'Otago',
      'Southland',
      'Taranaki',
      'Tasman',
      'Waikato',
      'Wellington',
      'West Coast',
    ],
    'Japan': [
      'Aichi',
      'Akita',
      'Aomori',
      'Chiba',
      'Ehime',
      'Fukui',
      'Fukuoka',
      'Fukushima',
      'Gifu',
      'Gunma',
      'Hiroshima',
      'Hokkaido',
      'Hyogo',
      'Ibaraki',
      'Ishikawa',
      'Iwate',
      'Kagawa',
      'Kagoshima',
      'Kanagawa',
      'Kochi',
      'Kumamoto',
      'Kyoto',
      'Mie',
      'Miyagi',
      'Miyazaki',
      'Nagano',
      'Nagasaki',
      'Nara',
      'Niigata',
      'Oita',
      'Okayama',
      'Okinawa',
      'Osaka',
      'Saga',
      'Saitama',
      'Shiga',
      'Shimane',
      'Shizuoka',
      'Tochigi',
      'Tokushima',
      'Tokyo',
      'Tottori',
      'Toyama',
      'Wakayama',
      'Yamagata',
      'Yamaguchi',
      'Yamanashi',
    ],
    'South Korea': [
      'Busan',
      'Chungcheongbuk-do',
      'Chungcheongnam-do',
      'Daegu',
      'Daejeon',
      'Gangwon-do',
      'Gwangju',
      'Gyeonggi-do',
      'Gyeongsangbuk-do',
      'Gyeongsangnam-do',
      'Incheon',
      'Jeju-do',
      'Jeollabuk-do',
      'Jeollanam-do',
      'Sejong',
      'Seoul',
      'Ulsan',
    ],
    'China': [
      'Anhui',
      'Beijing',
      'Chongqing',
      'Fujian',
      'Gansu',
      'Guangdong',
      'Guangxi',
      'Guizhou',
      'Hainan',
      'Hebei',
      'Heilongjiang',
      'Henan',
      'Hong Kong',
      'Hubei',
      'Hunan',
      'Inner Mongolia',
      'Jiangsu',
      'Jiangxi',
      'Jilin',
      'Liaoning',
      'Macau',
      'Ningxia',
      'Qinghai',
      'Shaanxi',
      'Shandong',
      'Shanghai',
      'Shanxi',
      'Sichuan',
      'Tianjin',
      'Tibet',
      'Xinjiang',
      'Yunnan',
      'Zhejiang',
    ],
    'India': [
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chhattisgarh',
      'Goa',
      'Gujarat',
      'Haryana',
      'Himachal Pradesh',
      'Jharkhand',
      'Karnataka',
      'Kerala',
      'Madhya Pradesh',
      'Maharashtra',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Odisha',
      'Punjab',
      'Rajasthan',
      'Sikkim',
      'Tamil Nadu',
      'Telangana',
      'Tripura',
      'Uttar Pradesh',
      'Uttarakhand',
      'West Bengal',
    ],
    'Brazil': [
      'Acre',
      'Alagoas',
      'Amapá',
      'Amazonas',
      'Bahia',
      'Ceará',
      'Distrito Federal',
      'Espírito Santo',
      'Goiás',
      'Maranhão',
      'Mato Grosso',
      'Mato Grosso do Sul',
      'Minas Gerais',
      'Pará',
      'Paraíba',
      'Paraná',
      'Pernambuco',
      'Piauí',
      'Rio de Janeiro',
      'Rio Grande do Norte',
      'Rio Grande do Sul',
      'Rondônia',
      'Roraima',
      'Santa Catarina',
      'São Paulo',
      'Sergipe',
      'Tocantins',
    ],
    'Argentina': [
      'Buenos Aires',
      'Catamarca',
      'Chaco',
      'Chubut',
      'Córdoba',
      'Corrientes',
      'Entre Ríos',
      'Formosa',
      'Jujuy',
      'La Pampa',
      'La Rioja',
      'Mendoza',
      'Misiones',
      'Neuquén',
      'Río Negro',
      'Salta',
      'San Juan',
      'San Luis',
      'Santa Cruz',
      'Santa Fe',
      'Santiago del Estero',
      'Tierra del Fuego',
      'Tucumán',
    ],
    'Mexico': [
      'Aguascalientes',
      'Baja California',
      'Baja California Sur',
      'Campeche',
      'Chiapas',
      'Chihuahua',
      'Coahuila',
      'Colima',
      'Durango',
      'Guanajuato',
      'Guerrero',
      'Hidalgo',
      'Jalisco',
      'México',
      'Michoacán',
      'Morelos',
      'Nayarit',
      'Nuevo León',
      'Oaxaca',
      'Puebla',
      'Querétaro',
      'Quintana Roo',
      'San Luis Potosí',
      'Sinaloa',
      'Sonora',
      'Tabasco',
      'Tamaulipas',
      'Tlaxcala',
      'Veracruz',
      'Yucatán',
      'Zacatecas',
    ],
    'South Africa': [
      'Eastern Cape',
      'Free State',
      'Gauteng',
      'KwaZulu-Natal',
      'Limpopo',
      'Mpumalanga',
      'Northern Cape',
      'North West',
      'Western Cape',
    ],
  };

  static const String _lastSelectedCountryKey = 'ntrip_last_selected_country';
  static const String _countryHistoryKey = 'ntrip_country_history';

  // Form controllers for adding new host
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _mountPointController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _newHostUseSsl = false;

  @override
  void initState() {
    super.initState();
    _previousConnectionState = widget.connectionState;
    _previousRefreshTrigger = widget.hostStatusRefreshTrigger;
    _loadCountries();
    _initializeCountryDropdown();
  }

  @override
  void didUpdateWidget(NtripConfigurationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if refresh trigger changed (indicates host status was updated in DB)
    if (_previousRefreshTrigger != widget.hostStatusRefreshTrigger) {
      _refreshCurrentHostStatus();
      _previousRefreshTrigger = widget.hostStatusRefreshTrigger;
    }

    // Detect transition from connecting to connected (connection established, but RTCM not validated yet)
    if (_previousConnectionState == NTRIPConnectionState.connecting &&
        widget.connectionState == NTRIPConnectionState.connected) {
      // Connection established - but don't mark as successful yet, wait for RTCM validation
      // No refresh needed here, will refresh when RTCM is validated or error occurs
    }
    // Detect transition from connecting or connected to disconnected/error (failed connection)
    else if ((_previousConnectionState == NTRIPConnectionState.connecting ||
            _previousConnectionState == NTRIPConnectionState.connected) &&
        (widget.connectionState == NTRIPConnectionState.disconnected ||
            widget.connectionState == NTRIPConnectionState.error)) {
      // Connection failed - reload hosts to update the status immediately
      _refreshCurrentHostStatus();
    }

    _previousConnectionState = widget.connectionState;
  }

  Future<void> _refreshCurrentHostStatus() async {
    if (_selectedCountry == null || _selectedState == null) return;

    try {
      // Small delay to ensure database write has completed
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload hosts from database to get updated connection status
      final hosts = await DriftDatabaseHelper.instance
          .getNtripSettingsByCountryAndState(_selectedCountry!, _selectedState);

      // Update the available hosts list
      if (mounted) {
        setState(() {
          _availableHosts = hosts;

          // Update the selected host if it still exists
          if (_selectedHost != null) {
            final updatedHost = hosts.firstWhere(
              (h) => h.id == _selectedHost!.id,
              orElse: () => _selectedHost!,
            );
            _selectedHost = updatedHost;
          }
        });
      }
    } catch (e) {
      // Silently fail - don't show error for background refresh
    }
  }

  Future<void> _initializeCountryDropdown() async {
    final sorted = await _getSortedCountriesAsync();
    setState(() {
      _selectedCountryInForm = sorted.first; // First is last selected or Italy
      _countryController.text = sorted.first;
    });
  }

  Future<void> _saveCountrySelection(String country) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSelectedCountryKey, country);

      // Update history - keep last selected at top
      final historyString = prefs.getString(_countryHistoryKey);
      List<String> history = historyString != null
          ? historyString.split(',')
          : [];

      // Remove country if already in history
      history.remove(country);
      // Add to beginning
      history.insert(0, country);
      // Keep only last 10 countries in history
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }

      await prefs.setString(_countryHistoryKey, history.join(','));
    } catch (e) {
      // Ignore errors - preferences are not critical
    }
  }

  List<String> _getStatesForCountry(String country) {
    final states = _countryStates[country];
    if (states == null || states.isEmpty) {
      return []; // Return empty list if no states available
    }
    return states;
  }

  Future<List<String>> _getSortedCountriesAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_countryHistoryKey);
      final lastCountry = prefs.getString(_lastSelectedCountryKey);

      List<String> history = historyString != null && historyString.isNotEmpty
          ? historyString.split(',').where((c) => c.isNotEmpty).toList()
          : [];

      // Start with last selected country if available
      List<String> sorted = [];
      if (lastCountry != null && lastCountry.isNotEmpty) {
        sorted.add(lastCountry);
      } else if (history.isNotEmpty) {
        sorted.add(history.first);
      } else {
        sorted.add('Italy'); // Default
      }

      // Add other countries from history (excluding already added)
      for (final country in history) {
        if (!sorted.contains(country)) {
          sorted.add(country);
        }
      }

      // Add remaining standard countries alphabetically
      for (final country in _standardCountries) {
        if (!sorted.contains(country)) {
          sorted.add(country);
        }
      }

      return sorted;
    } catch (e) {
      // Return standard list with Italy first on error
      final sorted = ['Italy'];
      for (final country in _standardCountries) {
        if (country != 'Italy' && !sorted.contains(country)) {
          sorted.add(country);
        }
      }
      return sorted;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _mountPointController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoading = true);
    try {
      var allSettings = await DriftDatabaseHelper.instance
          .getAllNtripSettings();

      // If there are no hosts, insert the default one
      if (allSettings.isEmpty) {
        await _insertDefaultHost();
        // Reload after inserting default
        allSettings = await DriftDatabaseHelper.instance.getAllNtripSettings();
      }

      final countries = allSettings.map((s) => s.country).toSet().toList()
        ..sort();
      setState(() {
        _countries = countries;
      });
      if (countries.isNotEmpty && _selectedCountry == null) {
        // Select the country from the first record in the database
        final firstRecord = allSettings.first;
        _selectedCountry = firstRecord.country;
        // Pass the first record's state to loadStates so it can select it
        await _loadStates(firstRecord.state);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading countries: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _insertDefaultHost() async {
    try {
      final defaultSetting = NtripSettingCompanion(
        name: drift.Value('IMAX3'),
        country: drift.Value('Italy'),
        state: drift.Value('Trentino'),
        host: drift.Value('194.105.50.232'),
        port: drift.Value(2101),
        mountPoint: drift.Value('IMAX3'),
        username: drift.Value('TeleferiKa_2'),
        password: drift.Value('WqDS-n8r5p!r-Db'),
        useSsl: drift.Value(false),
      );
      await DriftDatabaseHelper.instance.insertNtripSetting(defaultSetting);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inserting default host: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  Future<void> _loadStates([String? preferredState]) async {
    if (_selectedCountry == null) return;
    setState(() => _isLoading = true);
    try {
      // Get states from the standard list for the selected country
      final standardStates = _getStatesForCountry(_selectedCountry!);

      // Also get states from existing hosts in database
      final hosts = await DriftDatabaseHelper.instance
          .getNtripSettingsByCountry(_selectedCountry!);
      final dbStates = hosts
          .map((s) => s.state)
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // Combine standard states with database states, remove duplicates
      final states = <String>{...standardStates, ...dbStates}.toList()..sort();

      // Select first state if none selected (prefer the state from first DB record)
      String? stateToSelect = _selectedState;
      if (states.isNotEmpty && stateToSelect == null) {
        // Use preferred state if provided and it exists in the list
        if (preferredState != null &&
            preferredState.isNotEmpty &&
            states.contains(preferredState)) {
          stateToSelect = preferredState;
        } else if (hosts.isNotEmpty) {
          // Get the first host from the database for this country to get its state
          final firstHost = hosts.first;
          if (firstHost.state != null &&
              firstHost.state!.isNotEmpty &&
              states.contains(firstHost.state)) {
            stateToSelect = firstHost.state;
          } else if (dbStates.isNotEmpty) {
            // Fallback to first state that has hosts
            stateToSelect = dbStates.first;
          } else {
            // Fallback to first state from standard list
            stateToSelect = states.first;
          }
        } else {
          // No hosts, use first state from standard list
          stateToSelect = states.first;
        }
      }

      // Update state synchronously
      setState(() {
        _states = states;
        if (stateToSelect != null) {
          _selectedState = stateToSelect;
        } else if (states.isEmpty) {
          _selectedState = null;
          _availableHosts = [];
          _selectedHost = null;
        }
      });

      if (states.isNotEmpty && stateToSelect != null) {
        // Always load hosts and select first if no host is selected
        // Use stateToSelect to ensure we have the correct state value
        await _loadHostsWithState(stateToSelect);
      } else {
        _clearControllers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading states: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadHosts() async {
    if (_selectedCountry == null) return;
    await _loadHostsWithState(_selectedState);
  }

  Future<void> _loadHostsWithState(String? state) async {
    if (_selectedCountry == null) return;

    setState(() => _isLoading = true);
    try {
      final hosts = await DriftDatabaseHelper.instance
          .getNtripSettingsByCountryAndState(_selectedCountry!, state);

      // Try to load last used host ID from preferences
      NtripSetting? hostToSelect;
      if (hosts.isNotEmpty) {
        if (_selectedHost == null) {
          // No previously selected host, try to load last used
          hostToSelect = await _getLastUsedHost(hosts);
        } else {
          // If we have a selected host, make sure it's still in the list
          if (!hosts.contains(_selectedHost)) {
            // Selected host not in list, try to load last used
            hostToSelect = await _getLastUsedHost(hosts);
          } else {
            // Host is still in list, keep it selected
            hostToSelect = _selectedHost;
          }
        }
      }

      setState(() {
        _availableHosts = hosts;
        if (hosts.isNotEmpty && hostToSelect != null) {
          _selectedHost = hostToSelect;
          _loadHostIntoControllers(_selectedHost!);
        } else {
          _selectedHost = null;
          _clearControllers();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading hosts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadHostIntoControllers(NtripSetting host) {
    widget.hostController.text = host.host;
    widget.portController.text = host.port.toString();
    widget.mountPointController.text = host.mountPoint;
    widget.usernameController.text = host.username;
    widget.passwordController.text = host.password;
    widget.onSslChanged(host.useSsl);
  }

  Future<NtripSetting> _getLastUsedHost(List<NtripSetting> hosts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUsedHostId = prefs.getInt('lastUsedNtripHostId');

      if (lastUsedHostId != null) {
        // Try to find the last used host in the current list
        return hosts.firstWhere(
          (h) => h.id == lastUsedHostId,
          orElse: () => hosts.first, // Fallback to first if not found
        );
      } else {
        // No last used host, select first
        return hosts.first;
      }
    } catch (e) {
      // On error, just select first host
      return hosts.first;
    }
  }

  void _clearControllers() {
    widget.hostController.clear();
    widget.portController.clear();
    widget.mountPointController.clear();
    widget.usernameController.clear();
    widget.passwordController.clear();
    widget.onSslChanged(false);
  }

  void _clearAddHostForm() {
    _nameController.clear();
    _countryController.clear();
    _stateController.clear();
    _hostController.clear();
    _portController.clear();
    _mountPointController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _newHostUseSsl = false;
  }

  void _editHost(NtripSetting host) {
    setState(() {
      _isEditingHost = true;
      _showAddHostForm = false;
      _editingHostId = host.id;
      _nameController.text = host.name;
      _selectedCountryInForm = host.country;
      _countryController.text = host.country;
      _stateController.text = host.state ?? '';
      _hostController.text = host.host;
      _portController.text = host.port.toString();
      _mountPointController.text = host.mountPoint;
      _usernameController.text = host.username;
      _passwordController.text = host.password;
      _newHostUseSsl = host.useSsl;
      _saveCountrySelection(host.country);
    });
  }

  void _duplicateHost(NtripSetting host) {
    setState(() {
      _isEditingHost = false;
      _showAddHostForm = true;
      _editingHostId = null;
      // Copy all fields but modify the name to indicate it's a copy
      _nameController.text = '${host.name} (Copy)';
      _selectedCountryInForm = host.country;
      _countryController.text = host.country;
      _stateController.text = host.state ?? '';
      _hostController.text = host.host;
      _portController.text = host.port.toString();
      _mountPointController.text = host.mountPoint;
      _usernameController.text = host.username;
      _passwordController.text = host.password;
      _newHostUseSsl = host.useSsl;
      _saveCountrySelection(host.country);
    });
  }

  Future<void> _saveNewHost() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3000),
        ),
      );
      return;
    }
    if (_countryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Country is required'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3000),
        ),
      );
      return;
    }

    // Validate state is required
    final currentCountry =
        _selectedCountryInForm ?? _countryController.text.trim();
    final states = _getStatesForCountry(currentCountry);
    if (states.isNotEmpty && _stateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('State (Regione) is required'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3000),
        ),
      );
      return;
    }

    if (_hostController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Host is required'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 3000),
        ),
      );
      return;
    }

    try {
      final country = _countryController.text.trim();
      final name = _nameController.text.trim();
      // State is mandatory - if country has states, state must be provided
      final state = states.isNotEmpty
          ? _stateController.text.trim()
          : null; // Only null if country has no states

      // Check for duplicate name in the same country and state
      final existingHosts = await DriftDatabaseHelper.instance
          .getNtripSettingsByCountryAndState(country, state);

      // Check if a host with the same name already exists (excluding the one being edited)
      final hasDuplicate = existingHosts.any(
        (host) =>
            host.name.toLowerCase() == name.toLowerCase() &&
            (!_isEditingHost || host.id != _editingHostId),
      );

      if (hasDuplicate) {
        // A duplicate was found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'A host with the name "$name" already exists for $country${state != null ? ", $state" : ""}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 1000),
            ),
          );
        }
        return;
      }

      final port = int.tryParse(_portController.text.trim()) ?? 2101;
      final newSetting = NtripSettingCompanion(
        name: drift.Value(name),
        country: drift.Value(country),
        state: drift.Value(state),
        host: drift.Value(_hostController.text.trim()),
        port: drift.Value(port),
        mountPoint: drift.Value(_mountPointController.text.trim()),
        username: drift.Value(_usernameController.text.trim()),
        password: drift.Value(_passwordController.text.trim()),
        useSsl: drift.Value(_newHostUseSsl),
      );

      int? newHostId;
      if (_isEditingHost && _editingHostId != null) {
        // Update existing host
        final updateSetting = newSetting.copyWith(
          id: drift.Value(_editingHostId!),
        );
        await DriftDatabaseHelper.instance.updateNtripSetting(updateSetting);
        newHostId = _editingHostId;
      } else {
        // Insert new host and get the ID
        newHostId = await DriftDatabaseHelper.instance.insertNtripSetting(
          newSetting,
        );
      }

      // Store editing state before clearing
      final wasEditing = _isEditingHost;
      final editedHostId = _editingHostId;

      // Clear form
      _clearAddHostForm();

      setState(() {
        _showAddHostForm = false;
        _isEditingHost = false;
        _editingHostId = null;
      });

      // Save country selection
      final newCountry = _countryController.text.trim();
      await _saveCountrySelection(newCountry);

      // Reload all data to update dropdowns
      final newState = state;

      // Reload countries first
      await _loadCountries();

      // If editing, preserve the edited host selection
      if (wasEditing && editedHostId != null) {
        // Update country/state selection to match the edited host
        setState(() {
          _selectedCountry = country;
          _selectedState = newState;
        });

        // Reload states for the new country
        await _loadStates(newState);

        // Ensure state is set (in case loadStates didn't set it)
        setState(() {
          _selectedState = newState;
        });

        // Reload hosts for the new country/state
        await _loadHostsWithState(newState);

        // Find and select the edited host by ID
        final updatedHosts = await DriftDatabaseHelper.instance
            .getNtripSettingsByCountryAndState(country, newState);

        if (updatedHosts.isNotEmpty) {
          final editedHost = updatedHosts.firstWhere(
            (h) => h.id == editedHostId,
            orElse: () => updatedHosts.first, // Fallback to first if not found
          );

          setState(() {
            _selectedHost = editedHost;
          });
          _loadHostIntoControllers(editedHost);
        }
      } else {
        // Adding new host - select the newly created host
        // Update country/state selection to match the new host
        setState(() {
          _selectedCountry = country;
          _selectedState = newState;
        });

        // Reload states for the new country
        await _loadStates(newState);

        // Ensure state is set
        setState(() {
          _selectedState = newState;
        });

        // Reload hosts for the new country/state
        await _loadHostsWithState(newState);

        // Find and select the newly created host by ID
        if (newHostId != null) {
          final updatedHosts = await DriftDatabaseHelper.instance
              .getNtripSettingsByCountryAndState(country, newState);

          if (updatedHosts.isNotEmpty) {
            final newHost = updatedHosts.firstWhere(
              (h) => h.id == newHostId,
              orElse: () =>
                  updatedHosts.first, // Fallback to first if not found
            );

            setState(() {
              _selectedHost = newHost;
            });
            _loadHostIntoControllers(newHost);
          }
        }
      }

      // Refresh country dropdown to show updated order
      await _initializeCountryDropdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Host added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding host: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  Future<void> _deleteHost(NtripSetting host) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context)?.buttonDelete ?? 'Delete'),
        content: Text('Are you sure you want to delete "${host.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context)?.buttonCancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context)?.buttonDelete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deletedCountry = host.country;
        final wasSelectedHost = _selectedHost?.id == host.id;

        await DriftDatabaseHelper.instance.deleteNtripSetting(host.id);

        // Reload all dropdowns to reflect the deletion
        await _loadCountries();

        // Reload states for current country (or deleted country if no selection)
        if (_selectedCountry == null) {
          setState(() {
            _selectedCountry = deletedCountry;
          });
        }
        await _loadStates();

        // Reload hosts if we have a state selected
        if (_selectedState != null) {
          await _loadHosts();
        }

        // Clear selection if we deleted the selected host
        if (wasSelectedHost) {
          setState(() {
            _selectedHost = null;
          });
          _clearControllers();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Host deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1000),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting host: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 1000),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isConnected =
        widget.connectionState == NTRIPConnectionState.connected;
    final isConnecting =
        widget.connectionState == NTRIPConnectionState.connecting;
    final isError = widget.connectionState == NTRIPConnectionState.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(
          isConnected ? Icons.satellite_alt : Icons.satellite,
          color: isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(s?.bleNtripTitle ?? 'NTRIP Corrections'),
        subtitle: Text(
          isConnected
              ? (s?.bleNtripConnected ?? 'Connected')
              : isConnecting
              ? (s?.bleNtripConnecting ?? 'Connecting...')
              : isError
              ? (s?.bleNtripError ?? 'Error')
              : (s?.bleNtripDisconnected ?? 'Disconnected'),
          style: TextStyle(
            color: isConnected
                ? Colors.green
                : isError
                ? Colors.red
                : Colors.grey,
          ),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Country selection
                      if (_countries.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Country',
                            border: const OutlineInputBorder(),
                          ),
                          items: _countries.map((country) {
                            final localizedName =
                                CountryRegionLocalizations.getLocalizedCountry(
                                  context,
                                  country,
                                );
                            return DropdownMenuItem(
                              value: country,
                              child: Text(
                                localizedName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (isConnected || isConnecting)
                              ? null
                              : (value) async {
                                  setState(() {
                                    _selectedCountry = value;
                                    _selectedState = null;
                                    _selectedHost = null;
                                    _availableHosts = [];
                                    _states = [];
                                    // Cancel editing if dropdown changes
                                    _isEditingHost = false;
                                    _showAddHostForm = false;
                                    _editingHostId = null;
                                  });
                                  await _loadStates();
                                },
                        )
                      else
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Country',
                            hintText: 'No countries available',
                            border: const OutlineInputBorder(),
                            enabled: false,
                          ),
                        ),
                      const SizedBox(height: 12),
                      // State selection
                      if (_selectedCountry != null && _states.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'State (Regione) *',
                            border: const OutlineInputBorder(),
                          ),
                          items: _states.map((state) {
                            final localizedName =
                                CountryRegionLocalizations.getLocalizedRegion(
                                  context,
                                  _selectedCountry!,
                                  state,
                                );
                            return DropdownMenuItem(
                              value: state,
                              child: Text(
                                localizedName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (isConnected || isConnecting)
                              ? null
                              : (value) async {
                                  if (value != null) {
                                    setState(() {
                                      _selectedState = value;
                                      _selectedHost = null;
                                      // Cancel editing if dropdown changes
                                      _isEditingHost = false;
                                      _showAddHostForm = false;
                                      _editingHostId = null;
                                    });
                                    await _loadHosts();
                                  }
                                },
                        )
                      else if (_selectedCountry != null && _states.isEmpty)
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'State (Regione)',
                            hintText: 'No states available for this country',
                            border: const OutlineInputBorder(),
                            enabled: false,
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Host selection
                      if (_selectedState != null && _availableHosts.isNotEmpty)
                        DropdownButtonFormField<NtripSetting>(
                          value: _selectedHost,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Host Name',
                            border: const OutlineInputBorder(),
                          ),
                          items: _availableHosts.map((host) {
                            // Debug: log the connection status
                            final showCheckmark =
                                host.lastConnectionSuccessful == true;
                            final showX =
                                host.lastConnectionSuccessful == false;
                            return DropdownMenuItem(
                              value: host,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      host.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (showCheckmark)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    )
                                  else if (showX)
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (isConnected || isConnecting)
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedHost = value;
                                    // Cancel editing if dropdown changes
                                    _isEditingHost = false;
                                    _showAddHostForm = false;
                                    _editingHostId = null;
                                  });
                                  if (value != null) {
                                    _loadHostIntoControllers(value);
                                  }
                                },
                        )
                      else if (_selectedState != null &&
                          _availableHosts.isEmpty)
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Host Name',
                            hintText: 'No hosts available',
                            border: const OutlineInputBorder(),
                            enabled: false,
                          ),
                        ),
                      // Buttons: Row 1 (Edit + Duplicate), Row 2 (Add + Delete)
                      if (!isConnected && !isConnecting)
                        Column(
                          children: [
                            // Row 1: Edit + Duplicate (only shown when host is selected)
                            if (_selectedHost != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _editHost(_selectedHost!),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _duplicateHost(_selectedHost!),
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Duplicate'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Row 2: Add + Delete
                            Padding(
                              padding: EdgeInsets.only(
                                top: _selectedHost != null ? 8.0 : 0.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          (!_showAddHostForm && !_isEditingHost)
                                          ? () {
                                              setState(() {
                                                _showAddHostForm = true;
                                                _isEditingHost = false;
                                                _editingHostId = null;
                                                _clearAddHostForm();
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Host'),
                                    ),
                                  ),
                                  if (_selectedHost != null) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _deleteHost(_selectedHost!),
                                        icon: const Icon(Icons.delete),
                                        label: Text(
                                          s?.buttonDelete ?? 'Delete',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      // Add/Edit host form
                      if ((_showAddHostForm || _isEditingHost) &&
                          !isConnected &&
                          !isConnecting)
                        _buildAddHostForm(s),
                      const SizedBox(height: 16),
                      if (isConnected)
                        ElevatedButton.icon(
                          onPressed: widget.onDisconnect,
                          icon: const Icon(Icons.close),
                          label: Text(s?.bleNtripDisconnect ?? 'Disconnect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else ...[
                        if (!widget.canConnectNtrip)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              s?.bleNtripWaitForPosition ??
                                  'Wait for GPS position from device before connecting to NTRIP.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed:
                              (!widget.canConnectNtrip ||
                                  isConnecting ||
                                  _isEditingHost ||
                                  _showAddHostForm)
                              ? null
                              : () {
                                  // Ensure controllers are synced with selected host before connecting
                                  if (_selectedHost != null) {
                                    _loadHostIntoControllers(_selectedHost!);
                                    widget.onConnect(_selectedHost!.id);
                                  } else {
                                    widget.onConnect(null);
                                  }
                                },
                          icon: isConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.link),
                          label: Text(
                            isConnecting
                                ? (s?.bleNtripConnecting ?? 'Connecting...')
                                : (s?.bleNtripConnect ?? 'Connect to NTRIP'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                      if (widget.isForwardingRtcm) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s?.bleNtripForwarding ??
                                  'Forwarding RTCM corrections',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddHostForm(S? s) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditingHost ? 'Edit Host' : 'Add New Host',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Host Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _getSortedCountriesAsync(),
              builder: (context, snapshot) {
                final countries = snapshot.data ?? _standardCountries;
                final selectedCountry =
                    _selectedCountryInForm ?? countries.first;

                return DropdownButtonFormField<String>(
                  value: selectedCountry,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: countries.map((country) {
                    final localizedName =
                        CountryRegionLocalizations.getLocalizedCountry(
                          context,
                          country,
                        );
                    return DropdownMenuItem(
                      value: country,
                      child: Text(
                        localizedName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCountryInForm = value;
                        _countryController.text = value;
                        // Reset state when country changes
                        _stateController.text = '';
                      });
                      _saveCountrySelection(value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final currentCountry =
                    _selectedCountryInForm ?? _countryController.text;
                final states = _getStatesForCountry(currentCountry);
                final currentState = _stateController.text.isEmpty
                    ? null
                    : _stateController.text;
                // Reset state if it's not valid for the current country, or select first if empty
                final validState =
                    states.isNotEmpty && states.contains(currentState)
                    ? currentState
                    : (states.isNotEmpty ? states.first : null);

                // If no states available for this country, show disabled field
                if (states.isEmpty) {
                  return TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State (Regione)',
                      hintText: 'No states available for this country',
                      border: OutlineInputBorder(),
                      enabled: false,
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: validState,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'State (Regione) *',
                    border: OutlineInputBorder(),
                  ),
                  items: states.map((state) {
                    final localizedName =
                        CountryRegionLocalizations.getLocalizedRegion(
                          context,
                          currentCountry,
                          state,
                        );
                    return DropdownMenuItem(
                      value: state,
                      child: Text(
                        localizedName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _stateController.text = value;
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: s?.bleNtripHost ?? 'NTRIP Caster Host',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: s?.bleNtripPort ?? 'Port',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _newHostUseSsl,
                        onChanged: (value) =>
                            setState(() => _newHostUseSsl = value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('SSL/TLS'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mountPointController,
              decoration: InputDecoration(
                labelText: s?.bleNtripMountPoint ?? 'Mount Point',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                        children: const [
                          TextSpan(text: 'This app only accepts '),
                          TextSpan(
                            text: 'RTCM standard',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' version 3+, not '),
                          TextSpan(
                            text: 'RTCM compatible',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' or versions below 3.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: s?.bleNtripUsername ?? 'Username (Email)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: s?.bleNtripPassword ?? 'Password',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAddHostForm = false;
                      _isEditingHost = false;
                      _editingHostId = null;
                    });
                    _clearAddHostForm();
                  },
                  child: Text(s?.buttonCancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveNewHost,
                  child: Text(s?.buttonSave ?? 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
