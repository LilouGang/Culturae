const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const subThemeData = [
  {
    theme: 'Société',
    sousTheme: 'Religions',
    imagePath: 'assets/images/societereligions.jpg',
  },
  {
    theme: 'Société',
    sousTheme: 'Psychologie',
    imagePath: 'assets/images/societepsychologie.jpg',
  },
  {
    theme: 'Société',
    sousTheme: 'Droit',
    imagePath: 'assets/images/societedroit.jpg',
  },
  {
    theme: 'Société',
    sousTheme: 'Économie',
    imagePath: 'assets/images/societeeconomie.jpg',
  },
  {
    theme: 'Société',
    sousTheme: 'Politique',
    imagePath: 'assets/images/societepolitique.jpg',
  },
  {
    theme: 'Société',
    sousTheme: 'Gastronomie',
    imagePath: 'assets/images/societegastronomie.jpg',
  },
  {
    theme: 'Technologie',
    sousTheme: 'Transports',
    imagePath: 'assets/images/technologietransports.jpg',
  },
  {
    theme: 'Technologie',
    sousTheme: 'Énergies',
    imagePath: 'assets/images/technologieenergies.jpg',
  },
  {
    theme: 'Technologie',
    sousTheme: 'Numérique',
    imagePath: 'assets/images/technologienumerique.jpg',
  },
  {
    theme: 'Technologie',
    sousTheme: 'Communication',
    imagePath: 'assets/images/technologiecommunication.jpg',
  },
  {
    theme: 'Technologie',
    sousTheme: 'Intelligence Artificielle',
    imagePath: 'assets/images/technologieintelligenceartificielle.jpg',
  },
  {
    theme: 'Technologie',
    sousTheme: 'Biotechnologie',
    imagePath: 'assets/images/technologiebiotechnologie.jpg',
  },
  {
    theme: 'Divertissement',
    sousTheme: 'Jeux Vidéo',
    imagePath: 'assets/images/divertissementjeuxvideo.jpg',
  },
  {
    theme: 'Divertissement',
    sousTheme: 'Jeux de Société',
    imagePath: 'assets/images/divertissementjeuxdesociete.jpg',
  },
  {
    theme: 'Divertissement',
    sousTheme: 'Célébrités & People',
    imagePath: 'assets/images/divertissementcelebritesetpeople.jpg',
  },
  {
    theme: 'Divertissement',
    sousTheme: 'Culture Web',
    imagePath: 'assets/images/divertissementcultureweb.jpg',
  },
  {
    theme: 'Divertissement',
    sousTheme: 'Sports',
    imagePath: 'assets/images/divertissementsports.jpg',
  },
  {
    theme: 'Divers',
    sousTheme: 'Records',
    imagePath: 'assets/images/diversrecords.jpg',
  },
  {
    theme: 'Divers',
    sousTheme: 'Marques',
    imagePath: 'assets/images/diversmarques.jpg',
  },
  {
    theme: 'Divers',
    sousTheme: 'Insolite',
    imagePath: 'assets/images/diversinsolite.jpg',
  },
  {
    theme: 'Divers',
    sousTheme: 'Vocabulaire',
    imagePath: 'assets/images/diversvocabulaire.jpg',
  },
];

async function bulkCreateSubThemeStyles() {
  console.log("--- DÉBUT de la création en masse des SousThemesStyles ---");

  const collectionRef = db.collection('SousThemesStyles');
  const batch = db.batch();

  subThemeData.forEach(data => {
    if (!data.theme || !data.sousTheme) {
      console.error("Donnée invalide, 'theme' ou 'sousTheme' manquant :", data);
      return;
    }
    const docId = `${data.theme} ${data.sousTheme}`;

    const docRef = collectionRef.doc(docId);
    batch.set(docRef, data);
  });

  try {
    await batch.commit();
    console.log(`--- SUCCÈS : ${subThemeData.length} documents SousThemesStyles créés/mis à jour. ---`);
  } catch (error) {
    console.error("--- ERREUR lors de la création en masse :", error);
  }
}

bulkCreateSubThemeStyles();