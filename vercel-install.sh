#!/bin/bash

# On définit la version de Flutter à utiliser
FLUTTER_VERSION="3.35.2"

# On clone la branche de cette version spécifique
git clone https://github.com/flutter/flutter.git --branch $FLUTTER_VERSION --depth 1

# On ajoute Flutter au PATH
export PATH="$PATH:`pwd`/flutter/bin"

# On installe Flutter et les dépendances du projet
flutter precache
flutter pub get

# --- ON AJOUTE LA COMMANDE DE BUILD ICI ---
flutter build web --release