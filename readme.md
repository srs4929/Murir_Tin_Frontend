# 🚌 Murir Tin

**Murir Tin** is a smart local bus app designed to improve public transportation in Dhaka. It introduces color-coded routes, live GPS tracking, QR-code-based ticket booking, a complaint management system, and emergency SOS features. The app simplifies daily travel for commuters and aligns with the government’s initiative to make bus routes more organized.

---

## 🚀 Features

### 🗺️ Find Bus
- Shows current user location on the map.
- Displays nearby bus stoppages and color-coded routes.

### 📍 Live Map
- Tracks buses in real time.
- Helps users locate the nearest arriving buses easily.

### 🎟️ Book Ticket
- Calculates fare based on distance.
- Supports secure online payments.
- Generates QR-code and downloadable PDF tickets.

### 📢 Complaint Box
- Submit complaints about buses or tickets.
- Track status (Submitted, Accepted, Solved).
- View and react to other user complaints.

### 🚨 Emergency SOS
- Send quick alerts during emergencies (e.g., harassment, health issues).
- Connects with the nearest help center.

### 👤 Profile & Settings
- View and update personal details.
- Manage profile picture and password settings.

---

## 🛠️ Tools & Technologies

- **Frontend:** Flutter  
- **Backend:** FastAPI + Supabase  
- **Database & Authentication:** Supabase (PostgreSQL)  
- **Maps & Location:** Mapbox API  
- **Payment Gateway:** bKash (sandbox mode)  
- **Version Control:** Git & GitHub  

---
## 🔗 Backend Repository

[Backend Source Code (GitHub)](https://github.com/JobaerTamim7/MurirTinServer.git)

----

## 🧪 How to Install
---



This app requires certain sensitive keys and tokens to run, which should be stored securely in a `.env` file.

1. **Create a `.env` file in the project root with the following content:**

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_ACCESS_TOKEN
SUPABASE_JWT_SECRET=YOUR_SUPABASE_JWT_SECRET
```
2. **Clone the repository**
```
git clone https://github.com/srs4929/Murir_Tin_Frontend.git

```   
3.. **Go to frontend directory**
```
cd Murir_Tin_Frontend-main
``` 
4. **Install dependencies**
```
flutter pub get
```
4. **Run the app**
```   
flutter run
```





