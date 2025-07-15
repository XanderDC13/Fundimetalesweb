const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.setCustomClaimsOnCreate = functions.firestore
    .document("usuarios_activos/{userId}")
    .onCreate(async (snap, context) => {
      const userId = context.params.userId;
      const data = snap.data();

      const rol = data.rol;

      let claims = {};

      if (rol === "Administrador") {
        claims = {admin: true};
      } else if (rol === "Empleado") {
        claims = {role: "employee"};
      } else {
        console.log(`Rol no reconocido: ${rol}`);
        return null;
      }

      try {
        await admin.auth().setCustomUserClaims(userId, claims);
        console.log(`Custom claims asignados a ${userId}:`, claims);
      } catch (error) {
        console.error(`Error al asignar claims a ${userId}:`, error);
      }

      return null;
    });
