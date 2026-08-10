# Sentiment Analysis in Cryptocurrency Trading (MathWorks Project 239)

![License](https://img.shields.io/badge/License-MIT_or_BSD_2--Clause-blue.svg)
![MATLAB](https://img.shields.io/badge/MATLAB-Required-orange.svg)

**Team Lead:** Aditya Parmale (AdityaInTech)  
**Institution:** Vidyalankar Institute of Technology  
**Program:** MathWorks Excellence in Innovation  

---

## 📖 Motivation
Recently, more than 2,300 US businesses accept bitcoin, according to an estimate from late 2020. Cryptocurrency trading presents a host of opportunities and challenges. External factors, such as financial news and social media, have wide impacts on crypto price movements. For this reason, it is important to research the effectiveness of Twitter posts, as a main social media platform, on cryptocurrency trading strategies. 

Sentiment analysis is a sub-research area of Natural Language Processing (NLP) studies. Twitter sentiment analysis can provide insights that indicate positive or negative attitudes toward cryptocurrency. Moreover, due to the high volatility of cryptocurrency prices, the analysis of social media sentiments and cryptocurrencies’ time series will significantly improve trading strategies. This project aims to build the optimal portfolio of cash and cryptocurrencies to maximize revenues given a certain level of risk.

## 🚀 Project Description
This project analyzes data from Twitter posts about cryptocurrency to discover the current overall feelings of people towards it and uses these findings to build an optimal trading strategy. 

The system retrieves social media data, builds time series models with sentiment scores, and designs algorithmic trading strategies using MATLAB.

### Key Objectives & Steps
1. **Data Retrieval:** Retrieve tweets on cryptocurrencies using the Twitter connection object from the Datafeed Toolbox (or Python integration for extended data range).
2. **Sentiment Analysis:** Apply a classification algorithm to determine sentiment scores and compare results against existing VADER and ratio rule methods from the Text Analytics Toolbox. Large Language Models via MATLAB API may also be used to retrieve features.
3. **Time Series Modeling:** Build a time series model of the cryptocurrency, considering sentiment scores as a factor using the Econometrics Toolbox.
4. **Trading Strategy & Backtesting:** Design algorithmic trading strategies using the Financial Toolbox and back-test the portfolio performance.

## 🛠️ Required MATLAB Toolboxes
To successfully run this solution, ensure you have the following toolboxes installed in your MATLAB environment:
- Datafeed Toolbox™
- Statistics and Machine Learning Toolbox™
- Deep Learning Toolbox™
- Text Analytics Toolbox™
- Econometrics Toolbox™
- Financial Toolbox™

## ⚙️ Setup and Installation
1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/AdityaInTech/<your-repo-name>.git
   ```
2. Open MATLAB and navigate to the cloned repository directory.
3. Verify that all required toolboxes are installed.

## ▶️ How to Run
In accordance with MathWorks evaluation guidelines, this project features a single main entry point for end-to-end execution.

1. Open `main.m` (located in the root or `src/` directory).
2. Run the script. The script will automatically execute data loading, sentiment scoring, model building, and back-testing with minimal manual setup.

## 📂 Repository Structure
- `src/` - Contains all MATLAB scripts, functions, and the single entry point (`main.m`).
- `data/` - Directory for dataset files (Note: large raw data files are kept local and not pushed to the repo).
- `docs/` - Contains project documentation, reports, and challenge guidelines.

## 📚 References
- [1] Mittal, Anshul. "Stock Prediction Using Twitter Sentiment Analysis." (2011).
- [2] E. Şaşmaz and F. B. Tek, "Tweet Sentiment Analysis for Cryptocurrencies," 2021 6th International Conference on Computer Science and Engineering (UBMK), 2021, pp. 613-618.
- [3] J. Bollen and H. Mao, "Twitter Mood as a Stock Market Predictor" in Computer, vol. 44, no. 10, pp. 91-94, 2011.

---
*This repository is submitted as part of the MathWorks Excellence in Innovation program.*
