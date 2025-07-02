const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();
sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendFeedbackEmail = functions.firestore
  .document("feedback/{feedbackId}")
  .onCreate((snap, context) => {
    const data = snap.data();

    const msg = {
      to: "alexdelgado1318@gmail.com", // Cambia por tu correo real
      from: "noreply@tudominio.com",
      subject: `📩 Nuevo Feedback: ${data.type}`,
      text: `
Nuevo feedback recibido:

Tipo: ${data.type}
Descripción: ${data.description}
Email de usuario: ${data.userEmail || 'No proporcionado'}
Fecha: ${new Date().toISOString()}
      `,
    };

    return sgMail.send(msg);
  });
