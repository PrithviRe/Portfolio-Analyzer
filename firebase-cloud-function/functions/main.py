import os
import requests
import google.generativeai as genai
from textblob import TextBlob
import dotenv
import json
import yfinance as yf
from firebase_functions import https_fn
from firebase_admin import initialize_app

initialize_app()

dotenv.load_dotenv("api.env")

NEWS_API_KEY = os.getenv("NEWS_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-1.5-pro")

PREDICTION_HISTORY_FILE = "predictions.json"

def get_live_stock_data(stocks):
    stock_data = yf.download(stocks, period="1d", group_by="ticker")
    portfolio = []
    
    for stock in stocks:
        if stock in stock_data:
            data = stock_data[stock]
            last_price = data["Close"].iloc[-1]
            day_change = last_price - data["Open"].iloc[-1]
            day_change_percentage = (day_change / data["Open"].iloc[-1]) * 100
            portfolio.append({
                "tradingsymbol": stock,
                "last_price": last_price,
                "day_change": day_change,
                "day_change_percentage": day_change_percentage
            })
    return portfolio

def analyze_sentiment(text):
    sentiment_score = TextBlob(text).sentiment.polarity
    return 1 if sentiment_score > 0 else -1 if sentiment_score < 0 else 0

def fetch_news(stock_symbol):
    stock_name = stock_symbol.split(".")[0]  # Remove .NS or similar extensions
    url = f"https://newsapi.org/v2/everything?q={stock_name}&sortBy=publishedAt&apiKey={NEWS_API_KEY}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            news_articles = response.json().get("articles", [])
            headlines = [article["title"] for article in news_articles[:5]]
            return headlines
        else:
            return []
    except:
        return []

def analyze_stock_news(portfolio):
    stock_news_sentiment = {}
    for stock in portfolio:
        headlines = fetch_news(stock["tradingsymbol"])
        sentiments = [analyze_sentiment(headline) for headline in headlines]
        overall_sentiment = sum(sentiments)
        stock_news_sentiment[stock["tradingsymbol"]] = {
            "headlines": headlines,
            "sentiment_score": overall_sentiment
        }
    return stock_news_sentiment

def save_predictions(predictions):
    with open(PREDICTION_HISTORY_FILE, "w") as f:
        json.dump(predictions, f)

def load_past_predictions():
    if os.path.exists(PREDICTION_HISTORY_FILE):
        with open(PREDICTION_HISTORY_FILE, "r") as f:
            return json.load(f)
    return {}

def check_past_predictions(portfolio):
    past_predictions = load_past_predictions()
    accuracy_results = {}
    for stock in portfolio:
        symbol = stock["tradingsymbol"]
        if symbol in past_predictions:
            predicted_movement = past_predictions[symbol]
            actual_movement = "Buy" if stock["day_change"] > 0 else "Sell"
            accuracy_results[symbol] = predicted_movement == actual_movement
    return accuracy_results

def get_analysis(stocks):
    portfolio = get_live_stock_data(stocks)
    news_analysis = analyze_stock_news(portfolio)
    analysis_results = {}
    
    for stock in portfolio:
        symbol = stock["tradingsymbol"]
        stock_news = news_analysis.get(symbol, {})
        gemini_prompt = (
            f"Analyze {symbol} based on news sentiment and suggest whether to buy, hold, or sell. "
            f"News Sentiment Score: {stock_news.get('sentiment_score', 0)}. Headlines: {stock_news.get('headlines', [])}. "
            "Provide a brief analysis with potential risks and sector-wide trends."
        )
        try:
            response = model.generate_content(gemini_prompt)
            analysis_text = response.text if hasattr(response, "text") else str(response)
            recommendation = "Buy" if "buy" in analysis_text.lower() else "Sell" if "sell" in analysis_text.lower() else "Hold"
            analysis_results[symbol] = {
                "brief_analysis": analysis_text,
                "recommendation": recommendation,
                "sentiment_analysis": stock_news
            }
        except Exception as e:
            analysis_results[symbol] = {
                "brief_analysis": f"Gemini AI analysis failed: {e}",
                "recommendation": "Unknown",
                "sentiment_analysis": stock_news
            }

    # Save today's predictions for future accuracy comparison
    predictions_to_save = {
        symbol: analysis["recommendation"]
        for symbol, analysis in analysis_results.items()
    }
    save_predictions(predictions_to_save)

    past_accuracy = check_past_predictions(portfolio)
    return {
        "stock_analysis": analysis_results,
        "past_accuracy": past_accuracy
    }

@https_fn.on_request(memory=2048)
def stock_analysis_api(req: https_fn.Request) -> https_fn.Response:
    try:
        req_json = req.get_json()
        stocks = req_json.get("stocks", [])
        if not stocks:
            return https_fn.Response(json.dumps({"error": "Stock symbols required"}), status=400, content_type="application/json")
        result = get_analysis(stocks)
        return https_fn.Response(json.dumps(result, indent=4), content_type="application/json")
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, content_type="application/json")