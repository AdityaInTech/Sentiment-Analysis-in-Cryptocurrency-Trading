% function signalsData = generate_signals(cryptoData, smaPeriod, buyThreshold, sellThreshold, techTable)
% % GENERATE_SIGNALS Multi-Factor Alpha Engine combining Sentiment Z-Score, Velocity & Technicals.
% %
% % Syntax:
% %   signalsData = generate_signals(cryptoData, smaPeriod, buyThreshold, sellThreshold, techTable)
% %
% % Inputs:
% %   cryptoData    - Table containing sentiment columns (from analyze_sentiment)
% %   smaPeriod     - Sentiment smoothing window (default: 7 periods)
% %   buyThreshold  - Alpha threshold for LONG position (default: +0.25)
% %   sellThreshold - Alpha threshold for SHORT/EXIT position (default: -0.25)
% %   techTable     - Table containing RSI, PercentB, RealizedVol24h (from calculate_indicators)
% %
% % Outputs:
% %   signalsData   - Table with columns:
% %                   RawSentiment, SmoothedSentiment, SentimentZScore, SentimentVelocity,
% %                   AlphaScore, PureTargetSignal, ExecutedPositionPure,
% %                   HybridTargetSignal, ExecutedPositionHybrid, ExecutedPosition
% %
% % Description:
% %   Combines Rolling Sentiment Z-Score, Sentiment Velocity, RSI Momentum, and Bollinger Band %B
% %   into a composite multi-factor quantitative Alpha Score. Implements a strict lag shift (t-1)
% %   preventing look-ahead bias prior to execution simulation.
% %
% % Author: Senior Quantitative Trader & Financial Engineer
% % Project: Comprehensive Quantitative Crypto Trading System
% 
%     if nargin < 2 || isempty(smaPeriod);     smaPeriod = 7;      end
%     if nargin < 3 || isempty(buyThreshold);  buyThreshold = 0.25; end
%     if nargin < 4 || isempty(sellThreshold); sellThreshold = -0.25; end
%     if nargin < 5;                           techTable = [];     end
% 
%     % Extract sentiment series
%     if istable(cryptoData)
%         if ismember('CompoundScore', cryptoData.Properties.VariableNames)
%             rawSentiment = cryptoData.CompoundScore;
%         elseif ismember('SentimentRaw', cryptoData.Properties.VariableNames)
%             rawSentiment = cryptoData.SentimentRaw;
%         else
%             error('CompoundScore or SentimentRaw column required.');
%         end
% 
%         if ismember('SentimentZScore', cryptoData.Properties.VariableNames)
%             sentZ = cryptoData.SentimentZScore;
%         else
%             sentZ = (rawSentiment - movmean(rawSentiment, [23 0])) ./ (movstd(rawSentiment, [23 0]) + 1e-5);
%         end
% 
%         if ismember('SentimentVelocity', cryptoData.Properties.VariableNames)
%             sentVel = cryptoData.SentimentVelocity;
%         else
%             sentVel = [0; diff(sentZ)];
%         end
%     else
%         rawSentiment = cryptoData;
%         sentZ = (rawSentiment - movmean(rawSentiment, [23 0])) ./ (movstd(rawSentiment, [23 0]) + 1e-5);
%         sentVel = [0; diff(sentZ)];
%     end
% 
%     numPeriods = length(rawSentiment);
% 
%     % 1. Smoothed Sentiment (Trailing Moving Average)
%     smoothedSentiment = movmean(rawSentiment, [smaPeriod - 1, 0]);
% 
%     % 2. Pure Sentiment Target Signal
%     pureTargetSignal = zeros(numPeriods, 1);
%     pureTargetSignal(smoothedSentiment > buyThreshold) = 1;
%     pureTargetSignal(smoothedSentiment < sellThreshold) = -1;
% 
%     % 3. Multi-Factor Composite Alpha Engine
%     % Factors: Z-Score (40%), Velocity (30%), RSI Momentum (15%), Bollinger %B (15%)
%     w_z   = 0.40;
%     w_vel = 0.30;
%     w_rsi = 0.15;
%     w_bb  = 0.15;
% 
%     if ~isempty(techTable) && istable(techTable)
%         rsiVec   = techTable.RSI;
%         percentB = techTable.PercentB;
% 
%         % Normalize technicals to [-1, +1] range
%         normRsi = (rsiVec - 50) / 50;
%         normBb  = 2 * (percentB - 0.5);
%     else
%         normRsi = zeros(numPeriods, 1);
%         normBb  = zeros(numPeriods, 1);
%     end
% 
%     % Composite Alpha Score (-1.0 to +1.0 scale)
%     alphaScore = w_z * (sentZ / 3.0) + w_vel * (sentVel / 2.0) + w_rsi * normRsi + w_bb * normBb;
%     alphaScore = max(-1.0, min(1.0, alphaScore));
% 
%     % Hybrid Signal from Composite Alpha Score
%     hybridTargetSignal = zeros(numPeriods, 1);
%     for t = 1:numPeriods
%         if alphaScore(t) > buyThreshold
%             hybridTargetSignal(t) = 1;  % Long / Buy
%         elseif alphaScore(t) < sellThreshold
%             hybridTargetSignal(t) = -1; % Exit / Short
%         else
%             hybridTargetSignal(t) = 0;  % Neutral / Hold
%         end
%     end
% 
%     % 4. STRICT LAG SHIFT (t-1) PREVENTING LOOK-AHEAD BIAS
%     % ExecutedPosition(t) = TargetSignal(t-1)
%     executedPositionPure   = [0; pureTargetSignal(1:end-1)];
%     executedPositionHybrid = [0; hybridTargetSignal(1:end-1)];
%     executedPosition       = executedPositionHybrid;
% 
%     % 5. Package Signals into Table
%     signalsData = table(rawSentiment, smoothedSentiment, sentZ, sentVel, alphaScore, ...
%         pureTargetSignal, executedPositionPure, hybridTargetSignal, executedPositionHybrid, executedPosition, ...
%         'VariableNames', {'RawSentiment', 'SmoothedSentiment', 'SentimentZScore', 'SentimentVelocity', ...
%                           'AlphaScore', 'PureTargetSignal', 'ExecutedPositionPure', ...
%                           'HybridTargetSignal', 'ExecutedPositionHybrid', 'ExecutedPosition'});
% 
%     fprintf('[INFO] Multi-factor Composite Alpha Engine signals generated with strict t-1 lag shift.\n');
% end




function signals = generate_signals(indicators, sentimentScores, forecastedReturns)
% GENERATE_SIGNALS Evaluates technical indicators, sentiment Z-scores,
% and ARIMAX forecasted returns to generate action signals (+1, -1, 0).
%
% Inputs:
%   indicators        - Table containing technical indicators (RSI, Moving Averages, etc.)
%   sentimentScores   - Table or vector containing sentiment scores/Z-scores
%   forecastedReturns - Vector of predicted returns from the time-series model
%
% Output:
%   signals           - Vector of trading signals (1 = BUY, -1 = SELL, 0 = HOLD)

numRows = height(indicators);
signals = zeros(numRows, 1);

% --- 1. Robust Sentiment Extraction ---
if istable(sentimentScores)
    varNames = sentimentScores.Properties.VariableNames;

    if ismember('SentimentZScore', varNames)
        zScores = sentimentScores.SentimentZScore;
    elseif ismember('CompoundScore', varNames)
        % Compute rolling Z-score dynamically if Z-Score column is missing
        rawComp = sentimentScores.CompoundScore;
        rollMean = movmean(rawComp, [23, 0]);
        rollStd = movstd(rawComp, [23, 0]);
        zScores = (rawComp - rollMean) ./ (rollStd + 1e-5);
    elseif ismember('SentimentRaw', varNames)
        rawComp = sentimentScores.SentimentRaw;
        rollMean = movmean(rawComp, [23, 0]);
        rollStd = movstd(rawComp, [23, 0]);
        zScores = (rawComp - rollMean) ./ (rollStd + 1e-5);
    else
        % Fallback to first numeric column in table
        zScores = sentimentScores{:, 1};
    end
else
    % If array/vector was passed directly
    zScores = sentimentScores;
end

% Ensure Z-scores array matches data length
if length(zScores) < numRows
    zScores = [zeros(numRows - length(zScores), 1); zScores];
end

% --- 2. Format Forecasted Returns Vector ---
if length(forecastedReturns) < numRows
    forecastVector = [zeros(numRows - length(forecastedReturns), 1); forecastedReturns];
else
    forecastVector = forecastedReturns;
end

% --- 3. Extract Technical Indicators Safely ---
if ismember('RSI', indicators.Properties.VariableNames)
    rsi = indicators.RSI;
else
    rsi = 50 * ones(numRows, 1); % Neutral default fallback
end

% --- 4. Signal Generation Logic Loop ---
for t = 2:numRows
    % Sentiment Conditions
    bullishSentiment = zScores(t) > 1.0;
    bearishSentiment = zScores(t) < -1.0;

    % Technical Indicator Thresholds
    rsiOversold   = rsi(t) < 30;
    rsiOverbought = rsi(t) > 70;

    % Econometric ARIMAX Forecast Direction
    forecastBullish = forecastVector(t) > 0;

    % Execution Signal Matrix
    if (bullishSentiment && rsiOversold) || (bullishSentiment && forecastBullish)
        signals(t) = 1;   % BUY / LONG
    elseif (bearishSentiment && rsiOverbought) || (bearishSentiment && ~forecastBullish)
        signals(t) = -1;  % SELL / SHORT
    else
        signals(t) = 0;   % HOLD / NEUTRAL
    end
end
end