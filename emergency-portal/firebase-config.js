// ============================================================
//  RoadSOS Emergency Portal — Firebase Configuration
//  Replace the values below with your own Firebase project.
//  Get them from: https://console.firebase.google.com/
//  Project Settings → General → Your apps → Firebase SDK snippet
// ============================================================

const firebaseConfig = {
  apiKey:            "YOUR_API_KEY",
  authDomain:        "YOUR_PROJECT.firebaseapp.com",
  databaseURL:       "https://YOUR_PROJECT-default-rtdb.firebaseio.com",
  projectId:         "YOUR_PROJECT_ID",
  storageBucket:     "YOUR_PROJECT.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId:             "YOUR_APP_ID"
};

// Export so index.html can import it
export default firebaseConfig;
