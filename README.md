# NexusAuth 🔐

A simple, open-source project demonstrating how to connect a Flutter application to a Python FastAPI backend using **JWT Authentication** and **JSON Serialization/Deserialization**.

## 💡 What is this project?
NexusAuth is a minimalist app with a strict two-color UI. It consists of a simple login screen and a protected dashboard. The primary goal of this repository is to show how a frontend (Flutter) securely communicates with a backend (Python) using a digital token, and how data is translated between the two different programming languages.

## 📚 Core Concepts Explained

### 1. JSON Serialization & Deserialization
To send data across the internet, it must be converted into a universal text format called **JSON**.
* **Serialization:** The Python backend takes its internal data (like dictionaries or objects) and converts it into a JSON string to send over the network.
* **Deserialization:** The Flutter frontend receives this JSON string and converts it back into structured Dart objects so the app can display the data on the screen.

### 2. JWT (JSON Web Token)
Think of a JWT as a secure, temporary digital ID card.
1. The user logs in with their credentials (username/password).
2. The Python backend validates the credentials and creates a JWT.
3. The Flutter app receives this token and stores it securely.
4. For any future requests to view protected data, the Flutter app attaches this token to the request. The backend checks the token's validity before granting access.

## 🚀 How to Run the Project

### 1. Start the Backend (Python/FastAPI)
Open your terminal and run the following commands:
```bash
cd py_backend
pip install -r requirements.txt
cp .env.example .env  # Ensure you have a SECRET_KEY in this file
python main.py
```

#### 2. Start the Flutter App
Open your terminal and run the following commands:
```bash
cd nexus_auth
flutter run
```