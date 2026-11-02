import 'package:fleet_management/l10n/app_localizations.dart';

/// Display labels for the load specs stored in English (axle, body, floor, material).
/// The English value is what is stored and sent; only what the user sees is translated.
/// An unknown value (for example one typed elsewhere or sent by RR) is shown as it is.

String axleTypeLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Single Axle': return l10n.loadSpecAxleSingle;
    case 'Tandem Axle': return l10n.loadSpecAxleTandem;
    case 'Tri-Axle': return l10n.loadSpecAxleTri;
    case 'Multi-Axle': return l10n.loadSpecAxleMulti;
    case 'Semi-Trailer': return l10n.loadSpecAxleSemiTrailer;
    case 'Full Trailer': return l10n.loadSpecAxleFullTrailer;
    default: return value;
  }
}

String bodyTypeLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Open Body': return l10n.loadSpecBodyOpen;
    case 'Closed Body': return l10n.loadSpecBodyClosed;
    case 'Flatbed': return l10n.loadSpecBodyFlatbed;
    case 'Container': return l10n.loadSpecBodyContainer;
    case 'Tipper / Dumper': return l10n.loadSpecBodyTipper;
    case 'Refrigerated': return l10n.loadSpecBodyRefrigerated;
    case 'Tanker': return l10n.loadSpecBodyTanker;
    case 'Car Carrier': return l10n.loadSpecBodyCarCarrier;
    case 'Low Bed': return l10n.loadSpecBodyLowBed;
    case 'Side Wall': return l10n.loadSpecBodySideWall;
    default: return value;
  }
}

String floorTypeLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Plain Floor': return l10n.loadSpecFloorPlain;
    case 'Wooden': return l10n.loadSpecFloorWooden;
    case 'Steel': return l10n.loadSpecFloorSteel;
    case 'Aluminium': return l10n.loadSpecFloorAluminium;
    case 'Bamboo': return l10n.loadSpecFloorBamboo;
    case 'Rubber Matted': return l10n.loadSpecFloorRubberMatted;
    case 'Corrugated': return l10n.loadSpecFloorCorrugated;
    default: return value;
  }
}

String materialLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Steel Coils': return l10n.loadSpecMatSteelCoils;
    case 'Perishables': return l10n.loadSpecMatPerishables;
    case 'Electronics': return l10n.loadSpecMatElectronics;
    case 'Industrial': return l10n.loadSpecMatIndustrial;
    case 'Paints & Coatings': return l10n.loadSpecMatPaints;
    case 'Chemicals': return l10n.loadSpecMatChemicals;
    case 'Pharmaceuticals': return l10n.loadSpecMatPharma;
    case 'Automotive Parts': return l10n.loadSpecMatAutoParts;
    case 'Furniture': return l10n.loadSpecMatFurniture;
    case 'Textiles & Fabrics': return l10n.loadSpecMatTextiles;
    case 'FMCG / Packaged Goods': return l10n.loadSpecMatFmcg;
    case 'Construction Materials': return l10n.loadSpecMatConstruction;
    case 'Agricultural Produce': return l10n.loadSpecMatAgri;
    case 'Machinery & Equipment': return l10n.loadSpecMatMachinery;
    case 'Hazardous Goods': return l10n.loadSpecMatHazardous;
    case 'Liquids / Beverages': return l10n.loadSpecMatLiquids;
    case 'Plastics & Rubber': return l10n.loadSpecMatPlastics;
    case 'Paper & Printing': return l10n.loadSpecMatPaper;
    case 'Glass & Ceramics': return l10n.loadSpecMatGlass;
    case 'Others': return l10n.loadSpecMatOthers;
    default: return value;
  }
}
