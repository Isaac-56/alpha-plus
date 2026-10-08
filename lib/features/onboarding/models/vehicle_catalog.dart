/// Vehicle catalogue used during Alpha Plus registration.
///
/// Drivers first choose the physical category of the vehicle. Makes and
/// models are then limited to that category so a car model can never be
/// registered as a boda or tuk-tuk. `Other` remains available for legitimate
/// vehicles that are not yet in the catalogue; the admin still verifies every
/// vehicle before approval.
abstract final class VehicleCatalog {
  static const String car = 'Car';
  static const String tukTuk = 'Tuk-tuk (three-wheeler)';
  static const String boda = 'Boda (motorcycle)';

  static const List<String> categories = <String>[car, tukTuk, boda];

  static const Map<String, Map<String, List<String>>> _catalog =
      <String, Map<String, List<String>>>{
        car: <String, List<String>>{
          'Toyota': <String>[
            'Vitz',
            'Yaris',
            'Corolla',
            'Premio',
            'Allion',
            'Probox',
            'Succeed',
            'Noah',
            'Voxy',
            'Wish',
            'Hiace',
            'RAV4',
            'Harrier',
            'Land Cruiser Prado',
            'Land Cruiser',
            'Hilux',
            'Other Toyota',
          ],
          'Nissan': <String>[
            'March',
            'Note',
            'Tiida',
            'Sunny',
            'Bluebird Sylphy',
            'X-Trail',
            'Murano',
            'Pathfinder',
            'Patrol',
            'Navara',
            'Caravan',
            'Other Nissan',
          ],
          'Honda': <String>[
            'Fit',
            'Civic',
            'Accord',
            'CR-V',
            'HR-V',
            'Odyssey',
            'Other Honda',
          ],
          'Hyundai': <String>[
            'i10',
            'i20',
            'Accent',
            'Elantra',
            'Sonata',
            'Tucson',
            'Santa Fe',
            'H-1',
            'Other Hyundai',
          ],
          'Kia': <String>[
            'Picanto',
            'Rio',
            'Cerato',
            'Optima',
            'Sportage',
            'Sorento',
            'Carnival',
            'Other Kia',
          ],
          'Suzuki': <String>[
            'Alto',
            'Celerio',
            'Swift',
            'Dzire',
            'Ertiga',
            'Vitara',
            'Jimny',
            'Other Suzuki',
          ],
          'Mitsubishi': <String>[
            'Lancer',
            'Outlander',
            'Pajero',
            'L200',
            'Other Mitsubishi',
          ],
          'Subaru': <String>[
            'Impreza',
            'Legacy',
            'Forester',
            'Outback',
            'Other Subaru',
          ],
          'Mazda': <String>[
            'Demio',
            'Mazda3',
            'Mazda6',
            'CX-5',
            'BT-50',
            'Other Mazda',
          ],
          'Ford': <String>[
            'Focus',
            'Fusion',
            'Escape',
            'Everest',
            'Ranger',
            'Other Ford',
          ],
          'Chevrolet': <String>[
            'Spark',
            'Aveo',
            'Cruze',
            'Captiva',
            'Trailblazer',
            'Other Chevrolet',
          ],
          'Mercedes-Benz': <String>[
            'C-Class',
            'E-Class',
            'S-Class',
            'GLA',
            'GLC',
            'GLE',
            'Vito',
            'Other Mercedes-Benz',
          ],
          'BMW': <String>[
            '3 Series',
            '5 Series',
            '7 Series',
            'X1',
            'X3',
            'X5',
            'Other BMW',
          ],
          'Volkswagen': <String>[
            'Polo',
            'Golf',
            'Jetta',
            'Passat',
            'Tiguan',
            'Other Volkswagen',
          ],
          'Other': <String>['Other car model'],
        },
        tukTuk: <String, List<String>>{
          'Bajaj': <String>['RE', 'RE Compact', 'Maxima', 'Maxima Cargo'],
          'TVS': <String>['King', 'King Deluxe', 'King Kargo'],
          'Piaggio': <String>['Ape City', 'Ape Auto', 'Ape Xtra'],
          'Atul': <String>['Gem', 'Gem Paxx', 'Pakshi'],
          'Mahindra': <String>['Alfa', 'Alfa Plus', 'Treo'],
          'Other': <String>['Other tuk-tuk model'],
        },
        boda: <String, List<String>>{
          'Bajaj': <String>[
            'Boxer 100',
            'Boxer 125',
            'Boxer 150',
            'CT 100',
            'Discover',
            'Pulsar',
          ],
          'TVS': <String>[
            'HLX 100',
            'HLX 125',
            'HLX 150',
            'Star City',
            'Apache',
          ],
          'Honda': <String>['ACE 110', 'ACE 125', 'CG 125', 'CB 125'],
          'Haojue': <String>['HJ 110', 'HJ 125', 'DK 125', 'KA 150'],
          'Senke': <String>['SK 125', 'SK 150', 'Other Senke'],
          'Yamaha': <String>['YBR 125', 'Crux', 'XTZ 125'],
          'Dayun': <String>['DY 100', 'DY 125', 'DY 150'],
          'Lifan': <String>['LF 110', 'LF 125', 'LF 150'],
          'Sanya': <String>['SY 110', 'SY 125', 'SY 150'],
          'Other': <String>['Other boda model'],
        },
      };

  static List<String> makesFor(String category) =>
      List<String>.unmodifiable(_catalog[category]?.keys ?? const <String>[]);

  static List<String> modelsFor(String category, String make) =>
      List<String>.unmodifiable(
        _catalog[category]?[make] ?? const <String>[],
      );

  static String normalizeCategory(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    if (normalized.contains('tuk') ||
        normalized.contains('rickshaw') ||
        normalized.contains('three') ||
        normalized.contains('bajaj')) {
      return tukTuk;
    }
    if (normalized.contains('boda') ||
        normalized.contains('motor') ||
        normalized.contains('scooter')) {
      return boda;
    }
    return car;
  }

  static bool isValidCombination({
    required String category,
    required String make,
    required String model,
  }) =>
      _catalog[category]?.containsKey(make) == true &&
      (_catalog[category]?[make]?.contains(model) ?? false);
}
