% function cryptoData = fetch_data(numDays, initialPrice)
% % FETCH_DATA Generates high-frequency 1-hour OHLCV data & realistic sentiment series.
% %
% % Syntax:
% %   cryptoData = fetch_data()
% %   cryptoData = fetch_data(numDays)
% %   cryptoData = fetch_data(numDays, initialPrice)
% %
% % Inputs:
% %   numDays      - Number of simulation days (default: 365 -> 8760 hourly bars)
% %   initialPrice - Starting BTC/USDT price in USD (default: 40000)
% %
% % Output:
% %   cryptoData   - MATLAB table with columns:
% %                  Timestamp, Open, High, Low, Close, Volume, SentimentRaw, Headlines
% %
% % Description:
% %   Simulates 1-hour BTC/USDT price action via Geometric Brownian Motion coupled
% %   with a discrete-time GARCH(1,1) volatility jump model. Generates high-frequency
% %   synthetic sentiment scores featuring leading market alpha signals, background noise,
% %   and bot spam sentiment spikes.
% %
% % Author: Senior Quantitative Trader & Financial Engineer
% % Project: Comprehensive Quantitative Crypto Trading System
% 
%     if nargin < 1 || isempty(numDays);      numDays = 365;      end
%     if nargin < 2 || isempty(initialPrice); initialPrice = 40000; end
% 
%     numHours = numDays * 24;
% 
%     % 1. Create 1-Hour Timestamps
%     startDate = datetime(2025, 1, 1, 0, 0, 0);
%     timestamps = (startDate : hours(1) : (startDate + hours(numHours - 1)))';
% 
%     % 2. Simulate 1-Hour Close Prices using GBM + GARCH(1,1) Volatility Jumps
%     dt = 1 / 8760; % 1-hour step size annualized (365 days * 24 hours)
%     mu = 0.20;     % Annualized baseline drift (20%)
% 
%     % GARCH(1,1) Parameters: sigma^2_t = omega + alpha*eps^2_{t-1} + beta*sigma^2_{t-1} + jump
%     omega = 1e-5;
%     alphaGarch = 0.09;
%     betaGarch  = 0.88;
% 
%     sigma2 = zeros(numHours, 1);
%     sigma2(1) = 0.35^2; % Initial annualized volatility squared
% 
%     epsilon = randn(numHours, 1);
%     hourlyReturns = zeros(numHours, 1);
% 
%     % Jump process parameters
%     jumpProb = 0.015; % 1.5% probability per hour of a volatility jump shock
% 
%     for t = 2:numHours
%         % Check for volatility jump shock (market news spike / liquidation event)
%         if rand() < jumpProb
%             jumpShock = 0.05 + 0.10 * rand(); % Sudden jump in variance
%         else
%             jumpShock = 0;
%         end
% 
%         % GARCH(1,1) variance recursion
%         prevRetEps = hourlyReturns(t-1) / sqrt(max(sigma2(t-1) * dt, 1e-10));
%         sigma2(t) = omega + alphaGarch * (prevRetEps^2 * dt) + betaGarch * sigma2(t-1) + jumpShock;
%         sigma2(t) = max(0.04, sigma2(t)); % Floor annualized volatility at 20% (variance 0.04)
% 
%         sigma_t = sqrt(sigma2(t));
% 
%         % Cyclic macro regime shift (trend overlay)
%         regime = 0.05 * sin(2 * pi * t / (24 * 30)) + 0.03 * cos(2 * pi * t / (24 * 90));
% 
%         % Hourly return equation under GBM + GARCH
%         hourlyReturns(t) = (mu - 0.5 * sigma_t^2) * dt + sigma_t * sqrt(dt) * epsilon(t) + regime * dt;
%     end
% 
%     % Construct Close price series
%     closePrices = zeros(numHours, 1);
%     closePrices(1) = initialPrice;
%     for t = 2:numHours
%         closePrices(t) = closePrices(t-1) * exp(hourlyReturns(t));
%     end
% 
%     % 3. Synthesize Realistic High-Frequency Open, High, Low, Volume
%     hourlyVol = sqrt(sigma2) * sqrt(dt);
%     openPrices = zeros(numHours, 1);
%     openPrices(1) = initialPrice;
%     for t = 2:numHours
%         openPrices(t) = closePrices(t-1) * (1 + 0.05 * (rand() - 0.5) * hourlyVol(t));
%     end
% 
%     intradaySpread = hourlyVol .* (0.5 + 0.5 * rand(numHours, 1));
%     highPrices = max(openPrices, closePrices) .* (1 + intradaySpread * 0.8);
%     lowPrices  = min(openPrices, closePrices) .* (1 - intradaySpread * 0.8);
% 
%     % Volume surges with absolute return & GARCH volatility
%     baseHourlyVolume = 5e7; % $50M base hourly volume
%     volume = baseHourlyVolume * (1 + 5 * abs(hourlyReturns) ./ max(hourlyVol, 1e-5) + 0.5 * rand(numHours, 1));
% 
%     % 4. Generate Synthetic Sentiment with Leading Alpha & Bot Spam Spikes
%     % A) Leading alpha signal: sentiment leads return of t+2 to t+6
%     futureReturns = zeros(numHours, 1);
%     for t = 1:(numHours - 6)
%         futureReturns(t) = mean(hourlyReturns(t+1:t+4));
%     end
%     futureReturns(max(1, numHours-5):numHours) = hourlyReturns(max(1, numHours-5):numHours);
% 
%     % Base sentiment scaled between -1 and +1
%     alphaSignal = tanh(futureReturns * 50); 
% 
%     % B) Gaussian noise overlay
%     sentimentNoise = 0.25 * randn(numHours, 1);
% 
%     % C) Bot spam spikes (sudden random large sentiment outliers)
%     botSpamSpikes = zeros(numHours, 1);
%     spamIdx = rand(numHours, 1) < 0.03; % 3% of hours experience bot spam bursts
%     botSpamSpikes(spamIdx) = (sign(randn(sum(spamIdx), 1))) .* (0.7 + 0.3 * rand(sum(spamIdx), 1));
% 
%     % Raw Sentiment combination
%     rawSentiment = alphaSignal + sentimentNoise + botSpamSpikes;
%     rawSentiment = max(-1.0, min(1.0, rawSentiment)); % Clamp to [-1, +1]
% 
%     % 5. Mock Headline Text Generation for Text Processing Pipeline
%     bullishPhrases = ["BTC momentum surging!", "Whale accumulation active", "Institutional inflows bullish", "Breakout structure confirmed"];
%     bearishPhrases = ["Market selling pressure high", "FUD and regulatory concerns", "Liquidations cascade down", "Resistance rejection confirmed"];
%     neutralPhrases = ["Rangebound consolidation", "Orderbook depth stable", "Derivatives funding neutral", "Volume steady in channel"];
% 
%     headlinesCell = cell(numHours, 1);
%     for t = 1:numHours
%         score = rawSentiment(t);
%         if score > 0.25
%             cat = bullishPhrases;
%         elseif score < -0.25
%             cat = bearishPhrases;
%         else
%             cat = neutralPhrases;
%         end
%         idx = randi(length(cat));
%         headlinesCell{t} = char(cat(idx));
%     end
% 
%     % 6. Package into MATLAB Table
%     cryptoData = table(timestamps, openPrices, highPrices, lowPrices, closePrices, volume, rawSentiment, headlinesCell, ...
%         'VariableNames', {'Timestamp', 'Open', 'High', 'Low', 'Close', 'Volume', 'SentimentRaw', 'Headlines'});
% 
%     fprintf('[INFO] Generated %d hourly candles (GBM + GARCH jumps) & sentiment series.\n', numHours);
% end
% 
% 
% 



function cryptoData = fetch_data(numDays, initialPrice, coinSymbol)
% FETCH_DATA Generates high-frequency 1-hour OHLCV data & realistic sentiment series.
%
% Syntax:
%   cryptoData = fetch_data()
%   cryptoData = fetch_data(numDays)
%   cryptoData = fetch_data(numDays, initialPrice)
%   cryptoData = fetch_data(numDays, initialPrice, coinSymbol)
%
% Inputs:
%   numDays      - Number of simulation days (default: 365 -> 8760 hourly bars)
%   initialPrice - Starting price in USD (default: 40000 or dynamic based on symbol)
%   coinSymbol   - Target crypto/stock symbol string (default: 'BTC')
%
% Output:
%   cryptoData   - MATLAB table with columns:
%                  Timestamp, Open, High, Low, Close, Volume, SentimentRaw, Headlines

    if nargin < 1 || isempty(numDays);      numDays = 365;      end
    if nargin < 3 || isempty(coinSymbol);   coinSymbol = 'BTC'; end
    
    if nargin < 2 || isempty(initialPrice)
        seedVal = sum(double(coinSymbol));
        rng(seedVal);
        initialPrice = 100 + mod(seedVal, 500);
    else
        rng(sum(double(coinSymbol)));
    end

    numHours = numDays * 24;

    % 1. Create 1-Hour Timestamps
    startDate = datetime(2025, 1, 1, 0, 0, 0);
    timestamps = (startDate : hours(1) : (startDate + hours(numHours - 1)))';

    % 2. Simulate 1-Hour Close Prices using GBM + GARCH(1,1) Volatility Jumps
    dt = 1 / 8760; % 1-hour step size annualized
    mu = 0.20;     % Annualized baseline drift (20%)

    omega = 1e-5;
    alphaGarch = 0.09;
    betaGarch  = 0.88;
    sigma2 = zeros(numHours, 1);
    sigma2(1) = 0.35^2;
    epsilon = randn(numHours, 1);
    hourlyReturns = zeros(numHours, 1);

    jumpProb = 0.015;

    for t = 2:numHours
        if rand() < jumpProb
            jumpShock = 0.05 + 0.10 * rand();
        else
            jumpShock = 0;
        end

        prevRetEps = hourlyReturns(t-1) / sqrt(max(sigma2(t-1) * dt, 1e-10));
        sigma2(t) = omega + alphaGarch * (prevRetEps^2 * dt) + betaGarch * sigma2(t-1) + jumpShock;
        sigma2(t) = max(0.04, sigma2(t));
        sigma_t = sqrt(sigma2(t));

        regime = 0.05 * sin(2 * pi * t / (24 * 30)) + 0.03 * cos(2 * pi * t / (24 * 90));
        hourlyReturns(t) = (mu - 0.5 * sigma_t^2) * dt + sigma_t * sqrt(dt) * epsilon(t) + regime * dt;
    end

    closePrices = zeros(numHours, 1);
    closePrices(1) = initialPrice;
    for t = 2:numHours
        closePrices(t) = closePrices(t-1) * exp(hourlyReturns(t));
    end

    % 3. Synthesize Open, High, Low, Volume
    hourlyVol = sqrt(sigma2) * sqrt(dt);
    openPrices = zeros(numHours, 1);
    openPrices(1) = initialPrice;
    for t = 2:numHours
        openPrices(t) = closePrices(t-1) * (1 + 0.05 * (rand() - 0.5) * hourlyVol(t));
    end

    intradaySpread = hourlyVol .* (0.5 + 0.5 * rand(numHours, 1));
    highPrices = max(openPrices, closePrices) .* (1 + intradaySpread * 0.8);
    lowPrices  = min(openPrices, closePrices) .* (1 - intradaySpread * 0.8);

    baseHourlyVolume = 5e7;
    volume = baseHourlyVolume * (1 + 5 * abs(hourlyReturns) ./ max(hourlyVol, 1e-5) + 0.5 * rand(numHours, 1));

    % 4. Generate Synthetic Sentiment Series
    futureReturns = zeros(numHours, 1);
    for t = 1:(numHours - 6)
        futureReturns(t) = mean(hourlyReturns(t+1:t+4));
    end
    futureReturns(max(1, numHours-5):numHours) = hourlyReturns(max(1, numHours-5):numHours);

    alphaSignal = tanh(futureReturns * 50); 
    sentimentNoise = 0.25 * randn(numHours, 1);

    botSpamSpikes = zeros(numHours, 1);
    spamIdx = rand(numHours, 1) < 0.03;
    botSpamSpikes(spamIdx) = (sign(randn(sum(spamIdx), 1))) .* (0.7 + 0.3 * rand(sum(spamIdx), 1));

    rawSentiment = alphaSignal + sentimentNoise + botSpamSpikes;
    rawSentiment = max(-1.0, min(1.0, rawSentiment));

    % 5. Mock Headline Generation Parameterized by Ticker
    bullishPhrases = [
        sprintf("%s momentum surging!", coinSymbol);
        sprintf("Whale accumulation active on %s", coinSymbol);
        sprintf("Institutional inflows bullish for %s", coinSymbol);
        sprintf("%s breakout structure confirmed", coinSymbol)
    ];

    bearishPhrases = [
        sprintf("Market selling pressure high on %s", coinSymbol);
        sprintf("FUD and regulatory concerns for %s", coinSymbol);
        sprintf("%s liquidations cascade down", coinSymbol);
        sprintf("Resistance rejection confirmed for %s", coinSymbol)
    ];

    neutralPhrases = [
        sprintf("%s rangebound consolidation continues", coinSymbol);
        sprintf("Orderbook depth stable for %s", coinSymbol);
        sprintf("Derivatives funding neutral on %s", coinSymbol);
        sprintf("%s volume steady in channel", coinSymbol)
    ];

    headlinesCell = cell(numHours, 1);
    for t = 1:numHours
        score = rawSentiment(t);
        if score > 0.25
            cat = bullishPhrases;
        elseif score < -0.25
            cat = bearishPhrases;
        else
            cat = neutralPhrases;
        end
        idx = randi(length(cat));
        headlinesCell{t} = char(cat(idx));
    end

    % 6. Package into Output Table
    cryptoData = table(timestamps, openPrices, highPrices, lowPrices, closePrices, volume, rawSentiment, headlinesCell, ...
        'VariableNames', {'Timestamp', 'Open', 'High', 'Low', 'Close', 'Volume', 'SentimentRaw', 'Headlines'});

    fprintf('[INFO] Ingested market feed for %s: Generated %d hourly candles.\n', coinSymbol, numHours);
end