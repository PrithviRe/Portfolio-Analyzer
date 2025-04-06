# 📊 AI-Powered Portfolio Analyzer

This is a smart portfolio analysis tool that uses **Google Gemini**, **Firebase**, **News Sentiment**, and **Live Stock Data** to deliver deep, explainable insights on your investments. It helps you track stock performance, predict potential risks, and make better buy/sell decisions — all in plain, natural language.

---

## 🚀 Features

- **Real-time Stock Analysis** – Pulls current stock data using Yahoo Finance.
- **Sentiment-Driven Forecasting** – Analyzes financial news headlines and applies sentiment scoring.
- **Gemini AI Reports** – Uses Gemini API to generate personalized, conversational stock insights.
- **Buy / Sell / Hold Suggestions** – AI-based recommendations based on sentiment and market trends.
- **Prediction Accuracy Tracking** – Compares past AI predictions with actual market movements.

---

## 🛠️ Tech Stack

- **Flutter**
- **Python**
- **Firebase Functions**
- **Google Generative AI (Gemini)**
- **Yahoo Finance API (yfinance)**
- **NewsAPI**
- **TextBlob (for sentiment analysis)**
- **JSON-based storage for predictions**

---

## 📦 Prerequisites

Before running this project, make sure you have the following tools installed:

- [Python 3.8+](https://www.python.org/downloads/) – for running backend scripts
- [pip](https://pip.pypa.io/en/stable/) – for installing Python dependencies
- [Flutter SDK](https://docs.flutter.dev/get-started/install) – required if you're working with the Flutter frontend
- [Node.js (v14+)](https://nodejs.org/) – needed to install Firebase CLI
- [Firebase CLI](https://firebase.google.com/docs/cli):
  ```bash
  npm install -g firebase-tools

## ⚙️ Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/Portfolio-Analyzer.git
   cd Portfolio-Analyzer/
2. Install the required dependencies
   ```bash
   cd firebase-cloud-function/functions/
   pip install -r requirements.txt
3. Add your API keys to api.env <br>
   i. To get Gemini AI API Key, follow these steps: <br>
      &nbsp;&nbsp;&nbsp;&nbsp;a. Head to [Google AI Studio](https://aistudio.google.com/) <br>
      &nbsp;&nbsp;&nbsp;&nbsp;b. Click on Get API Key > Create API Key <br>
      &nbsp;&nbsp;&nbsp;&nbsp;c. Select from an existing Google Cloud project (if not having an existing project, you can create one from [Google Cloud](https://console.cloud.google.com/)) <br>
      &nbsp;&nbsp;&nbsp;&nbsp;d. API key is created, now copy it from the list and add to api.env <br>
   ii. To get News API Key, follow these steps: <br>
      &nbsp;&nbsp;&nbsp;&nbsp;a. Head to [News API](https://newsapi.org/) <br>
      &nbsp;&nbsp;&nbsp;&nbsp;b. Click on Get API Key. <br>
      &nbsp;&nbsp;&nbsp;&nbsp;c. Add the API Key to api.env <br>
4. Deploy firebase-cloud-function to [Firebase](https://firebase.google.com/) <br>
5. Head to [KITE Connect](https://developers.kite.trade/), Click on Create new app > Choose Publisher Type > Add relevant details > Create <br>
6. Add your API Key and API Secret which you got from the previous step <br>
   ```bash
   cd portfolio_analyzer/lib/
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Open keys.dart and add your API Key and API Secret<br>

## ▶️ Running the App

After cloning the repository and setting up the dependencies, you can run the app locally using the following command:

   ```bash
   flutter build --release
```
Upon running this command your apk will available in portfolio_analyzer/build/app/outputs/flutter-apk/ 
