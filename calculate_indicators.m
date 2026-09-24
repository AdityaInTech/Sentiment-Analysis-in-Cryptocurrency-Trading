function techTable = calculate_indicators(cryptoData, rsiPeriod, macdFast, macdSlow, macdSignal, bbPeriod, bbStd, volWindow)
% CALCULATE_INDICATORS Computes technical analysis indicators and realized volatility.
%
% Syntax:
%   techTable = calculate_indicators(cryptoData)
%   techTable = calculate_indicators(cryptoData, rsiPeriod, macdFast, macdSlow, macdSignal, bbPeriod, bbStd, volWindow)
%
% Inputs:
%   cryptoData - Table containing 'Close' price column (or numeric vector of close prices)
%   rsiPeriod  - RSI lookback period (default: 14)
%   macdFast   - MACD fast EMA period (default: 12)
%   macdSlow   - MACD slow EMA period (default: 26)
%   macdSignal - MACD signal line EMA period (default: 9)
%   bbPeriod   - Bollinger Bands SMA period (default: 20)
%   bbStd      - Bollinger Bands standard deviation multiplier (default: 2.0)
%   volWindow  - Realized volatility rolling window in periods (default: 24)
%
% Outputs:
%   techTable  - Table containing: RSI, MACDLine, SignalLine, MACDHist, UpperBB, MiddleBB, LowerBB, PercentB, RealizedVol24h
%
% Author: Senior Quantitative Trader & Financial Engineer
% Project: Comprehensive Quantitative Crypto Trading System

    if nargin < 2 || isempty(rsiPeriod);  rsiPeriod  = 14; end
    if nargin < 3 || isempty(macdFast);   macdFast   = 12; end
    if nargin < 4 || isempty(macdSlow);   macdSlow   = 26; end
    if nargin < 5 || isempty(macdSignal); macdSignal = 9;  end
    if nargin < 6 || isempty(bbPeriod);   bbPeriod   = 20; end
    if nargin < 7 || isempty(bbStd);      bbStd      = 2.0; end
    if nargin < 8 || isempty(volWindow);  volWindow  = 24; end

    if istable(cryptoData)
        closePrices = cryptoData.Close;
    else
        closePrices = cryptoData;
    end

    n = length(closePrices);

    % 1. Relative Strength Index (RSI - 14)
    priceDiff = [0; diff(closePrices)];
    gains  = max(priceDiff, 0);
    losses = max(-priceDiff, 0);

    avgGain = zeros(n, 1);
    avgLoss = zeros(n, 1);

    if n >= rsiPeriod
        avgGain(rsiPeriod) = mean(gains(1:rsiPeriod));
        avgLoss(rsiPeriod) = mean(losses(1:rsiPeriod));
        for t = (rsiPeriod + 1):n
            avgGain(t) = (avgGain(t-1) * (rsiPeriod - 1) + gains(t)) / rsiPeriod;
            avgLoss(t) = (avgLoss(t-1) * (rsiPeriod - 1) + losses(t)) / rsiPeriod;
        end
    end

    rs = avgGain ./ max(avgLoss, 1e-10);
    rsi = 100 - (100 ./ (1 + rs));
    rsi(1:rsiPeriod-1) = 50;

    % 2. MACD (12, 26, 9)
    emaFast = compute_ema(closePrices, macdFast);
    emaSlow = compute_ema(closePrices, macdSlow);
    macdLine = emaFast - emaSlow;
    signalLine = compute_ema(macdLine, macdSignal);
    macdHist = macdLine - signalLine;

    % 3. Bollinger Bands (20, 2.0)
    middleBB = movmean(closePrices, [bbPeriod - 1, 0]);
    stdBB    = movstd(closePrices, [bbPeriod - 1, 0]);
    upperBB  = middleBB + bbStd * stdBB;
    lowerBB  = middleBB - bbStd * stdBB;
    
    % Percent B (%B): (Close - LowerBB) / (UpperBB - LowerBB)
    bbBandwidth = max(upperBB - lowerBB, 1e-6);
    percentB = (closePrices - lowerBB) ./ bbBandwidth;

    % 4. Realized Volatility (24-Hour Rolling Standard Deviation of Hourly Returns, Annualized)
    logReturns = [0; diff(log(closePrices))];
    rollVol = movstd(logReturns, [volWindow - 1, 0]);
    realizedVol24h = rollVol * sqrt(8760); % Annualized realized volatility

    % Package into Table
    techTable = table(rsi, macdLine, signalLine, macdHist, upperBB, middleBB, lowerBB, percentB, realizedVol24h, ...
        'VariableNames', {'RSI', 'MACDLine', 'SignalLine', 'MACDHist', 'UpperBB', 'MiddleBB', 'LowerBB', 'PercentB', 'RealizedVol24h'});

    fprintf('[INFO] Technical indicators & 24h Realized Volatility computed.\n');
end

% Local Helper: Exponential Moving Average
function ema = compute_ema(data, period)
    n = length(data);
    ema = zeros(n, 1);
    k = 2 / (period + 1);
    ema(1) = data(1);
    for i = 2:n
        ema(i) = data(i) * k + ema(i-1) * (1 - k);
    end
end
