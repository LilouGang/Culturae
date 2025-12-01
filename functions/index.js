const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.updateQuestionDifficulty = onSchedule("every 24 hours", async (event) => {
  logger.info("Début du job de mise à jour de la difficulté.");

  try {
    const logsSnapshot = await db.collection("AnswerLogs").get();
    if (logsSnapshot.empty) {
      logger.info("Aucun log à traiter.");
      return null;
    }
    logger.info(`Traitement de ${logsSnapshot.size} logs.`);

    const stats = {};
    const questionIdsFromLogs = new Set(); 
    
    logsSnapshot.forEach((doc) => {
      const log = doc.data();
      if (log && typeof log.questionId === 'string' && log.questionId.length > 0) {
        const questionId = log.questionId;
        questionIdsFromLogs.add(questionId);
        if (!stats[questionId]) {
          stats[questionId] = {answered: 0, correct: 0};
        }
        stats[questionId].answered++;
        if (log.wasCorrect === true) {
          stats[questionId].correct++;
        }
      } else {
        logger.warn("Log ignoré car son format est invalide :", doc.id, log);
      }
    });

    const questionRefs = Array.from(questionIdsFromLogs).map((id) => db.collection("Questions").doc(id));
    const questionsDocs = await db.getAll(...questionRefs);
    
    const existingQuestionIds = new Set();
    questionsDocs.forEach((doc) => {
      if (doc.exists) {
        existingQuestionIds.add(doc.id);
      }
    });
    logger.info(`${existingQuestionIds.size} questions existantes trouvées sur ${questionIdsFromLogs.size} mentionnées.`);

    if (existingQuestionIds.size > 0) {
      const batch = db.batch();
      for (const questionId in stats) {
        if (existingQuestionIds.has(questionId)) {
          const questionRef = db.collection("Questions").doc(questionId);
          const stat = stats[questionId];
          batch.update(questionRef, {
            timesAnswered: admin.firestore.FieldValue.increment(stat.answered),
            timesCorrect: admin.firestore.FieldValue.increment(stat.correct),
          });
        }
      }
      await batch.commit();
      logger.info(`${existingQuestionIds.size} questions mises à jour avec les nouveaux compteurs.`);
    }

    const allQuestionsSnapshot = await db.collection("Questions").get();
    const difficultyBatch = db.batch();
    allQuestionsSnapshot.forEach((doc) => {
      const question = doc.data();
      const timesAnswered = question.timesAnswered || 0;
      const timesCorrect = question.timesCorrect || 0;
      let currentDifficulty = question.difficulty || 5;
      let newDifficulty = currentDifficulty; // On initialise la nouvelle difficulté avec l'ancienne

      // 2. On ne recalcule la difficulté que si le seuil est atteint.
      if (timesAnswered > 100) {
        const ratio = timesCorrect / timesAnswered;
        if (ratio >= 0.9) newDifficulty = 1;
        else if (ratio >= 0.8) newDifficulty = 2;
        else if (ratio >= 0.7) newDifficulty = 3;
        else if (ratio >= 0.6) newDifficulty = 4;
        else if (ratio >= 0.5) newDifficulty = 5;
        else if (ratio >= 0.4) newDifficulty = 6;
        else if (ratio >= 0.3) newDifficulty = 7;
        else if (ratio >= 0.2) newDifficulty = 8;
        else if (ratio >= 0.1) newDifficulty = 9;
        else newDifficulty = 10;
      }
      
      // 3. On n'écrit dans la base de données que si la difficulté a réellement changé.
      //    C'est une optimisation pour réduire le nombre d'écritures.
      if (newDifficulty !== currentDifficulty) {
          difficultyBatch.update(doc.ref, {difficulty: newDifficulty});
      }
    });
    await difficultyBatch.commit();
    logger.info("Difficulté recalculée pour toutes les questions.");

    const deleteBatch = db.batch();
    logsSnapshot.forEach((doc) => {
      deleteBatch.delete(doc.ref);
    });
    await deleteBatch.commit();
    logger.info(`${logsSnapshot.size} logs supprimés. Job terminé avec succès.`);

  } catch (error) {
    logger.error("Une erreur fatale est survenue pendant l'exécution :", error);
    throw error;
  }

  return null;
});

exports.cleanupUserData = onSchedule("every 24 hours", async (event) => {
  logger.info("Début du job de nettoyage des données utilisateur.");

  const questionsSnapshot = await db.collection("Questions").get();
  const validQuestionIds = new Set();
  questionsSnapshot.forEach((doc) => {
    validQuestionIds.add(doc.id);
  });
  logger.info(`${validQuestionIds.size} ID de questions valides trouvés.`);

  const usersSnapshot = await db.collection("Users").get();
  if (usersSnapshot.empty) {
    logger.info("Aucun utilisateur à traiter. Arrêt.");
    return null;
  }

  const cleanupBatch = db.batch();
  let usersToUpdate = 0;

  usersSnapshot.forEach((userDoc) => {
    const userData = userDoc.data();
    if (userData.answeredQuestions) {
      const userAnswers = userData.answeredQuestions;
      const updates = {};
      let needsUpdate = false;

      for (const questionId in userAnswers) {
        if (!validQuestionIds.has(questionId)) {
          updates[`answeredQuestions.${questionId}`] = admin.firestore.FieldValue.delete();
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        cleanupBatch.update(userDoc.ref, updates);
        usersToUpdate++;
      }
    }
  });

  if (usersToUpdate > 0) {
    await cleanupBatch.commit();
    logger.info(`Nettoyage terminé. ${usersToUpdate} documents utilisateur mis à jour.`);
  } else {
    logger.info("Aucun utilisateur n'avait de données à nettoyer.");
  }

  return null;
});