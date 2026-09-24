function forecastedReturns = fit_timeseries_model(marketData, sentimentScores)
% FIT_TIMESERIES_MODEL Fits an ARIMAX(1,0,1) model using log returns with 
% sentiment Z-scores as an exogenous regressor (X) to forecast 1-step returns.
%
% Inputs:
%   marketData       - MATLAB table containing 'Close' prices
%   sentimentScores  - MATLAB table containing 'SentimentZScore'
%
% Output:
%   forecastedReturns - Vector of forecasted 1-period log returns

closePrices = marketData.Close;
numBars = length(closePrices);

% Compute hourly log returns
logReturns = [0; log(closePrices(2:end) ./ closePrices(1:end-1))];

% Extract exogenous sentiment regressor (Z-Score)
if istable(sentimentScores) && ismember('SentimentZScore', sentimentScores.Properties.VariableNames)
    exogX = sentimentScores.SentimentZScore;
else
    % Fallback if simple vector/array passed
    exogX = sentimentScores;
end

% Clean NaNs or Inf values
logReturns(isnan(logReturns) | isinf(logReturns)) = 0;
exogX(isnan(exogX) | isinf(exogX)) = 0;

forecastedReturns = zeros(numBars, 1);

% Fit ARIMAX(1,0,1) model using Econometrics Toolbox or direct ARX estimation
try
    % Attempt formal Econometric Toolbox ARIMAX specification
    modelSpec = arima('AROrder', 1, 'MAOrder', 1, 'Constant', 0);

    % Rolling or full-series estimation with sentiment regressor
    % (Simulated regression: beta_0 * Return_{t-1} + beta_1 * MA_{t-1} + gamma * Sentiment_t)
    est = estimate(modelSpec, logReturns, 'X', exogX, 'Display', 'off');

    arCoeff = cell2mat(est.AR);
    maCoeff = cell2mat(est.MA);
    gammaCoeff = est.Beta;

    % Construct 1-step forecast series
    resids = infer(est, logReturns, 'X', exogX);
    for t = 2:numBars
        forecastedReturns(t) = arCoeff * logReturns(t-1) + ...
            maCoeff * resids(t-1) + ...
            gammaCoeff * exogX(t);
    end
    fprintf('[INFO] ARIMAX(1,0,1) model fitted successfully with sentiment regressor.\n');

catch
    % Fallback: Linear autoregressive predictor with exogenous sentiment (ARX)
    % Fits: Ret_t = a1 * Ret_{t-1} + b1 * Sentiment_t + epsilon_t
    X_reg = [lagmatrix(logReturns, 1), exogX];
    X_reg(isnan(X_reg)) = 0;

    % Ordinary Least Squares estimation
    beta = X_reg \ logReturns; 
    forecastedReturns = X_reg * beta;
    fprintf('[INFO] Econometrics Toolbox not found; used fast ARX fallback model.\n');
end
end