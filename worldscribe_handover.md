# WorldScribe — Handover Document

## 📱 Project Overview
WorldScribe is a mobile-first worldbuilding app for writers, game developers, and storytellers.

It allows users to create and manage:
- Worlds
- Characters
- Locations
- Factions
- Lore

It integrates AI (Gemini API) to generate and expand creative content.

---

## 🎯 MVP Goal
Users can:
1. Create a world  
2. Add characters  
3. Generate characters using AI  
4. View and edit saved lore  

---

## 🧱 Tech Stack
Frontend: Flutter  
Backend: Firebase (Auth, Firestore, Cloud Functions)  
AI: Gemini API  

---

## 🧩 Architecture

Flutter App  
↓  
Firebase (Auth + Firestore)  
↓  
Cloud Functions (secure API layer)  
↓  
Gemini API  

IMPORTANT: Never store API keys in the app.

---

## 📂 Folder Structure

/lib
  /core
  /features
  /screens
  /widgets
  /services
main.dart

---

## 📱 Core Screens

- Splash Screen  
- Home Screen (World list)  
- Create World  
- World Dashboard  
- Characters Screen  
- Character Detail  
- AI Forge  

---

## 🤖 AI Flow

1. App sends prompt  
2. Cloud Function calls Gemini  
3. Returns JSON  
4. Save to Firestore  

---

## 🗄️ Firestore Structure

users/
  userId/
    worlds/
      worldId/
        characters/

---

## 🔐 Security

- API keys only in backend  
- User data isolated  
- Validate AI output  

---

## 🚀 Phases

Phase 1:
- Auth
- Worlds
- Characters
- AI generation

Phase 2:
- Locations
- Factions
- Timeline

---

## 🧪 Testing

- Create world works  
- Add character works  
- AI generation works  
- Data persists  

---

## 🎨 UI Direction

- Dark fantasy journal style  
- Card-based UI  
- Fast and simple  

---

## ⚠️ Risks

- AI limits  
- JSON formatting issues  
- Scaling costs  

---

## 💡 Future

- Maps  
- Relationships graph  
- Export tools  

---

## ✅ Notes

Focus on simplicity and speed. Avoid overbuilding early.

End of file.
